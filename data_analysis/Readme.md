Directory structure


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

001 and 2 deal with  extracting and combinig data into one spreadsheet..

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