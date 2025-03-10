#@ File (label="Choose folder with corrected masks",style="directory") corrected_dir
#@ Boolean (label="Placebo button",default=true) out_dir


print("\\Clear");
run("Close All");

SCORE_Table_Heading = "score_table"; 
channelKey = newArray("MET NUMBER","100","010","110","001","101","011","111");
SCORE_table = generateTable(SCORE_Table_Heading,channelKey);


flist = getFileList(corrected_dir);
flist = Array.sort(flist);

for(i=0;i<flist.length;i++){
	if(matches(flist[i],"MET_([0-9]*).*tif.*")){
		fpath = corrected_dir + File.separator + flist[i];
		open(fpath);
		startRegex = indexOf(flist[i],"_")+1;
		endRegex = indexOf(flist[i],".");
		metNum = substring(flist[i],startRegex,endRegex);		
		metBin = getTitle();
		new_scores = scoreLego(metBin);
		res = Array.concat(metNum,new_scores);
		logResults(SCORE_table,res);		
		
		run("Close All");
	}
}


exit("Done - Don't forget to save the table");



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
		thisMet = substring(l[0],4,lengthOf(l[0])-5);
//		print(thisMet);
//		print(metNum);
		if(matches(thisMet,metNum)){
			
			output = true;
			toReturn = l;
			
		}else{
	//		print("nah");
			
		}
		//print(i);
		
	}
	if(output){
		return toReturn;
	}else{
		return false;
	}


	
}

function getScores(data){
	asdf = File.openAsString(data);
	asdf = split(asdf,"\n");
	return asdf;
	
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

