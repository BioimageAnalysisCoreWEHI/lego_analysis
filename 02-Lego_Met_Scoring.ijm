#@ File (label="Directory full of Met Tifs", style="Directory") dir1
#@ File (label="Output directory", style="Directory") dir2
#@ Boolean (label="Use Manual Threshold",default=true) USE_MANUAL_THRESHOLD
#@ Integer (label="Channel 1 Threshold",default=3,style="spinner") c1_th
#@ Integer (label="Channel 2 Threshold",default=3,style="spinner") c2_th
#@ Integer (label="Channel 3 Threshold",default=3,style="spinner") c3_th
#@ Boolean (label="Using Ilastik binaries",default=false) USING_ILASTIK
#@ File (label="Channel 1 Mask", style="File") f_c1_mask
#@ File (label="Channel 2 Mask", style="File") f_c2_mask
#@ File (label="Channel 3 Mask", style="File") f_c3_mask
#@ File (label="Morphology file csv", style="File") morpho_file


var debugMode = true;

print("\\Clear");
run("Close All");
dir1 = dir1 + File.separator();
dir2 = dir2 + File.separator();


flist = getFileList(dir1);

if(!File.exists(dir2)){
	File.makeDirectory(dir2);
}
checkGlobals();


Table_Heading = "TABLES_TEMP_STUPID_TESTING_IGNORE";
channelKey = newArray("fname","100","010","110","001","101","011","111");
table = generateTable(Table_Heading,channelKey);



for(i=0;i<flist.length;i++){
	if(endsWith(flist[i],"tif") && !endsWith(flist[i],"bg.tif")){ //use the masked version
		fpath = dir1 + flist[i];
		if(!File.exists(dir2+flist[i]+".jpg")){;

			print(fpath);
			open(fpath);
			run("Select None");
	
			fname = getTitle();
			res = processImage();
			res = Array.concat(fname,res);
		
			logResults(table,res);
			saveTable(Table_Heading);
		
			selectWindow("Composite");
			//if(!debugMode){
			run("Median...","radius=2 stack");
	//		}
			
			saveAs("TIF", dir2+fname+"_stackMask.tif");
			run("Z Project...", "projection=[Max Intensity]");
			run("RGB Color");
			rename("Mask1");
			
			
		
			selectWindow("MAX_"+fname);
			Stack.setChannel(1);run("Cyan");
			Stack.setChannel(2);run("Yellow");
			Stack.setChannel(3);run("Magenta");
					
			
			
			run("RGB Color");
			rename("Mask2");
			
			
			
			
		
			run("Concatenate...", "open image1=Mask1 image2=Mask2 image3=[-- None --]");
			run("Make Montage...", "columns=2 rows=1 scale=1");
			saveAs("Jpeg", dir2+fname+".jpg");
			
			run("Close All");
			if(isOpen("Exception")){
				while(isOpen("Exception")){
					selectWindow("Exception");
					run("Close");
				}
			}
		}else{
			print("Skipping");
		}
	}
}
		
		
	

function processImage(){	
	
	fname = getTitle();
	run("Duplicate...","duplicate title=asdf");
	selectWindow(fname);
	if(!debugMode){
		run("Median 3D...", "x=4 y=4 z=2");	
	}
	run("Z Project...", "projection=[Max Intensity]");
	mfname = getTitle();
	run("Split Channels");

	
	if (!USING_ILASTIK){
		if(USE_MANUAL_THRESHOLD){
			lowerC1 = c1_th;
			lowerC2 = c2_th;
			lowerC3 = c3_th;		
		}else{		
			selectWindow("C1-"+mfname);		
			run("Median...", "radius=5");
			setAutoThreshold("Otsu dark");
			getThreshold(lowerC1, upper);
			
			selectWindow("C2-"+mfname);
			run("Median...", "radius=5");
			setAutoThreshold("Otsu dark");
			getThreshold(lowerC2, upper);
			
			selectWindow("C3-"+mfname);
			run("Median...", "radius=5");
			setAutoThreshold("Otsu dark");
			getThreshold(lowerC3, upper);
			
			//print(lowerC1,lowerC2,lowerC3);
		}
		
		
		selectWindow(fname);
		run("Split Channels");
		
		
		selectWindow("C1-"+fname);
		run("Subtract Background...", "rolling=750 stack");
		setMinAndMax(0, 4095);
	
		//run("Threshold...");
		print("lowerC1");
		print(lowerC1);
		
		setThreshold(lowerC1,65535,"raw");	
	
		run("Convert to Mask","stack");
		run("Grays");
		
		
		selectWindow("C2-"+fname);
		run("Duplicate...","duplicate title=wut");
		selectWindow("C2-"+fname);
	
		setMinAndMax(0, 4095);
		run("Subtract Background...", "rolling=750 stack");
		print("lowerC2");
		print(lowerC2);
		setThreshold(lowerC2,65535,"raw");
		run("Convert to Mask","stack");
		run("Grays");
		
		
		selectWindow("C3-"+fname);
		setMinAndMax(0, 4095);
		run("Subtract Background...", "rolling=750 stack");
		
		setThreshold(lowerC3,65535,"raw");
		run("Convert to Mask","stack");
		run("Grays");
		
		
		ch1 = "C1-"+fname;
		ch2 = "C2-"+fname;
		ch3 = "C3-"+fname;
		
			
		ch1b = makeBinary(ch1,0);	
		ch2b = makeBinary(ch2,1);
		ch3b = makeBinary(ch3,2);
	}else{
		print("using ilastik");
		metNum = substring(fname,indexOf(fname,"_")+1,indexOf(fname,"."));
		metNum = parseInt(metNum);
		
		mets_file = File.openAsString(morpho_file);
		mets_file = split(mets_file,"\n");
		for(m=0;m<mets_file.length;m++){
			metStats = split(mets_file[m],",");
			if(metStats[0] == metNum){
				Array.print(metStats);
				m = mets_file.length + 1;
			}				
		}
		x0 = parseInt(metStats[2]);
		w = parseInt(metStats[3]) - x0;
		y0 = parseInt(metStats[4]);
		h = parseInt(metStats[5]) - y0;
		z0 = parseInt(metStats[6]);
		z1 = parseInt(metStats[7]);

		run("Bio-Formats Importer", "open=["+f_c1_mask+"] autoscale color_mode=Default crop rois_import=[ROI manager] view=Hyperstack specify_range stack_order=XYCZT z_begin="+z0+" z_end="+z1+" z_step=1 x_coordinate_1="+x0+" y_coordinate_1="+y0+" width_1="+w+" height_1="+h);
		ch1 = getTitle();
		run("Bio-Formats Importer", "open=["+f_c2_mask+"] autoscale color_mode=Default crop rois_import=[ROI manager] view=Hyperstack specify_range stack_order=XYCZT z_begin="+z0+" z_end="+z1+" z_step=1 x_coordinate_1="+x0+" y_coordinate_1="+y0+" width_1="+w+" height_1="+h);
		ch2 = getTitle();
		run("Bio-Formats Importer", "open=["+f_c3_mask+"] autoscale color_mode=Default crop rois_import=[ROI manager] view=Hyperstack specify_range stack_order=XYCZT z_begin="+z0+" z_end="+z1+" z_step=1 x_coordinate_1="+x0+" y_coordinate_1="+y0+" width_1="+w+" height_1="+h);
		ch3 = getTitle();
		
		ch1b = makeBinary(ch1,0);	
		ch2b = makeBinary(ch2,1);
		ch3b = makeBinary(ch3,2);

	}
	
	
	
	
	makeLEGO(ch1b,ch2b,ch3b);
	lego = getTitle();
	
	
	close("*Binarized");
	close("C1-"+fname);
	close("C2-"+fname);
	close("C3-"+fname);
	close("C4-"+fname);
	close("SUM");
	close("asdf");
	
	
	run("Merge Channels...", "c1=C1-MAX_"+fname+" c2=C2-MAX_"+fname+" c3=C3-MAX_"+fname+" create");	
	if(USING_ILASTIK){
		selectWindow("Composite");
		run("Scale...", "x=3 y=3 interpolation=None average create");
		
	}
	selectWindow(lego);
	
	
	
	
	res = scoreLego(lego);
	Array.print(res);
	
	
	return res;

}

	
function scoreLegoChannel(c){
	run("Clear Results");
	//if(!debugMode){
		run("Median...","radius=2 stack");
	//}
	
	//run("3D Geometrical Measure");depricated apparently
	//run("3D Volume Surface"); //also depricated >:(
	
	
	setPixel(0,0,255); //hack to make volume measure work
	run("3D Volume");
	
	nThings = nResults();
	if(nThings > 1){
		run("Summarize");
		
		meanVol = getResult("Volume(Unit)",nResults()-4);
		totalVol = nThings * meanVol;
	}else{
		if(nThings == 1){
			meanVol = getResult("Volume(Unit)");
			totalVol = meanVol;
		}else{
			meanVol = 0;
			totalVol = meanVol;
		}
	}
	if(totalVol==1){
			meanVol=0;
			totalVol = 0; //undo the hack

	}
	//print(c,nThings,meanVol,totalVol);
	
	close("legoChannel");
	close("DUP*");
	res = newArray(c,nThings,meanVol,totalVol);
	print("Res line 227");
	Array.print(res);
	
	return res;
	

}

function scoreLego(lego){
	AllChannelRes = newArray();
	print("\\Clear");
	selectWindow(lego);
	for(c=1;c<=7;c++){
		run("Duplicate...","duplicate title=legoChannel channels="+c+"-"+c);
		res = scoreLegoChannel(c);	
		AllChannelRes = Array.concat(AllChannelRes,res);
	}

	print("\\Clear");
	print("Lne 246");
	Array.print(AllChannelRes);
	
	
	totalVol = 0;
	for(n=3;n<AllChannelRes.length;n=n+4){
		//print(n,AllChannelRes[n]);
		totalVol = totalVol + AllChannelRes[n];
	}
	print("totalVol line 263");
	print(totalVol);
	
	PC_Array = newArray();
	
			
	for(n=3;n<AllChannelRes.length;n=n+4){
		print("Line 270");
		Array.print(AllChannelRes);		
		print(n,AllChannelRes[n]);
		PC_Array = Array.concat(PC_Array,AllChannelRes[n] / totalVol);
		Array.print(PC_Array);
	}
	
	
	//for(c=0;c<7;c++){
	//	print(c);
	//	print(channelKey[c],PC_Array[c]);
	//}
	

	return PC_Array;
	
	
	
}


function makeLEGO(ch1b,ch2b,ch3b){

	
	//run("Image Expression Parser (Macro)", "expression=A+B+C a=["+ch1b+"] b=["+ch2b+"] c=["+ch3b+"] d=None e=None f=None g=None h=None i=None j=None k=None l=None");
	imageCalculator("Add create stack", ch1b,ch2b);
	one_and_two = getTitle();
	imageCalculator("Add create stack", one_and_two,ch3b);
	rename("sum");
	
	run("glasbey_inverted");
	while(!isOpen("sum")){
		//I feel like this is dangerous....
		rename("sum");
	}

	nBarCodes = 7;
	for(i = 1; i<=nBarCodes; i++){
		wait(10);
		while(!isOpen("sum")){
			wait(250);
			print("I'm wainting from 'sum'thing!");
		}
		selectWindow("sum");
		run("Duplicate...","title=hack duplicate");
		
		selectWindow("hack");
		setThreshold(i,i);

		selectWindow("hack");
		run("Convert to Mask", "method=Default background=Dark black");

		selectWindow("hack");
		//run("Re-order Hyperstack ...", "channels=[Slices (z)] slices=[Channels (c)] frames=[Frames (t)]");
		//this is removed because I don't think it's needed with the new improved way of dealing with big mets

		//selectWindow("hack");
		//run("Median 3D...", "x=4 y=4 z=2");
		//this was removed because it was crashing on big mets

		selectWindow("hack");
		rename("newChannel "+i);	
		
		
		//run("Re-order Hyperstack ...", "channels=[Slices (z)] slices=[Channels (c)] frames=[Frames (t)]");
	
	}
	checkAllChannels();	
	
	run("Merge Channels...", "c1=[newChannel 1] c2=[newChannel 2] c3=[newChannel 3] c4=[newChannel 4] c5=[newChannel 5] c6=[newChannel 6] c7=[newChannel 7] create ignore");
	Stack.setChannel(1);run("Cyan");//100
	Stack.setChannel(2);run("Yellow");//010
	Stack.setChannel(3);run("Green");//110
	Stack.setChannel(4);run("Magenta");//001
	Stack.setChannel(5);run("  9 Purple ");//101
	Stack.setChannel(6);run("  8 Orange ");;//011
	Stack.setChannel(7);run("Grays");//111
	
}







function checkAllChannels(){
	for(i=1;i<=7;i++){
		selectWindow("newChannel "+i);
		if(is("Virtual Stack")){
			run("Duplicate...","duplicate title=hack");
			close("newChannel "+i);
			selectWindow("hack");
			rename(	"newChannel "+i);
			getDimensions(width, height, channels, slices, frames);
			if(channels>1){
				run("Re-order Hyperstack ...", "channels=[Slices (z)] slices=[Channels (c)] frames=[Frames (t)]");
			}	
		}
	}	
}



function makeBinary(im,binVal){
	selectImage(im);
	binVal = pow(2,binVal);
	//run("Image Expression Parser (Macro)", "expression=[(A / 255) * "+binVal+"] a=["+im+"] b=None c=None d=None e=None f=None g=None h=None i=None j=None");
	run("Replace value", "pattern=255 replacement="+binVal);
	name = im+"_Binarized";
	run("glasbey_inverted");
	rename(name);
	//virtual = getTitle();
	//name = im+"_Binarized";
	//run("Duplicate...","title=["+name+"] duplicate");
	return name;
}


//Generate a custom table
//Give it a title and an array of headings
//Returns the name required by the logResults function
function generateTable(tableName,column_headings){
	if(isOpen(tableName)){
		selectWindow(tableName);
		run("Close");
	}
	tableTitle=tableName;
	tableTitle2="["+tableTitle+"]";
	run("Table...","name="+tableTitle2+" width=600 height=250");
	newstring = "\\Headings:"+column_headings[0];
	for(i=1;i<column_headings.length;i++){
			newstring = newstring +" \t " + column_headings[i];
	}
	print(tableTitle2,newstring);
	return tableTitle2;
}


//Log the results into the custom table
//Takes the output table name from the generateTable funciton and an array of resuts
//No checking is done to make sure the right number of columns etc. Do that yourself
function logResults(tablename,results_array){
	resultString = results_array[0]; //First column
	//Build the rest of the columns
	for(i=1;i<results_array.length;i++){
		resultString = toString(resultString + " \t " + results_array[i]);
	}
	//Populate table
	print(tablename,resultString);
}



function saveTable(temp_tablename){
	selectWindow(temp_tablename);
	saveAs("Text",dir2+temp_tablename+".txt");
}


function checkGlobals(){
	print("dir1 = " + dir1);
	print("dir2 = " + dir2);
	print("Thresholds = ");
	print(c1_th,c2_th,c3_th);
}