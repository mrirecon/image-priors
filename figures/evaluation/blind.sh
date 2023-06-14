src=/scratch/gluo/umg_tfl3d/8x
dst=/scratch_radon/gluo/umg_tfl3d

readarray -t shuffle < shuffle_list

for item in "${shuffle[@]}"; do

IFS=$'\t' read -ra array <<< "${item}"

hum=${array[0]}
reco1=${array[1]}
reco2=${array[2]}
reco3=${array[3]}
reco4=${array[4]}

mkdir -p $dst/$hum
cp $src/$hum/$reco1.nii $dst/$hum/1.nii
cp $src/$hum/$reco2.nii $dst/$hum/2.nii
cp $src/$hum/$reco3.nii $dst/$hum/3.nii
cp $src/$hum/$reco4.nii $dst/$hum/4.nii

done