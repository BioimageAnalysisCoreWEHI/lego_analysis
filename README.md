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
Finally we arrive at a spreadsheet with mets scored by volume of each lego channel, plus distance to nearest vessel 
