set -e 

config=/home/gluo/workspace/nlinv_prior/figures/phase_augmentation/config
dir=/home/ague/data/gluo/dataset/abide_2/train
good=abide_1000635
bad=abide_1004807
okay=abide_1002539

mkdir -p sub_figs
cd sub_figs

bart avg 1 ${dir}/${good} tmp
cfl2png -c $config tmp good
cfl2png -c ../phase_config tmp good_phase

bart avg 1 ${dir}/${good}_mag_reserved tmp
cfl2png -c $config tmp good_

bart avg 1 ${dir}/${bad} tmp
cfl2png -c $config tmp bad
cfl2png -c ../phase_config tmp bad_phase

bart avg 1 ${dir}/${bad}_mag_reserved tmp
cfl2png -c $config tmp bad_

bart avg 1 ${dir}/${okay} tmp
cfl2png -c $config tmp okay
cfl2png -c ../phase_config tmp okay_phase

bart avg 1 ${dir}/${okay}_mag_reserved tmp
cfl2png -c $config tmp okay_
