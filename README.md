# Lego Pipeline

## Initial Data Handling
- If necessary - stitch/fuse in Zen
  - Alternatively select just one side-view 
- Open full resolution channels individually and save as TIFs
  - can optionally be converted to 8-bit to save computational resources
- Segment each channel individually (see segmentation instructions below)
- Combine all three met channels to create one "All met" mask 
- Segment vessel image manually if possible, alternatively attempt via ilastik

## Get the Mets
 - On the "all met" mask image - run:
   - MorpholibJ Plugin
     - Binary 
       - Connected Components Labelling
     - Analyse
       - Analyse 3d
         - Select Volume and Bounding Box
   - Save Results table as csv

## Extract Mets
### 01-Extract_All_Mets.ijm macro
- Make sure pixel values are correct (shouldn't need changing but might)
- Specify a directory to save met images to (line 6)
- Specify location of bounding box csv (line 8)
- Set volume cut-off  (line 18)
- Run
  - Set and forget, can take a long time depending on number of mets

## Lego scoring 
### 02-Lego_Met_Scoring.ijm
- Make sure you have "Neurocyto LUTs" plugin site installed
- Specify dir1 (directory with the met images from the previous step)
- Specify dir2 (directory to save binary lego masks to)
- If you want to use manual thresholds instead of allowing the macro to attempt an autothreshold, then:
  - change USE_MANUAL_THRESHOLD to true 
  - set the c1,c2 and c3 thresholds (c1_th, c2_th, and c3_th)

##  Validation 
#### Optional? Here or later? 
### 03-Manual_Validation.ijm
- Has proper menu
- Specify directory with mets from above
- Specify which met ID to start from
- ![Super intuitive flow diagram](img/LeGO%20Flow.png)

## Lego Volume and Location Scoring
## LEGO_LOCATIONS.ijm
- Specify volume / bounding box csv from above 
- Specify the segmented, local thickness vessel image 
- Specify pixel and volume size of the thickness image (may be different if vessels were segmented on the scaled down image which may be easier)
- Specify "search radius" (line 44)

# Output
Finally we arrive at a spreadsheet with mets scored by volume of each lego channel, plust distance to nearest vessel 
 ### To do:
 - [x] Create some documentation
  -[ ] Create more documentation
  - [ ] Combine a few of the above steps
  - [ ] Get the local thickness of the nearest vessel
  - [ ] Get more accurate centroids, currently based on bounding boxes and assumes total box is "full"


## Cell Segmentation 
- Use bioformats to open the largest resolution image, but use “specify range for each series” and just open the channel you’re interested in.  
- Max project to get an overall idea of what you’re looking for.  
- Median filter – experiment with size of filter, between 2-4 will give good sensitivity but you’ll pick up a lot of stuff which may or may not be cells. Higher filter - lower sensitivity  
- Set a threshold that you think captures most of what you want and ignored what you don’t want.  
- Note the threshold values.  
- Go back to the 3d stack (before you max projected it) 
- Run the same median filter – 2d works faster, not sure if 3d is necessary but you can try it 
- **EITHER**: Set the threshold as decided above and apply – this might result in many single pixel or small objects  
- **OR**: Use the 3d-suite simple segmentation, set the threshold value and then set a minimum size of object to detect 
 

# Vessel Segmentation 
## Using FIJI 
- I’ve been playing and haven’t decided which option is best for resolution level – obviously the lowest level isn’t much use – you'll miss too much (probably?) Levels 2 and 3 look pretty promising, level 1 might work but it’s getting pretty large by this stage.  
- Subtract background, play with background radius, 50 for smaller resolution and 100 for level 2 looked good. Basically, trying to remove as much autofluorescence as possible 
- Set min/max brightness as something that looks okay and change to 8-bit 
- **FILTERING** before and/or after auto-threshold step
  - Make sure you have the morpholibJ plugins, help>update>enable update sites> IJPB-Plugins
  - I’m using combinations of morpholibJ opening/closing and media 3d 
- Adjust local threshold  
  - Method: Bernsen (has worked well in the past) 
  - Radius: play around, I’ve been again around the 50-100 mark but need to investigate further 
  - White objects on a black background 
  - Stack on 
- Further morphological/median filtering might clean up
- We may need to add a step to get rid of signal on periphery but that’s not a huge problem 
- When happy with binary – save it with a useful filename (samplenumber_seriesNumber_vesselBinary.tif or something) You can open in imaris or something to see how it looks in 3d.  
- Once we have binaries we can do distance and thickness transforms 
- Take binary airways image (save it) and do Analyze>Local Thickness (masked, calibrated, silent) and save the result of that too  

## Using Ilastik
TBC





 
