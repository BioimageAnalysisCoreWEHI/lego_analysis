#@ File (label="Full res source file (czi)", style="file") fpath
#@ File (label="Binary Vessel Image (tif)", style="file") thick_fpath
#@ File (label="CSV of met locations", style="file") fpath_1
#@ Integer (label="Resolution level (not series)",default=3,style="spinner") resolution_level
#@ String (visibility=MESSAGE, value="<HTML><B>Note this value is the ratio of pixel sizes not the series number<BR>ie: series 2 is 1/3 of full res, so set resolution level to 3</HTML>", required=false) msg
#@ Boolean (label="Get pixel size from czi metadata",default=true) getPixelSizes
#@ Boolean (label="I used Ilastik",default=true) used_ilastik

run("Set Measurements...", "area mean min center limit redirect=None decimal=3");

//overwritten below
var pixelSize = 1.2197 * resolution_level;
var voxelSize = 2.1970;

run("Bio-Formats Macro Extensions");


//fpath_1 = "V:\\Sabrina\\919_lung_1\\All_met_binary-lbl-morpho.csv";
//thick_fpath = "V:\\Sabrina\\919_lung_1\\";

print(pixelSize);

if(getPixelSizes){
	Ext.setId(fpath);
	Ext.getPixelsPhysicalSizeX(pixelSize);
	Ext.getPixelsPhysicalSizeZ(zpix);
	pixelSize = pixelSize * resolution_level;
}

print(pixelSize);



run("Close All");
print("Opening " + thick_fpath);
open(thick_fpath);
dat = getTitle();
getDimensions(fullImage_width, fullImage_height, blah, blah, blah);

closeRoiManager();



res = File.openAsString(fpath_1);


res = split(res,"\n");


Table_Heading = "Table name";
channelKey = newArray("MetID","Distance to closest vessel","Vessel thickness?");
table = generateTable(Table_Heading,channelKey);

print("TOTAL in res = " + res.length);

for(m=0;m<res.length;m++){	
	metStats = split(res[m],",");
	print("mIndex = "+m);
	vol = metStats[1];
	vol = parseInt(vol);
	if(vol < 10000000000000000 && vol > 25){ //previously 10000000
		x0 = parseInt(metStats[2]);
		width = parseInt(metStats[3]) - x0;
		y0 = parseInt(metStats[4]);
		height = parseInt(metStats[5]) - y0;
		z0 = parseInt(metStats[6]);
		z1 = parseInt(metStats[7]);

		CX = x0 + (width/2);
		CY = y0 + (height / 2 );
		CZ = (z1 + z0) / 2;

		print("Location = ",CX,CY,CZ);
		CX = CX / pixelSize;
		CY = CY / pixelSize;	
		CZ = CZ / voxelSize;
		if(used_ilastik){
			CX = CX * pixelSize;
			CY = CY * pixelSize;
			CZ = CZ * voxelSize;
		}
		
		
	
		makePoint(CX, CY);
		roiManager("Add");
	
		searchRadius = 100;
	
		makeRectangle(CX-searchRadius, CY-searchRadius, 2*searchRadius, 2*searchRadius);
	
		roiManager("add");
		
		Stack.setSlice(CZ);
		
		doTheStuff = true;
		if(doTheStuff){
			roiManager("Select",roiManager("Count")-1);
			run("Duplicate...","title=roi duplicate");
			run("Properties...", "pixel_width="+pixelSize+" pixel_height="+pixelSize+" voxel_depth="+voxelSize);
			setThreshold(0.01,1000000000);
			run("Convert to Mask", "method=Default background=Dark black");
			run("Z Project...", "projection=[Max Intensity]");
			randomWindow = getTitle();
			run("Measure");
			if(getResult("Max")==255){
				StuffIsNearBy = true;
			}else{
				StuffIsNearBy = false;
			}
			
			close(randomWindow);
			//rename("randomWindow");
			
			if(StuffIsNearBy){
				run("Size Opening 2D/3D", "min=250");
                close("roi");
                rename("roi");                
				run("3D Distance Map", "map=EDT image=roi mask=Same threshold=0 inverse");
				Stack.setSlice(CZ);
				makePoint(100,100);
				howClose = getPixel(100,100);
				
				
			}else{
				howClose = "NaN";
                close("randomWindow");
			}
			print(howClose);
			print(CZ);
			getDimensions(width, height, channels, slices, frames);
			newImage("Untitled", "8-bit black", 200, 200, slices);
			Stack.setSlice(CZ);
			
			setPixel(100,100,255);
			run("Properties...", "pixel_width="+pixelSize+" pixel_height="+pixelSize+" voxel_depth="+voxelSize);
			run("3D Distance Map", "map=EDT image=Untitled mask=Same threshold=0 inverse");
			rename("from_centroid");
			
			selectWindow("roi");
			run("Local Thickness (masked, calibrated, silent)");
			
			selectWindow("from_centroid");
			Stack.setSlice(CZ);
			
			setThreshold(0,Math.ceil(howClose));
			run("Convert to Mask", "method=Default background=Dark black");
			if ((CX < searchRadius) || (CY < searchRadius) || ((CX + searchRadius) > fullImage_width) || ((CY + searchRadius) > fullImage_height)){
				selectWindow("roi_LocThk");
				if (CX < searchRadius){
					run("Canvas Size...", "width="+2*searchRadius+" height="+2*searchRadius+" position=Center-Right");
				}			
				if (CY < searchRadius){
					run("Canvas Size...", "width="+2*searchRadius+" height="+2*searchRadius+" position=Top-Center");
				}
				if ((CX + searchRadius) > fullImage_width)	{
					run("Canvas Size...", "width="+2*searchRadius+" height="+2*searchRadius+" position=Center-Left");
				}
				if ((CY + searchRadius) > fullImage_height) {
					run("Canvas Size...", "width="+2*searchRadius+" height="+2*searchRadius+" position=Bottom-Center");			
				}						
			}
			
			run("Image Expression Parser (Macro)", "expression=[A * (B / 255)] a=roi_LocThk b=from_centroid c=None d=None e=None f=None");
			run("Re-order Hyperstack ...", "channels=[Slices (z)] slices=[Channels (c)] frames=[Frames (t)]");
			run("Z Project...", "projection=[Max Intensity]");			
			
							
																					
			setThreshold(0.05,500000);
			run("Measure");
			locThick = getResult("Mean",nResults()-1);
            print(locThick);
            

			resa = newArray(metStats[0],howClose,locThick);
			//Array.print(res);
			logResults(table,resa);
			
			close("EDT");
			close("roi");
			print("I HAVE DONE THE THING");
			selectWindow(dat);
			close("\\Others");
		}
	
	}
	print("m is still " + m);
	
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

function closeRoiManager(){
	if(isOpen("ROI Manager")){
		selectWindow("ROI Manager");
		run("Close");
	}
	
}
