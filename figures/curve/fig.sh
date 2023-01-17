set -e

dir=/home/gluo/workspace/nlinv_prior/results/po

mkdir -p sub_figs
cd sub_figs

cfl2png -c ../config $dir/prior_abide_filtered_pics pics
cfl2png -c ../config $dir/prior_abide_filtered_nlinv nlinv
cfl2png -c ../config $dir/grd grd
cfl2png -c ../config $dir/zero_filled zero_filled

cfl2png -c ../phase_config $dir/coilsen e_coil
cfl2png -c ../phase_config $dir/prior_abide_filtered_nlinv_coils n_coil