# Lego Pipeline

## Initial Data Handling
- If necessary - stitch/fuse in Zen
  - Alternatively select just one side-view 
- Open full resolution channels individually and save as TIFs
  - can optionally be converted to 8-bit to save computational resources
- Segment each channel individually (see segmentation instructions below)
- Segment vessel image manually if possible, alternatively attempt via ilastik

If you're using ilastik on a slice by slice basis you can use ```00 - batch_ilastik.ijm``` to run it through all the slices relatively easily. 

## Image Analysis
Pipeline found in the ```image_analysis``` subfolder. This is designed to run  on a distributed HPC using the slurm scheduler. There may be configurations specific to our HPC, but in theory it can be adapted relatively easily. Only requirements are slurm and adequate python conda environments. 

# Output
Finally we arrive at a spreadsheet with mets scored by volume of each lego channel, plus distance to nearest vessel, its thickness, and other recorded metrics.git  

# Data Analysis
All the data analysis from the extracted image data is in the folder `data_analysis`
