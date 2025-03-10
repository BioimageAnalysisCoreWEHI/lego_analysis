var	res_fpath = "V:\\Sabrina\\New_analysis_with_new_scripts\\917\\917\\All_met_mask_917_new-lbl-morpho.csv";
var	fpath_maskImage = "V:\\Lachie\\Sabrina\\TOO_BIG\\All_met_mask_917_new-lbl.tif";
var tooBig_fpath = "V:\\Sabrina\\New_analysis_with_new_scripts\\917\\917\\917_all_mets\\Toobig\\";
run("Close All");

flist = getFileList(tooBig_fpath){
	for(i=0;i<flist.length;i++){
		if(endsWith(flist[i],"TOO BIG.tif")){
			metNum = substring(flist[i],indexOf(flist[i],"_")+1,indexOf(flist[i],"IS TOO"));
			print(metNum);	
			outName = "MET_"+metNum+".tif";
			if(!File.exists(tooBig_fpath+outName)){
				print("doing stuff");
				openMask(metNum);
				mask = getTitle();
				open(tooBig_fpath+flist[i]);
				toMask = getTitle();	
				make_mask(mask,toMask);
				saveAs("TIF",tooBig_fpath+outName);				
				run("Close All");
			}else{
				print("Skipping "+outName);
			}
			/*
			metNum = substring(flist[i],indexOf(flist[i],"_")+1,indexOf(flist[i],"IS TOO"));
			print(metNum);	
			openMask(metNum);
			mask = getTitle();
			open(tooBig_fpath+flist[i]);
			toMask = getTitle();	
			make_mask(mask,toMask);
			exit();
			*/
					
		}
	}
}



function openMask(metNum){

	
	var res = "";
	res = File.openAsString(res_fpath);
	res = split(res,"\n");
	print(res[0]);
	
	
	m = metNum;
	//for(m=200;m<220;m++){
	pix = 1.2197;
	zpix = 2.9170;
	
	metStats = split(res[m],",");
	Array.print(metStats);
	vol = metStats[1];
	vol = parseInt(vol);
	print(m);
	print(vol);
	
	print("m = ",m);
	x0 = parseInt(metStats[2]);
	width = parseInt(metStats[3]) - x0;
	y0 = parseInt(metStats[4]);
	height = parseInt(metStats[5]) - y0;
	z0 = parseInt(metStats[6]);
	z1 = parseInt(metStats[7]);
	
	x0 = floor(x0 / pix);
	w = floor(width / pix);
	y0 = floor(y0 / pix);
	h = floor(height / pix);
				
	z0 = floor(z0 / zpix) - 2;
	z1 = floor(z1 / zpix) + 2;
	
		
	getBinaryLabel(fpath_maskImage,x0,y0,w,h,z0,z1,metNum);
}


function make_mask(mask,toMask){
	selectWindow(mask);
	n = nSlices();
	print(n);
	for(i=1;i<=n;i++){
		closeRoiManager();
		
		selectWindow(mask);
		safety=0;
		while((roiManager("Count") == 0) && (safety<50)){
			
			run("Select None");
			Stack.setFrame(i);
			Stack.setSlice(i);
			selectWindow(mask);
			wait(1);
			setThreshold(128,255);
			wait(0.5);
			run("Analyze Particles...", "clear add slice");
			roiManager("Select",Array.getSequence(roiManager("Count")));
			roiManager("Combine");
			
			roiManager("Add");
			
			selectWindow(toMask);
			Stack.setFrame(i);
			Stack.setSlice(i);	
			if(roiManager("Count") == 0){
				print("Going again because shit is stupid");
				wait(50);	
			}
			safety++;
		}
		nRois = roiManager("Count");
		
		roiManager("Select",nRois-1);
		run("Scale... ", "x=3 y=3");
		
		
		run("Make Inverse");
		roiManager("Add");	
		roiManager("Show None");
		
		setBackgroundColor(0, 0, 0);
		for(c=1;c<=4;c++){
			Stack.setChannel(c);
			run("Clear", "slice");
		}
	}
}



function closeRoiManager(){
	if(isOpen("ROI Manager")){
		selectWindow("ROI Manager");
		run("Close");
	}
}




function getBinaryLabel(fpath_maskImage,x0,y0,w,h,z0,z1,metNum){
	run("Bio-Formats Importer", "open=["+fpath_maskImage+"] autoscale color_mode=Default crop rois_import=[ROI manager] view=Hyperstack specify_range stack_order=XYCZT z_begin="+z0+" z_end="+z1+" z_step=1 x_coordinate_1="+x0+" y_coordinate_1="+y0+" width_1="+w+" height_1="+h);
	
	rename("channelMask");
	setThreshold(metNum,metNum,"raw");
	
	
	run("Convert to Mask", "method=Default background=Dark black");
}
	
function merge(){	
	getDimensions(width, height, channels, slices, frames);
	newImage("c4Mask", "8-bit white", width, height, slices);
	run("Merge Channels...", "c1=channelMask c2=channelMask c3=channelMask c4=c4Mask create");
	run("Scale...", "x=3 y=3 z=1.0 interpolation=None average create");
	rename("thing");
}
	
	