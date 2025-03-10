#@ File (label="Full res source file (czi)", style="file") fpath
#@ File (label="Location of all met label image (TIF Labeled)", style="file") fpath_maskImage
#@ File (label="CSV of met locations", style="file") res_fpath
#@ File (label="Set output directory", style="directory") dir2
#@ Integer (label="Resolution level (not series)",default=3,style="spinner") resolution_level
#@ String (visibility=MESSAGE, value="<HTML><B>Note this value is the ratio of pixel sizes not the series number<BR>ie: series 2 is 1/3 of full res, so set resolution level to 3</HTML>", required=false) msg
#@ Boolean (label="Get pixel size from metadata",default=true) getPixelSizes




run("Bio-Formats Macro Extensions");
print("\\Clear");

run("Close All");

//overwritten below
 
//unless they're not
var pix = 1.0;
var zpix = 1.0;

var res = "";
res = File.openAsString(res_fpath);


if(getPixelSizes){
	Ext.setId(fpath);
	Ext.getPixelsPhysicalSizeX(pix);
	Ext.getPixelsPhysicalSizeZ(zpix);	
}
dir2 = dir2 + File.separator();



checkGobals();


setBatchMode(true);



if(!File.exists(dir2)){
	File.makeDirectory(dir2);
}

res = split(res,"\n");
print(res[0]);

for(m=0;m<res.length;m++){
//for(m=200;m<220;m++){

	metStats = split(res[m],",");
	Array.print(metStats);
	vol = metStats[1];
	vol = parseInt(vol);
	print(m);
	print(vol);
	
	
//	if(vol < 100000 && vol > 1000){ //previously 10000000
	//if(vol > 1000){ //previously 10000000
	if(vol > 1000){ //previously 10000000

		print(vol);
		print("m = ",m);
		x0 = parseInt(metStats[2]);
		width = parseInt(metStats[3]) - x0;
		y0 = parseInt(metStats[4]);
		height = parseInt(metStats[5]) - y0;
		z0 = parseInt(metStats[6]);
		z1 = parseInt(metStats[7]);
		
		if((!File.exists(dir2 + "MET_"+m+".tif") && !File.exists(dir2 + "MET_"+m+"IS TOO BIG.tif")) || !File.exists(dir2+ "MET_"+m+"_with_bg.tif")){
			
			
			makeCrop(x0,y0,width,height,z0,z1);
			data = getTitle();
			x0 = floor(x0 / pix);
			w = floor(width / pix);
			y0 = floor(y0 / pix);
			h = floor(height / pix);
				
			z0 = floor(z0 / zpix) - 2;
			z1 = floor(z1 / zpix) + 2;
			if(z0<1){z0=1;}
			
			print(x0,w,y0,h);
			print(z0,z1);
			print(fpath_maskImage);
			print(m);
						
			getDimensions(width, height, channels, slices, frames);
			tempName = getTitle();
			if(!File.exists(dir2+ "MET_"+m+"_with_bg.tif")){
				saveAs("TIF",dir2 + "MET_"+m+"_with_bg.tif");
				rename(tempName);
			}

			if(!File.exists(dir2 + "MET_"+m+".tif") && !File.exists(dir2 + "MET_"+m+"IS TOO BIG.tif")){
				tooBig = false;				
				if ((width*height*slices*channels) < 2147483647){		
					print(x0,y0,w,h);
					getBinaryLabel(fpath_maskImage,x0,y0,w,h,z0,z1,m);
					run("Image Expression Parser (Macro)", "expression=[A * (B / 255)] a=["+data+"] b=thing");		
				}else{	
					if ((width*height*slices) < 2147483647){		
						getBinaryLabel(fpath_maskImage,x0,y0,w,h,z0,z1,m);
						print("This one is too big to do all at once - doing by channel");	
						splitMask(data,"thing");		
					}else{
						print("This one is just far too big - saving unmasked");					
						tooBig=true;		
					}
				}				
							
				getDimensions(width, height, channels, slices, frames);
	
	
				Stack.setSlice(slices/2);
				run("Make Composite", "display=Composite");
				for(c=1;c<=4;c++){
					Stack.setChannel(c);
					setMinAndMax(0, 4095);
				}
	
				if(tooBig){
					
					saveAs("TIF",dir2 + "MET_"+m+"IS TOO BIG.tif");
				}else{
					saveAs("TIF",dir2 + "MET_"+m+".tif");
				}
			}else{
				print("Already done masked one of " + m);
			}
		
			run("Close All");
		}else{
			print("Met " + m+ " is already done, skipping");
		}
		
	}
	
	
	
	
	

	
}

function makeCrop(xmin,ymin,w,h,z0,z1){

	a = floor(xmin / pix);
	b = floor(w / pix);
	c = floor(ymin / pix);
	d = floor(h / pix);
	print(a,b,c,d);


	
	
	x0 = resolution_level * floor(xmin / pix);
	w = resolution_level * floor(w / pix);
	y0 = resolution_level * floor(ymin / pix);
	h = resolution_level * floor(h / pix);
	
	print(x0,w,y0,h);
	print(x0,w);
	print(y0,h);
	
	z0 = floor(z0 / zpix) - 2;
	z1 = floor(z1 / zpix) + 2;
	
	
	if(z0<1){z0=1;}
	print(z0,z1);
	run("Bio-Formats Importer", "open=["+fpath+"] autoscale color_mode=Default crop rois_import=[ROI manager] specify_range view=Hyperstack stack_order=XYCZT c_begin_1=1 c_end_1=4 c_step=1 z_begin_1="+z0+" z_end_1="+z1+" z_step_1=1 x_coordinate_1="+x0+" y_coordinate_1="+y0+" width_1="+w+" height_1="+h+" series1");
}



function checkGobals(){
	print("fpath = " + fpath);
	print("res_fpath = " + res_fpath);
	print("dir2 = " + dir2);
	print("resolution_level = " + resolution_level);
	print("pix = " + pix);
	print("zpix = " + zpix);	
}



function getBinaryLabel(fpath_maskImage,x0,y0,w,h,z0,z1,metNum){
	run("Bio-Formats Importer", "open=["+fpath_maskImage+"] autoscale color_mode=Default crop rois_import=[ROI manager] view=Hyperstack specify_range stack_order=XYCZT z_begin="+z0+" z_end="+z1+" z_step=1 x_coordinate_1="+x0+" y_coordinate_1="+y0+" width_1="+w+" height_1="+h);
	rename("channelMask");	
	setThreshold(metNum,metNum,"raw");
	run("Convert to Mask", "method=Default background=Dark black");
	getDimensions(width, height, channels, slices, frames);
	newImage("c4Mask", "8-bit white", width, height, slices);
	run("Merge Channels...", "c1=channelMask c2=channelMask c3=channelMask c4=c4Mask create");
	run("Scale...", "x=3 y=3 z=1.0 interpolation=None average create");
	rename("thing");	
}
	
	
function splitMask(data,thing){
	
	selectWindow(data);
		run("Split Channels");
	selectWindow(thing);
	run("Split Channels");
	
	selectWindow("C2-thing");run("Close");
	selectWindow("C3-thing");run("Close");
	selectWindow("C4-thing");run("Close");
	selectWindow("C1-thing");
	rename("onemask");
	
	
	
	run("Image Expression Parser (Macro)", "expression=[A * (B / 255)] a=[C1-"+data+"] b=onemask");
	rename("c1");
	run("Re-order Hyperstack ...", "channels=[Slices (z)] slices=[Channels (c)] frames=[Frames (t)]");
	setMinAndMax(0,65535);
	run("16-bit");
	resetMinAndMax();
	close("C1-"+data);
	
	run("Image Expression Parser (Macro)", "expression=[A * (B / 255)] a=[C2-"+data+"] b=onemask");
	rename("c2");
	run("Re-order Hyperstack ...", "channels=[Slices (z)] slices=[Channels (c)] frames=[Frames (t)]");
	resetMinAndMax();
	setMinAndMax(0,65535);
	run("16-bit");
	close("C2-"+data);
	
	run("Image Expression Parser (Macro)", "expression=[A * (B / 255)] a=[C3-"+data+"] b=onemask");
	rename("c3");
	run("Re-order Hyperstack ...", "channels=[Slices (z)] slices=[Channels (c)] frames=[Frames (t)]");
	resetMinAndMax();
	setMinAndMax(0,65535);
	run("16-bit");
	close("C3-"+data);
	
	run("Merge Channels...", "c1=c1 c2=c2 c3=c3 c4=[C4-"+data+"] create");
	close("onemask");	
	
}
	
	
	
	
