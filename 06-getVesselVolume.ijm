#@ File (label="Base directory", style="directory") sl_dir1
#@ File (label="Filtered results", style="File") resFile
#@ File (label="Bounding Box file", style="file") locFile
print("\\Clear");
mets = "tmpLbl.tif";
mets_file = sl_dir1+File.separator()+mets;

ves = "tmp_locThk.tif";
ves_file = sl_dir1+File.separator()+ves;

locs = File.openAsString(locFile);
locs = split(locs,'\n');


Table_Heading = "Vessel Vols";
columns = "metID,Vessel Volume";
columns = split(columns,",");
table = generateTable(Table_Heading,columns);

mets = newArray();
vols = newArray();

if(!isOpen(ves)){
	open(ves_file);
	ves = getTitle();
}
closeRoiManager();
flist = getFileList(sl_dir1 + File.separator + "output_mets");

for(i=0;i<flist.length;i++){
	fname = flist[i];
	if(matches(fname,"Met_[0-9]*.tif")){
		print(fname);
		metNum = split(fname,"_");
		metNum = substring(metNum[1],0,indexOf(metNum[1],"."));
		metNum = parseInt(metNum);
		thisMet = find_met_location(metNum,locs);
		
		x = parseInt(thisMet[2]);
		y = parseInt(thisMet[4]);
		w = parseInt(thisMet[3]) - x;
		h = parseInt(thisMet[5]) - y;
		z1 = thisMet[6];
		z2 = thisMet[7];
		selectWindow(ves);
		makeRectangle(x,y,w,h);
		roiManager("Add");
		
		run("Duplicate...","title=met_"+metNum+" duplicate range="+z1+"-"+z2+"");
		
		setThreshold(1,65535);
		run("Convert to Mask","black");
		run("Analyze Regions 3D", "volume surface_area_method=[Crofton (13 dirs.)]");
		
		if(Table.size==0){
			vol = 0;
		}else{
			vol = Table.get("Volume",0);
		}
		res = newArray(metNum,vol);//,totalVolume,numberOfPoints);
		logResults(table,res);
		
		close("met_"+metNum);
		close("met_"+metNum+"-morpho");
		
		
	}else{
		print("NO");
		print(fname);
		
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

function closeRoiManager(){
	if(isOpen("ROI Manager")){
		selectWindow("ROI Manager");
		run("Close");
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