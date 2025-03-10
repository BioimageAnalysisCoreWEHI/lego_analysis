#@ File (label="Choose source folder with extracted mets (raw)",style="directory") MET_PATH_tmp
#@ Integer (label="Start from MET number",value=1) startFrom
#@ Boolean (label="Automatically place windows",value=true) placeWindows
#@ Boolean (label="Scale intensities",value=true) scaleI
#@ int (label="C1 Min Intensity",style="Slider",min=0,max=65535) minInt_C1
#@ int (label="C1 Max Intensity",style="Slider",min=0,max=65535) maxInt_C1
#@ int (label="C2 Min Intensity",style="Slider",min=0,max=65535) minInt_C2
#@ int (label="C2 Max Intensity",style="Slider",min=0,max=65535) maxInt_C2
#@ int (label="C3 Min Intensity",style="Slider",min=0,max=65535) minInt_C3
#@ int (label="C3 Max Intensity",style="Slider",min=0,max=65535) maxInt_C3
//#@ Boolean (label="Debug mode",value=false) debugMode

print("\\Clear");
run("Close All");

var MET_PATH = "a"; //initialising - not sure why this is now necessary...?
var MASK_PATH = "a";
var SHOW_MIP = false;
//var tablePath = tablePath;


MET_PATH = MET_PATH_tmp + File.separator();

var dir2 = MET_PATH + "CORRECTED_METS";

if(!File.exists(dir2)){
	File.makeDirectory(dir2);
}

if(File.exists(dir2 + File.separator() + "notes.csv")){
	exit("Notes exist - copy them somewhere else\n\nThis script will overwrite them");
}

Table_Heading = "Met Notes";
cols = newArray("MET NUMBER", "Happy?","Notes");
table = generateTable(Table_Heading,cols);

/*
 * I've changed my mind, this should now be done in a later step to save human time
 * 
SCORE_Table_Heading = "score_table"; 
channelKey = newArray("MET NUMBER","100","010","110","001","101","011","111");
SCORE_table = generateTable(SCORE_Table_Heading,channelKey);
*/




flist = getFileList(MET_PATH);
flist = Array.sort(flist);

tables = newArray();
for(i=0;i<flist.length;i++){
	if(endsWith(flist[i],"csv")){
		tables = Array.concat(tables,flist[i]);		
	}
}

for(i=0;i<flist.length;i++){
	if(matches(flist[i],"Met_([0-9]*).tif")){
		startRegex = indexOf(flist[i],"_")+1;
		endRegex = indexOf(flist[i],".");
		metNum = substring(flist[i],startRegex,endRegex);
		if(!File.exists(dir2 + File.separator() + "MET_"+metNum+".tif_stackMask.tif") && metNum>=startFrom){		
			
			scores = getScores(tables);
			Array.print(scores);
			a  = getSpecificScore(scores,metNum);
			Array.print(a);
			nZeros = 0;			
			for(c=2;c<=8;c++){
				if(parseFloat(a[c])==0){
					nZeros++;
				}
			}			
			if(nZeros==6){
				isMultiColor = false;
			}else{
				isMultiColor = true;
			}
			displayMet(metNum);
			metBin = getTitle();
			if(isMultiColor){					
				waitForUser("Inspect closely.\n\n\nPress OK when you're ready to make a call\n\n\nYou won't be able to interact with data after this");
				happy = getBoolean("Happy with this one?");
				while(!happy){
					//not happy Jan
					happyOrNot = "Not Happy";
					beginValidation(metBin);		
					waitForUser("Inspect closely.\n\n\nPress OK when you're ready to make a call\n\n\nYou won't be able to interact with data after this");
					happy = getBoolean("Happy now?\n\nIf not, get ready to go again!");
				}
				
				happyOrNot = "Happy";
				notes = getString("Make some notes?","");
			}else{
				happyOrNot = "Happy (auto)";
				notes = "Auto - single coluor";
			}
			selectWindow(metBin);
			
			saveAs("TIF",dir2 + File.separator() + metBin);
			res = newArray(metNum,happyOrNot,notes);
			logResults(table,res);

			/*			
			new_scores = scoreLego(metBin);
			logResults(SCORE_table,new_scores);
			exit();
			*/
			
			
			selectWindow(Table_Heading);
			saveAs("Results",dir2+File.separator()+"notes.csv");
			run("Close All");
		}
	}
}

function beginValidation(metBin){
	
	makeKeyBar();
	
	ch=0;
	showText("ASDF", "Click on colour you want to correct");
	while(ch==0){
		ch = getColorClickedOn();
	}
	selectWindow("ASDF");
	run("Close");

	selectWindow(metBin);
	run("Duplicate...","duplicate title=oops");	
	run("Duplicate...","duplicate title=Ch"+ch+" channels="+ch+"-"+ch);
	
	//keepOrDelete = getThreeChoice("Keep what\nyou click on","Correct what\nyou click on","Delete all but\nthis channel");
	keepOrDelete = getFourChoice("Keep what\nyou click on","Correct what\nyou click on","Delete all but\nthis channel","Relabel everything\nthis channel");

	if(keepOrDelete != "Relabel everything\nthis channel"){
		if(keepOrDelete == "Keep what\nyou click on"){
			filterForKeeps("Ch"+ch);
		}else{
			if(keepOrDelete == "Correct what\nyou click on"){
				filterForDeletes("Ch"+ch);
			}else{
				print("Delete-y");				
			}
		}
	
		if(keepOrDelete != "Delete all but\nthis channel"){
		
			ReassignOrDelete = getChoiceBox("Reassign\n\"Change\"","Delete\n\"Change\"");
			
			selectWindow(metBin);
			run("Split Channels");
			remapMerge(metBin,ch);			
			if(ReassignOrDelete == "Delete\n\"Change\""){
				close("Change");
			}else{
				showText("ASDF", "Click on colour to merge to");
				toMergeTo = getColorClickedOn();
				selectWindow("ASDF");
				run("Close");
				mergeWithChannel(metBin,"Change",toMergeTo);			
				close("Change");
			}	
		}else{
			//delete all but
			deleteAllBut(metBin,ch);
			rename(metBin);		
		}
	}else{		
		selectWindow(metBin);
		run("Split Channels");
		run("Image Expression Parser (Macro)", "expression=A+B+C+D+E+F+G a=C1-"+metBin+" b=C2-"+metBin+" c=C3-"+metBin+" d=C4-"+metBin+" e=C5-"+metBin+" f=C6-"+metBin+" g=C7-"+metBin+" h=None i=None j=None k=None l=None m=None");
		run("8-bit");
		run("Re-order Hyperstack ...", "channels=[Slices (z)] slices=[Channels (c)] frames=[Frames (t)]");
		rename("correct");
		selectWindow("C1-"+metBin);
		run("Select All");
		setBackgroundColor(0,0,0);
		run("Clear","stack");
		rename("blank");


		if(ch==1){run("Merge Channels...", "c1=correct c2=blank c3=blank c4=blank c5=blank c6=blank c7=blank create");}	
		if(ch==2){run("Merge Channels...", "c1=blank c2=correct c3=blank c4=blank c5=blank c6=blank c7=blank create");}	
		if(ch==3){run("Merge Channels...", "c1=blank c2=blank c3=correct c4=blank c5=blank c6=blank c7=blank create");}	
		if(ch==4){run("Merge Channels...", "c1=blank c2=blank c3=blank c4=correct c5=blank c6=blank c7=blank create");}	
		if(ch==5){run("Merge Channels...", "c1=blank c2=blank c3=blank c4=blank c5=correct c6=blank c7=blank create");}	
		if(ch==6){run("Merge Channels...", "c1=blank c2=blank c3=blank c4=blank c5=blank c6=correct c7=blank create");}	
		if(ch==7){run("Merge Channels...", "c1=blank c2=blank c3=blank c4=blank c5=blank c6=blank c7=correct create");}	
		rename(metBin);
		getDimensions(width, height, channels, slices, frames);
		Stack.setSlice(slices/2);
		colourBinary();
		close("C*");	
	}

	
	close("Untitled");

	ContinueOrUndo = getChoiceBox("Continue","Undo");
	if(ContinueOrUndo == "Continue"){
		print("ok");
		close("oops");		
	}else{
		close(metBin);
		selectWindow("oops");
		rename(metBin);		
	}
}


function displayMet(MET_NUMBER){
		
	dataPath = MET_PATH + "Met_"+MET_NUMBER+".tif";	
	maskPath3D = MET_PATH + "met_"+MET_NUMBER+"_mask.tif";
	
	//scores = getScores(tablePath);
	//a  = getSpecificScore(scores,MET_NUMBER);
	//makeBars(a);
	


	open(dataPath);
	Stack.setChannel(1);run("Cyan");
	Stack.setChannel(2);run("Yellow");
	Stack.setChannel(3);run("Magenta");
	run("Make Composite");
	Stack.setActiveChannels("1110");
	if(scaleI){
		Stack.setChannel(1);setMinAndMax(minInt_C1, maxInt_C1);
		Stack.setChannel(2);setMinAndMax(minInt_C2, maxInt_C2);
		Stack.setChannel(3);setMinAndMax(minInt_C3, maxInt_C3);
		
	}
	Stack.setActiveChannels("1110");
	getDimensions(width, height, channels, slices, frames);
	Stack.setSlice(slices/2);
	
	open(maskPath3D);
	colourBinary();
	run("Make Composite");
	Stack.setSlice(slices/2);
	run("Set... ", "zoom=300"); 
	
}





function getSpecificScore(scores,metNum){
	output = false;
	
	for(i=1;i<scores.length;i++){

		if(matches(scores[i],".*,.*")){
			l = split(scores[i],",");
		}
		if(matches(scores[i],".*\\t.*")){
			l = split(scores[i],"\t");
		}
	
		//print(l[0]);
		thisMet = l[0];
		if(matches(thisMet,metNum)){		
			output = true;
			toReturn = l;
		}else{
	//		print("nah");
		}
	}
	if(output){
		return toReturn;
	}else{
		return false;
	}	
}

function getScores(tables){
	scores = newArray();
	for(i=0;i<tables.length;i++){
		data = MET_PATH + tables[i];
		asdf = File.openAsString(data);
		asdf = split(asdf,"\n");
		scores = Array.concat(scores,asdf);
	}
	return scores;	
}

function makeBars(thisMetData){
	newImage("Untitled", "RGB black", 10, 100, 1);
	i = 0;
	j = parseFloat(thisMetData[1]) * 100.0;
	j = floor(j);
	//setForegroundColor("Red");
	//cyan
	setForegroundColor(0,255,255);
	makeRectangle(0,i,10,j);
	run("Fill");

	i=i+j;
	j = parseFloat(thisMetData[2]) * 100.0;
	j = floor(j);
	//yellow
	setForegroundColor(255,255,0);
	makeRectangle(0,i,10,j);
	run("Fill");

	i=i+j;
	j = parseFloat(thisMetData[3]) * 100.0;
	j = floor(j);
	//green
	setForegroundColor(0,255,0);
	makeRectangle(0,i,10,j);
	run("Fill");
	
	i=i+j;
	j = parseFloat(thisMetData[4]) * 100.0;
	j = floor(j);
	//magenta
	setForegroundColor(255,0,255);
	makeRectangle(0,i,10,j);
	run("Fill");

	i=i+j;
	j = parseFloat(thisMetData[5]) * 100.0;
	j = floor(j);
	//purple
	setForegroundColor(117,0,255);
	makeRectangle(0,i,10,j);
	run("Fill");
	
	i=i+j;
	j = parseFloat(thisMetData[6]) * 100.0;
	j = floor(j);
	//orange
	setForegroundColor(255,117,0);
	makeRectangle(0,i,10,j);
	run("Fill");
	

	i=i+j;
	j = parseFloat(thisMetData[7]) * 100.0;
	j = floor(j);
	setForegroundColor(255,255,255);
	makeRectangle(0,i,10,j);
	run("Fill");

	run("Select None");
	setLocation(100,100);
	run("Set... ", "zoom=800 x=5 y=50");
		
}


function makeKeyBar(){
	newImage("KeyBar", "RGB black", 10, 100, 1);
	
	i = 0;
	j = 15;
	setForegroundColor("Red");
	//cyan
	setForegroundColor(0,255,255);
	makeRectangle(0,i,10,j);
	run("Fill");

	i=i+j;
	j = 15;
	//yellow
	setForegroundColor(255,255,0);
	makeRectangle(0,i,10,j);
	run("Fill");

	i=i+j;
	j = 15;
	//green
	setForegroundColor(0,255,0);
	makeRectangle(0,i,10,j);
	run("Fill");
	
	i=i+j;
	j = 15;
	//magenta
	setForegroundColor(255,0,255);
	makeRectangle(0,i,10,j);
	run("Fill");

	i=i+j;
	j = 15;
	//purple
	setForegroundColor(117,0,255);
	makeRectangle(0,i,10,j);
	run("Fill");
	
	i=i+j;
	j = 15; 
	//orange
	setForegroundColor(255,117,0);
	makeRectangle(0,i,10,j);
	run("Fill");

	i=i+j;
	j = 15;
	//white
	setForegroundColor(255,255,255);
	makeRectangle(0,i,10,j);
	run("Fill");

	run("Select None");
	setLocation(100,100);
	run("Set... ", "zoom=800 x=5 y=50");
		
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



function getColorClickedOn(){	
	setTool("Rectangle");
	flags = 0;
	leftButton = 16;

	while (flags != leftButton){
		selectWindow("KeyBar");
		getCursorLoc(x, y, z, flags);
	}

	v = getPixel(x,y);
	red = (v>>16)&0xff;  // extract red byte (bits 23-17)
	green = (v>>8)&0xff; // extract green byte (bits 15-8)
	blue = v&0xff;       // extract blue byte (bits 7-0)

	if(red==0 && green==255 && blue==255){
		print("Cyan");
		ch = 1;
	}
	if(red==255 && green==255 && blue==0){
		print("Yellow");
		ch = 2;
	}
	if(red==0 && green==255 && blue==0){
		print("Green");
		ch = 3;
	}

	if(red==255 && green==0 && blue==255){
		print("Magenta");
		ch = 4;
	}
	if(red==117 && green==0 && blue==255){
		print("Purple");
		ch = 5;
	}
	if(red==255 && green==117 && blue==0){
		print("Orange");
		ch = 6;
	}
	if(red==255 && green==255 && blue==255){
		print("white");
		ch = 7;
	}
	return ch;
}	



function getChoiceBox(choice1,choice2){
	newImage("Make your choice", "RGB Black", 400, 100, 1);
	//if doing this then move box so you can see it
	if(choice1=="Reassign\n\"Change\""){
		l = getInfo("log");
		l = split(l," ");
		setLocation(l[0],l[1]-150);
		//Array.print(l);				
	}
	
	
	
	makeRectangle(0,0,200,100);
	setColor("white");
	run("Fill");	
	run("Select None");

	setFont("SansSerif", 20, "bold");
	setColor(10, 10, 10);
	 x=50; y=50;
  	drawString(choice1, x, y);

	setColor(240, 240, 240);
	 x=250; y=50;
  	drawString(choice2, x, y);

  	setTool("Rectangle");
	flags = 0;
	leftButton = 16;

	while (flags != leftButton){
		selectWindow("Make your choice");
		getCursorLoc(x, y, z, flags);
	}

	v = getPixel(x,y);
	red = (v>>16)&0xff;  // extract red byte (bits 23-17)
	green = (v>>8)&0xff; // extract green byte (bits 15-8)
	blue = v&0xff;       // extract blue byte (bits 7-0)

	if(red==255 || red == 240){
		choice = choice1;
	}else{
		choice = choice2;
	}
	selectWindow("Make your choice");
	
	run("Close");
	print(choice);
	return choice;	
}

function filterForKeeps(ch){
	selectWindow(ch);
	setTool("multipoint");
	while(selectionType()==-1){
		waitForUser("Scrub through stack and click on stuff to keep\n \nPlease only click on window titled "+ch);
	
	}
	
	run("Interactive Morphological Reconstruction 3D", "type=[By Dilation] connectivity=6");
	rename("Keep");
	imageCalculator("Subtract create stack", ch,"Keep");
	rename("Change");
	Stack.setSlice(nSlices/2);
	
	getLocationAndSize(x, y, width, height);
	print("\\Clear");
	print(x,y,width,height);
	selectWindow(ch);
	run("Close");
}


function filterForDeletes(ch){
	selectWindow(ch);
	setTool("multipoint");
	while(selectionType()==-1){
		waitForUser("Scrub through stack and click on stuff to change\n \nPlease only click on window titled "+ch);		
	}
	
	run("Interactive Morphological Reconstruction 3D", "type=[By Dilation] connectivity=6");
	rename("Change");
	imageCalculator("Subtract create stack", ch,"Change");
	rename("Keep");
	selectWindow("Change");
	Stack.setSlice(nSlices/2);
	getLocationAndSize(x, y, width, height);
	print("\\Clear");
	print(x,y,width,height);
	selectWindow(ch);
	run("Close");
	//close(ch);//someitmes this prompts to save?!
}

function deleteAllBut(metbin,ch){
	selectWindow("Ch"+ch);
	rename("correct");
	getDimensions(width, height, channels, slices, frames);
	newImage("blank", "8-bit black", width, height, slices);
	close(metbin);
	if(ch==1){run("Merge Channels...", "c1=correct c2=blank c3=blank c4=blank c5=blank c6=blank c7=blank create");}	
	if(ch==2){run("Merge Channels...", "c1=blank c2=correct c3=blank c4=blank c5=blank c6=blank c7=blank create");}	
	if(ch==3){run("Merge Channels...", "c1=blank c2=blank c3=correct c4=blank c5=blank c6=blank c7=blank create");}	
	if(ch==4){run("Merge Channels...", "c1=blank c2=blank c3=blank c4=correct c5=blank c6=blank c7=blank create");}	
	if(ch==5){run("Merge Channels...", "c1=blank c2=blank c3=blank c4=blank c5=correct c6=blank c7=blank create");}	
	if(ch==6){run("Merge Channels...", "c1=blank c2=blank c3=blank c4=blank c5=blank c6=correct c7=blank create");}	
	if(ch==7){run("Merge Channels...", "c1=blank c2=blank c3=blank c4=blank c5=blank c6=blank c7=correct create");}	
}




function remapMerge(metBin,ch){
	//<hack>
	if(isOpen("Keep")){selectWindow("Keep");rename("correct");}
	//</hack>
	if(ch==1){run("Merge Channels...", "c1=correct c2=C2-"+metBin+" c3=C3-"+metBin+" c4=C4-"+metBin+" c5=C5-"+metBin+" c6=C6-"+metBin+" c7=C7-"+metBin+" create");}	
	if(ch==2){run("Merge Channels...", "c1=C1-"+metBin+" c2=correct c3=C3-"+metBin+" c4=C4-"+metBin+" c5=C5-"+metBin+" c6=C6-"+metBin+" c7=C7-"+metBin+" create");}	
	if(ch==3){run("Merge Channels...", "c1=C1-"+metBin+" c2=C2-"+metBin+" c3=correct c4=C4-"+metBin+" c5=C5-"+metBin+" c6=C6-"+metBin+" c7=C7-"+metBin+" create");}	
	if(ch==4){run("Merge Channels...", "c1=C1-"+metBin+" c2=C2-"+metBin+" c3=C3-"+metBin+" c4=correct c5=C5-"+metBin+" c6=C6-"+metBin+" c7=C7-"+metBin+" create");}	
	if(ch==5){run("Merge Channels...", "c1=C1-"+metBin+" c2=C2-"+metBin+" c3=C3-"+metBin+" c4=C4-"+metBin+" c5=correct c6=C6-"+metBin+" c7=C7-"+metBin+" create");}	
	if(ch==6){run("Merge Channels...", "c1=C1-"+metBin+" c2=C2-"+metBin+" c3=C3-"+metBin+" c4=C4-"+metBin+" c5=C5-"+metBin+" c6=correct c7=C7-"+metBin+" create");}	
	if(ch==7){run("Merge Channels...", "c1=C1-"+metBin+" c2=C2-"+metBin+" c3=C3-"+metBin+" c4=C4-"+metBin+" c5=C5-"+metBin+" c6=C6-"+metBin+" c7=correct create");}	
/*	Stack.setChannel(1);run("Red");//100
	Stack.setChannel(2);run("Green");//010
	Stack.setChannel(3);run("Yellow");//110
	Stack.setChannel(4);run("Blue");//001
	Stack.setChannel(5);run("Magenta");//101
	Stack.setChannel(6);run("Cyan");//011
	Stack.setChannel(7);run("Grays");//111
	*/
	Stack.setChannel(1);run("Cyan");//100
	Stack.setChannel(2);run("Yellow");//010
	Stack.setChannel(3);run("Green");//110
	Stack.setChannel(4);run("Magenta");//001
	Stack.setChannel(5);run("  9 Purple ");//101
	Stack.setChannel(6);run("  8 Orange ");;//011
	Stack.setChannel(7);run("Grays");//111

	rename(metBin);
	close("C"+ch+"-"+metBin);
	close("correct");
}

function mergeWithChannel(metBin,toMerge,toMergeTo){
	print(toMergeTo);
	selectWindow(metBin);
	run("Split Channels");
	imageCalculator("Add create stack", toMerge,"C"+toMergeTo+"-"+metBin);
	rename("correct");
	remapMerge(metBin,toMergeTo);	
	
}



function getThreeChoice(c1,c2,c3){
	newImage("Make your choice", "RGB Black", 400, 202, 1);
	makeRectangle(0,0,200,100);
	setColor("white");
	run("Fill");	
	run("Select None");
	setFont("SansSerif", 20, "bold");
	setColor(10, 10, 10);
	 x=50; y=50;
  	drawString(c1, x, y);
	setColor(240, 240, 240);
	 x=250; y=50;
  	drawString(c2, x, y);
	makeRectangle(0,102,400,100);
	setColor(1,128,255);
	run("Fill");	
	run("Select None");
	setColor(254,255,0);
	x=120; y=150;
	drawString(c3, x, y);

  	setTool("Rectangle");
	flags = 0;
	leftButton = 16;
	
	while (flags != leftButton){
		selectWindow("Make your choice");
		getCursorLoc(x, y, z, flags);	
	}

	v = getPixel(x,y);
	red = (v>>16)&0xff;  // extract red byte (bits 23-17)
	green = (v>>8)&0xff; // extract green byte (bits 15-8)
	blue = v&0xff;       // extract blue byte (bits 7-0)
	

	if(red==255 || red == 240){
		choice = c1;
	}else{
		if(red==1 || red==254){
			choice = c3;
		}else{
			choice = c2;
		}		
	}
	selectWindow("Make your choice");
	run("Close");
	
	return choice;	
	
}

function getFourChoice(c1,c2,c3,c4){
	
	newImage("Make your choice", "RGB Black", 400, 202, 1);
	makeRectangle(0,0,200,100);
	setColor("white");
	run("Fill");	
	run("Select None");
	setFont("SansSerif", 20, "bold");
	setColor(10, 10, 10);
	 x=50; y=50;
  	drawString(c1, x, y);
	setColor(240, 240, 240);
	 x=250; y=50;
  	drawString(c2, x, y);
  	
	makeRectangle(0,102,200,100);
	setColor(1,128,255);
	run("Fill");	
	run("Select None");
	setColor(254,255,0);
	x=20; y=150;
	drawString(c3, x, y);

	makeRectangle(200,102,200,100);
	setColor(2,255,128);
	run("Fill");	
	run("Select None");
	setColor(2,0,255);
	x=220; y=150;
	drawString(c4, x, y);

  	setTool("Rectangle");
	flags = 0;
	leftButton = 16;

	while (flags != leftButton){
		selectWindow("Make your choice");
		getCursorLoc(x, y, z, flags);
	}

	v = getPixel(x,y);
	red = (v>>16)&0xff;  // extract red byte (bits 23-17)
	green = (v>>8)&0xff; // extract green byte (bits 15-8)
	blue = v&0xff;       // extract blue byte (bits 7-0)
	

	if(red==255 || red == 240){
		choice = c1;
	}else{
		if(red==1 || red==254){
			choice = c3;
		}else{
			if(red==2){
				choice = c4;
			}else{
				choice = c2;
			}
		}		
	}
	selectWindow("Make your choice");
	run("Close");
	
	return choice;	
	
}

function colourBinary(){
	/*
	Stack.setChannel(1);run("Red");
	Stack.setChannel(2);run("Green");
	Stack.setChannel(3);run("Yellow");
	Stack.setChannel(4);run("Blue");
	Stack.setChannel(5);run("Magenta");
	Stack.setChannel(6);run("Cyan");
	Stack.setChannel(7);run("Grays");
	*/
	Stack.setChannel(1);run("Cyan");//100
	Stack.setChannel(2);run("Yellow");//010
	Stack.setChannel(3);run("Green");//110
	Stack.setChannel(4);run("Magenta");//001
	Stack.setChannel(5);run("  9 Purple ");//101
	Stack.setChannel(6);run("  8 Orange ");;//011
	Stack.setChannel(7);run("Grays");//111	
}



	
function scoreLegoChannel(c){
	run("Clear Results");
	//if(!debugMode){
		run("Median...","radius=2 stack");
	//}
	
	//run("3D Geometrical Measure");depricated apparently
	//run("3D Volume Surface");
 //also depricated >:(
	
	
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
		totalVol = totalVol + AllChannelRes[n];
	}

	PC_Array = newArray();
	for(n=3;n<AllChannelRes.length;n=n+4){
		print("Line 270");
		Array.print(AllChannelRes);		
		print(n,AllChannelRes[n]);
		PC_Array = Array.concat(PC_Array,AllChannelRes[n] / totalVol);
		Array.print(PC_Array);
	}
	
	return PC_Array;	
}




