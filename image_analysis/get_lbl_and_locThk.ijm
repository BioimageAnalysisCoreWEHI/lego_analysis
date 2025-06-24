print("\\Clear");
run("Bio-Formats Macro Extensions");
run("Close All");
dir1 = "V:\\Sabrina\\New_new\\883\\";


c1_fpath = dir1 + "883_MASK_C1.tif";
c2_fpath = dir1 + "883_MASK_C2.tif";
c3_fpath = dir1 + "883_MASK_C3_threshold40.tif";
c4_fpath = dir1 + "883_MASK_C4_threshold195.tif";
rawImg_path = dir1 + "210513_Ms883_PACT clearing_lunglobe_lightsheet_stacktile-Dual Side Fusion-01.czi";

open(c1_fpath);
//run("Median...", "radius=2 stack"); 210513_Ms883_PACT clearing_lunglobe_lightsheet_stacktile-Dual Side Fusion-01.czi

c1 = getTitle();
open(c2_fpath);
//run("Median...", "radius=2 stack");

c2 = getTitle();

print(c1);
print(c2);

imageCalculator("Max create stack", c1,c2);
rename("C1maxC2");

close(c1);
close(c2);
open(c3_fpath);
//run("Median...", "radius=2 stack"); 
c3 = getTitle();
print(c3);

imageCalculator("Max create stack", "C1maxC2",c3);
rename("allMets");
close(c3);
close("C1maxC2");

run("Connected Components Labeling", "connectivity=6 type=float");
saveAs("tif",dir1+"tmpLbl.tif");

run("Analyze Regions 3D", "volume bounding_box surface_area_method=[Crofton (13 dirs.)] euler_connectivity=6");
selectWindow("tmpLbl-morpho");
saveAs("Results",dir1+"tmp_metBbox.csv");

run("Close All");


open(c4_fpath);


Ext.setId(rawImg_path);
Ext.getPixelsPhysicalSizeX(sizeX)
Ext.getPixelsPhysicalSizeZ(sizeZ)
print(sizeX);
print(sizeZ);

Stack.setXUnit("micron");
Stack.setYUnit("micron");
Stack.setZUnit("micron");


scale = 3;
run("Properties...", "pixel_width="+sizeX*scale+" pixel_height="+sizeX*scale+" voxel_depth="+sizeZ);
run("Local Thickness (masked, calibrated, silent)");

for(s=1;s<=nSlices();s++){
	Stack.setSlice(s);
	changeValues(NaN,NaN,0);
}

saveAs("TIF",dir1 + "tmp_locThk.tif");

run("Close All");

