#! /bin/bash
#SBATCH --job-name=lego_analysis #Name to give the job
#SBATCH --time=6:30:00 #Time to allow job to run for
#SBATCH --ntasks=1
#SBATCH --output=/vast/scratch/users/microscopy/outputs/lego-%A_%a.out #Where to put output logs
#SBATCH --cpus-per-task=12 #Only use more than one if code is already multithreaded
#SBATCH --mem 512G #obvious
#SBATCH --array=0-99
#SBATCH --mail-type=END #email when all jobs done
#SBATCH --mail-user=user@wehi.edu.au #email who?

#The next line is essential for conda to work in your script
source /stornext/System/data/apps/anaconda3/anaconda3-2019.03/etc/profile.d/conda.sh
conda activate /stornext/Img/data/prkfs1/m/Microscopy/BAC_Conda_envs/lego/

batch_size=$1
config_file=$2

#run the analysis
python extract_and_measure_mets.py --config $config_file --met_range $(($SLURM_ARRAY_TASK_ID*$batch_size)) $((($SLURM_ARRAY_TASK_ID*$batch_size)+$batch_size))

