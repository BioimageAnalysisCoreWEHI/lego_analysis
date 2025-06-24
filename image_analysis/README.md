# Lego Pipeline - HPC

## What to do
### 0) Setup jupyter environment
This only needs to be done once
You will need a bit of space in your home area  ~400mb
1. Login to slurm-node via rap
2. Clone this repo 
``` git clone https://github.com/DrLachie/SabrinaLego ```
or ``` copy files from Lachie ```
  
3. >module load anaconda3
   > 
   >conda init
4. > conda create -n on_demand_lego python=3.9
   > 
    > conda activate on_demand_lego
   > 
   > pip install PyYAML
   > 
   > conda install ipykernel
   > 
    > python -m ipykernel install --user --name lego_on_demand --display-name "Python (lego)" 

You should now be able to activate this kernel in Jupyter on-demand! 

# Lightsheet Analysis
Most of the processing is performed in ```extract_and_measure_mets.py```. The following dependencies need to be in your python environment: 
- dask
- tifffile
- scikit-image
- yaml
- numpy

Everything else should be in there by default.

# Running the pipeline:

### 1a) 
You can manually create the csv bounding box csv, labelled image, and local thickness image by combining the three binaries (Image calculator C1 max C2, and result_of_that max C3), then use morpholibJ for connected components labelling. Then analyse regions 3d checking just volume and bounding box.  

However, it's much easier to use the convenient fiji macro ```get_lbl_and_locThk.ijm```. Just change the filepaths that are hardcoded in there. It performs the method above in a more automated fashion. 

### 1b) The following files need to be in a single directory 
- Raw (stithced/fused) czi
- FIJI Labelled Met Image (tif)
- Binary masks of C1,C2,C3 and Vessels (tif)
- csv file containing bounding box 
- config.yml file (this will be created by the notebook)

Note, for the label image and csv file, 

### 2) Edit config.yml and submit job
 - Open an on demand Jupyter notebook server
 - Open the "Lets_Go_LEGO" notebook
 - Change the filepaths 
 - Run the cells
 - The final cell submits the job to HPC

### You might want to think about editing the .sh files to include your email address. 

---

#Jupyter Notebook - useful comands
- ctrl+enter -> run selected cell
- shift+enter -> run selected cell and advance to next cell
- arrow keys -> navigate
- enter -> edit cell


## What is going on here? 

Broadly, the ```run_lego_analysis.sh``` script goes through the required files, converts the czi to zarr 
using ```czi_to_zarr.sh``` (which in turn submits ```csi2zarr.py``` to HPC), converts tiff 
to zarr (similarly uses ```tiff_to_zarr.sh``` to submit ```tiff2zarr.py``` to HPC). 

It also grabs the number of detected objects from the csv file to determine the parallelisation of the analysis. 
The final analysis script ```extract.sh``` will submit ```extract_and_measure.py``` to the SLURM queue, 
but will not execute until the above jobs are completed and will run 10 jobs of nMets/10 each. It also gets 
the config.yml file from the original input directory, so make sure you're editing that one. 

Output location will be determined by the definition in ```config.yml```

# Post analysis correction
### 03-Manual_Correction_Milton.ijm
- Has proper menu
- Specify directory with mets from above
- Specify which met ID to start from

### Super intuitive flow diagram 
![Super intuitive flow diagram](../img/LeGO%20Flow.png)

# Data collation and filtering
Despite the name, run ```04-preCorrection.ipynb``` *after* doing the correction. It will create resuts tables and recalculate all of the met / clone volumes.
You can then also run ```04b - FILTERING_RESULTS.ipynb``` to remove "bad" detections or any other noted deletions. 

### Optionally
You can run 



 
