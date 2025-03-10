#@ File (label="Directory full of slices", style="Directory") dir1
#@ File (label="Output Directory", style="Directory") dir2
#@ File (label="Ilastik project file", style="File") ilastikFile
#@ Integer (label="Channel with vessel prediction",default=1,style="spinner") c
#@ Boolean (label="Stack at the end") doStack
#@ Boolean (label="Keep slices? (Will be deleted if false)") keepSlices

run("Close All");
flist = getFileList(dir1);
if(!File.exists(dir2)){
	File.makeDirectory(dir2);
}

debugMode = false;

if(!debugMode){
	for(i=0;i<flist.length;i++){
		if(endsWith(flist[i],"tif")){
			if( !File.exists(dir2+File.separator()+flist[i]+"_pred.tif" )){
		
			open(dir1 + File.separator() +  flist[i]);
			fname = getTitle();
			
			run("Run Pixel Classification Prediction", "projectfilename=["+ilastikFile+"] inputimage=["+fname+"] pixelclassificationtype=Probabilities");
			
			run("Duplicate...","title=pred duplicate channels="+c+"-"+c);
			//run("MQ div-emerald ");
			run("Fire");
			setMinAndMax(0, 1);
			run("8-bit");
			saveAs("TIF",dir2+File.separator()+fname+"_pred.tif");
			run("Close All");	
			}else{
				print("Already done image " + i);
			}
		}	
	}
}



if(doStack){
	File.openSequence(dir2+File.separator());
	if(!keepSlices){
		del_flist = getFileList(dir2);
		for(j=0;j<del_flist.length;j++){
			File.delete(dir2 + File.separator() + del_flist[j]);
		}
	}
	saveAs("TIF",dir2 + File.separator() + "vessel_stack.tif");	
}

showMessage("<HTML><H1>DONE</H1></HTML>");