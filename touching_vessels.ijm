#@ File (label="Base directory", style="directory") sl_dir1
#@ File (label="Filtered results", style="File") resFile
#@ File (label="Bounding Box file", style="file") locFile






print("\\Clear");
sample_label = File.getName(sl_dir1);
print(sample_label);


Table_Heading = "Touching stuff";
columns = "metID,metVol(vox),touchingVol(vox),Number of points";
columns = split(columns,",");
table = generateTable(Table_Heading,columns);

mets = "tmpLbl.tif";
mets_file = sl_dir1+File.separator()+mets;

ves = "tmp_locThk.tif";
ves_file = sl_dir1+File.separator()+ves;

locs = File.openAsString(locFile);
locs = split(locs,'\n');




if(!isOpen(mets)){
	open(mets_file);	
}

if(!isOpen(ves)){
	open(ves_file);
}



x = File.openAsString(resFile);

a = split(x,'\n');
print(a[0]);
b = split(a[0],',');
print(b[9]);

for(l=1;l<a.length;l++){
	b = split(a[l],',');
	if(b[9]=="0.0"){
		Array.print(b);
		metNum = parseInt(b[0]);
		print(metNum);
		thisMet = find_met_location(metNum,locs);
		Array.print(thisMet);
		x = parseInt(thisMet[2]);
		y = parseInt(thisMet[4]);
		w = parseInt(thisMet[3]) - x;
		h = parseInt(thisMet[5]) - y;
		selectWindow(mets);
		makeRectangle(x,y,w,h);
		run("Duplicate...","duplicate title=met_"+metNum+"");
		setThreshold(metNum,metNum);
		setOption("BlackBackground", true);
		run("Convert to Mask", "background=Dark black");
		
		selectWindow(ves);
		makeRectangle(x,y,w,h);
		run("Duplicate...","duplicate title=vessels");

		run("Image Expression Parser (Macro)", "expression=[((A/255) * B) > 0] a=met_"+metNum+" b=vessels c=None d=None");
		run("Re-order Hyperstack ...", "channels=[Slices (z)] slices=[Channels (c)] frames=[Frames (t)]");
		run("Connected Components Labeling", "connectivity=6 type=[16 bits]");
		
		rename("touching");
		run("Analyze Regions 3D", "volume surface_area euler_number surface_area_method=[Crofton (13 dirs.)] euler_connectivity=6");
		
		selectWindow("touching-morpho");
		
		vols = Table.getColumn("Volume");
		Array.getStatistics(vols, min, max, mean, stdDev);
		numberOfPoints = vols.length;
		totalVolume = mean * vols.length;
		print(totalVolume);
		
		selectWindow("met_"+metNum);
		run("Analyze Regions 3D", "volume surface_area euler_number surface_area_method=[Crofton (13 dirs.)] euler_connectivity=6");
		
		selectWindow("met_"+metNum+"-morpho");
		metVol = Table.get("Volume",0);
		
		//metVol = Table.getColumn("Volume",0);
		print(metNum,metVol,totalVolume,numberOfPoints);
		res = newArray(metNum,metVol,totalVolume,numberOfPoints);
		logResults(table,res);
	
	
		cleanUp();
		
		


	}
	
}

function find_met_location(metNum,locArray){	
	for(l=0;l<locArray.length;l++){
		line = split(locArray[l],',');	
		if (parseInt(line[0]) == metNum){			
			return line;
		}
	}
	return false;	
}

function cleanUp(){
	titles = getList("image.titles");6
	for(t=0;t<titles.length;t++){
		if ( (titles[t] != "tmp_locThk.tif") && ( titles[t] != "tmpLbl.tif") ){
			close(titles[t]);	
		}	
	}	
	titles = getList("Window.titles");
	Array.print(titles);
	for(t=0;t<titles.length;t++){
		if(titles[t]!="Touching stuff"){
			close(titles[t]);		
		}
	}	
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

