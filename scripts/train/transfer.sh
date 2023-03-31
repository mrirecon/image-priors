#cat /scratch/gluo/umg/cfl | xargs -i scp {} transfer-g:/scratch/users/luo9/abide

path=/home/ague/data/gluo/dataset/abide_2/train
pattern1="abide_*.cfl"
pattern2="abide_*.hdr"
find $path -name $pattern1 | sort > cfl_list
find $path -name $pattern2 | sort > hdr_list

destination=transfer-g:/scratch/users/luo9/abide

rsync -av --progress --files-from=$cfl_list / $destination &
rsync -av --progress --files-from=$hdr_list / $destination

