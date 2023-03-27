#!/bin/sh

npz_path=/home/ague/data/gluo/dataset/abide_2/magnitude
npz_pattern="abide_*.npz"
if ! $(test -s all_magnitude) ; then
echo "listing all magnitude images..."
find $npz_path -name $npz_pattern | sort > all_magnitude
fi

cfl_path=/home/ague/data/gluo/dataset/abide_2/train
cfl_pattern="abide_*.cfl"
if ! $(test -s finished) ; then
echo "listing all generated complex images..."
find $cfl_path -name $cfl_pattern | grep -v "mag_re" | sort | \
    sed "s/cfl/npz/g" | sed "s/train/magnitude/g" > finished
fi

diff --text --unified --new-file finished all_magnitude | grep '+/home/' | \
 sed "s/+//g"> missing

nr_missing=$(cat missing | wc -l)
echo "so far, $nr_missing files are not augmented with phase and listed in the file named missing"
rm finished