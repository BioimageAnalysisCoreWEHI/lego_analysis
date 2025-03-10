#! /bin/bash
#SBATCH --job-name=copy_img #Name to give the job
#SBATCH --time=3:30:00 #Time to allow job to run for
#SBATCH --ntasks=1
#SBATCH --output=/vast/scratch/users/microscopy/outputs/copy_from_vast_imaging-%A_%a.out #Where to put output logs

#SBATCH --cpus-per-task=1 #Only use more than one if code is already multithreaded
#SBATCH --mem 12G #obvious
#SBATCH --mail-type=END #email when all jobs done
#SBATCH --mail-user=user@wehi.edu.au #email who?

echo "fpath = $1"
echo "out_path = $2"

#The next line is essential for conda to work in your script
#source /stornext/System/data/apps/anaconda3/anaconda3-2019.03/etc/profile.d/conda.sh
#conda activate bac 

#run the analysis
rsync -ah "$1" "$2"

 
