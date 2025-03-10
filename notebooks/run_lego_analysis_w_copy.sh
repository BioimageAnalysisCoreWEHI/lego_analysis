#! /bin/bash

################################################################################
# Help                                                                         #
################################################################################
Help()
{
   # Display Help
   echo "Usage Instructions."
   echo
   echo "Syntax: $0 /path/to/lego_dataset /path/to/vast/scratch/space "
   echo
   echo "options:"
   echo "h     Print this Help."
   echo "d     Dry-run - Don't submit jobs, just print commands"
   echo
   echo "Files required in path:"
   echo "     Raw (stitched/fused) czi"
   echo "     Labelled met tif (from fiji)"
   echo "     Binary masks of C1,C2,C3 and Vessels (tif)"
   echo "     csv file containing bounding box "
   echo "     config.yml file containing filepaths (see github readme)"
   echo
}

################################################################################
################################################################################
# Main program                                                                 #
################################################################################
################################################################################
dry_run=0 #default
dir1=$1 #default
dir2=$2 #default
while getopts ":hd" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      d) # dry run
         dry_run=1
         dir1=$2
         dir2=$3
         ;;
     \?) # incorrect option
         echo "Error: Invalid option"
         exit;;
   esac
done

echo
echo "LET'S ANALYSE SOME "
echo
echo "⠀⠀⠀⢠⣶⠶⠶⣦⣀⣴⡶⠿⠿⠷⣦⣤⣶⠾⠿⠿⢶⣦⣀⣴⡶⠾⠷⢶⣦⡀
⠀⠀⣰⡿⠁⠀⢀⣿⡿⠁⠀⠀⠀⠀⡸⠋⠀⠀⡀⠀⠀⢹⡟⠁⠀⢀⠀⠀⠹⣷
⠀⢠⡿⠁⠀⠀⣼⡿⠁⠀⠠⠶⢿⣿⠁⠀⢀⣾⣇⣀⣠⡞⠀⠀⢰⣿⠀⠀⢰⣿
⢀⣿⠃⠀⠀⣼⣿⠃⠀⠀⠀⠀⣸⠃⠀⠀⡾⠁⠀⠈⣿⠁⠀⢠⣿⠇⠀⠀⣼⡇
⣸⡏⠀⠀⠰⠿⡟⠀⠀⠸⠿⠿⣿⠀⠀⢸⣿⠂⠀⢀⡏⠀⠀⣼⡟⠀⠀⣰⡿⠀
⣿⡇⠀⠀⠀⢀⣧⠀⠀⠀⠀⢀⣿⡀⠀⠀⠀⠀⣠⣾⣇⠀⠀⠀⠀⢀⣴⡿⠁⠀
⠘⠿⣶⣶⡶⠿⠻⠷⣶⣶⡶⠿⠛⠿⣶⣶⣶⠿⠛⠉⠻⠷⣶⣶⡶⠿⠋⠀⠀⠀
"

echo
echo

# Strip trailing / if it's there
[[ "${dir1}" != */ ]] && dir1="${dir1}/"
[[ "${dir1}" == */ ]] && dir1="${dir1: : -1}"

[[ "${dir2}" != */ ]] && dir2="${dir2}/"
[[ "${dir2}" == */ ]] && dir2="${dir2: : -1}"

# Loop through the directory looking for image files and the csv
# Submit necessary convrsions to SLURM
declare -a job_ids
for FILE in "$dir1"/*
do
  fname="${FILE##*/}"
  extension="${FILE##*.}"
  basefilename="${fname%.*}"

  if [ $extension = "tif" ]
  then
    input=$dir1"/"$fname
    output=$dir2"/."
    if [ $dry_run == 0 ]
    then
      copy_job=$(sbatch --parsable rsync_via_milton.sh $input $output)
      echo "Copying $fname jobId $copy_job"
    else
      copy_job="dry_run_copy"
      echo "sbatch --parsable rsync_via_milton.sh $input $output"
    fi

    #change source directory to dir2
    input=$dir2"/"$fname
    output=$dir2"/"$basefilename
    if [ $dry_run == 0 ]
    then
      this_job=$(sbatch --parsable --dependency=afterok:$copy_job tiff_to_zarr.sh $input $output)
      job_ids+=($this_job)
      echo "Job $this_job submitted to Milton - tiff2zarr"
    else
      echo "sbatch --parsable --dependency=afterok:$copy_job tiff_to_zarr.sh $input $output"
      job_ids+="job_id_tiff2zarr"
    fi
  fi

  if [ $extension = "czi" ]
  then
    input=$dir1"/"$fname
    output=$dir2"/."
    #echo "Copying $input to $dir2"/"$fname"
    if [ $dry_run == 0 ]
    then
      copy_job=$(sbatch --parsable rsync_via_milton.sh $input $output)
      echo "Copying $fname jobId $copy_job"
    else
      copy_job="dry_run_copy"
      echo "sbatch --parsable rsync_via_milton.sh $input $output"
    fi

    #change input to dir2
    input=$dir2"/"$fname
    output=$dir2"/"$basefilename
    if [ $dry_run == 0 ]
    then
      this_job=$(sbatch --parsable --dependency=afterok:$copy_job czi_to_zarr.sh $input $output)
      job_ids+=($this_job)
      echo "Job $this_job submitted to Milton - czi2zarr"
    else
      echo "sbatch --parsable czi_to_zarr.sh $input $output"
      job_ids+="job_id_czi2zarr"
    fi
  fi

  if [ $extension = "csv" ]
  then
     fpath=$dir1"/"$fname
     cp $fpath $dir2"/"$fname
     nMets=$(cat $fpath | wc -l)
  fi

  if [ $extension = "yml" ]
  then
     config_file=$dir1"/"$fname
     cp $config_file $dir2"/"$fname
     config_file=$dir2"/"$fname
  fi
done

#create dependency list
comma=","
job_list=""
for job_id in "${job_ids[@]}"
do
  job_list="$job_list$comma$job_id"
done
dependencies=${job_list:1:${#job_list}}

echo "nMets is $nMets"

echo "---"
echo "Once Zarr conversion is done - analysis will run:"
batchSize=$(($nMets / 100 ))
if [ $dry_run == 0 ]
then
   echo "-"
   penultimate_job=$(sbatch --parsable --dependency=afterok:$dependencies extract.sh $batchSize $config_file)
   echo "Analysis job $penultimate_job submitted"
else
  echo "---"
  cmd="sbatch --dependency=afterok:$dependencies extract.sh $batchSize $config_file"
  echo $cmd
fi

output_directory=$dir2"/output_mets/"

if [ -d $dir1"/output_mets" ]
then
  echo "output directory exists"
else
  mkdir $dir1"/output_mets"
fi

destination=$dir1"/output_mets/"
if [ $dry_run == 1 ]
then
  echo "sbatch rsync job to copy outputs"
  echo $output_directory
  echo $destination
  sbatch --nodes=1 --cpus-per-task=2 --time=3:30:00 --mem=8GB --wrap="rsync -r $output_directory $destination"
else
  echo "Copying data back to output_mets"
  sbatch --dependency=afterok:$penultimate_job --time=3:30:00 --nodes=1 --cpus-per-task=2 --mem=8GB --wrap="rsync -r $output_directory $destination"
fi


echo "

⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣶⣶⣿⣿⣿⣿⣿⣿⣶⣶⡄⠀⠀⠀⠀⠀⠀⠀_____________________⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀/|⠀⠀⠀Jobs submitted   |
⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀/⠀|⠀⠀⠀ to Milton HPC   |
⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀___/⠀⠀|____________________|⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠻⠿⠿⠿⠿⠿⠿⠟⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⣀⣀⢀⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⡀⣀⣀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⢀⣼⣿⡿⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⢿⣿⣧⡀⠀⠀⠀⠀
⠀⠀⠀⢀⣾⣿⣿⡇⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⢸⣿⣿⣷⡀⠀⠀⠀
⠀⠀⠀⣼⣿⣿⣿⢀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡀⣿⣿⣿⣧⠀⠀⠀
⠀⠀⣸⣿⣿⣿⡏⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⢹⣿⣿⣿⣇⠀⠀
⠀⠀⣿⣿⣿⣿⠇⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠸⣿⣿⣿⣿⠀⠀
⠀⠀⣿⣿⣿⡿⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡆⢿⣿⣿⣿⠀⠀
⠀⣠⣿⣿⣿⡇⠸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠇⢸⣿⣿⣿⣄⠀
⣾⡿⠋⠉⢻⣷⡀⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⢀⣾⡟⠉⠙⢿⣷
⢿⡇⠀⠀⢸⣿⠁⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠈⣿⡇⠀⠀⢸⡿
⠀⠀⠀⠀⠛⠁⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠈⠛⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⡇⢸⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⡇⢸⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⡇⢸⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣤⣤⣤⣤⣤⣤⣤⡄⢠⣤⣤⣤⣤⣤⣤⣤⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⡇⢸⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀

⠀⠀"

