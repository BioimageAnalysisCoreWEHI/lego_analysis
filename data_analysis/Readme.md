**Installation**


To ensure compatibility, install the following Python package versions:

```bash
pip install pandas==2.2.1 seaborn==0.13.2 numpy==1.23.4 matplotlib==3.8.4 holoviews==1.20.2
```

**Directory Structure**

```md
    ├───figures
    ├───final_graphs
    │   ├───fig3
    │   ├───fig5
    │   └───supplementary
    ├───merged
    └───raw_data
        ├───IV
        │   ├───1064
        │   ├───1066
        │   ├───883
        │   ├───934
        │   └───935
        └───MFI
            ├───1067
            ├───1069
            ├───1070
            └───1381
```
Raw Data extracted from images in "./raw_data"
- IV: Intravenous & MFI: Mammary Fatpad injection
    - Each folder is id of the animal
    - Each folder contains
        - an `xlsx` file with MET data (Definitely the Final version :) )
        - tmp_metBbox.csv which is the bounding box details for each MET
        - VesselSurfaceAreaMeasurements.txt: Data on METs that touch vessels and intersection surface area 

001_merge_clean.ipynb
- Merge all the datasets in subfolders `./raw_data/IV` and `./raw_data/MFP` and create `_merged.csv` files in ./raw_data for each animal. Datsets will have suffix `_merged.csv`

002_merge_all_tables.ipynb
- Merge datasets from above and add metadata 
- This will generate the final dataset for analysis `./MFP_IV_combined_raw_data.csv`in the root directory

003_metastatic_burden.ipynb

- Fig 3s,t,v,u
- Supp fig 2a

004_blood_vessel_met_minimum_distance.ipynb
- supp 6 a, b, c, 
- Fig 5d

005_MET_stacked_comparison.ipynb

- Supp 5 a-h
- Fig 3n

006_MET_Volume_thresholds.ipynb
- Fig 3o,p,q,r

007_vessel_surface_area_thickness.ipynb
- Fig 5 efg
- Fig 5h

008_chord_diagrams
- Supp fig 4 (all)
- Fig 4

009_shannon_diversity
- supp fig 3