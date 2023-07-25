set -e

dir=/home/jason/gluo_remote/reproduce/image-priors/results/mag
pattern=("po" "1d" "2d")
#pattern=("2d")

mkdir -p subfigs
cd subfigs

crop_and_cnvrt()
{
    tmpfile1=$(mktemp /tmp/abc-script.XXXXXX)
    tmpfile2=$(mktemp /tmp/abc-script.XXXXXX)
    bart extract 0 20 255 1 25 226 $2 $tmpfile1
    bart extract 0 80 140 1 58 175 $2 $tmpfile2
    cfl2png -c $1 $tmpfile1 $3
    cfl2png -c $1 $tmpfile2 $3_crop
}

crop_and_cnvrt2()
{
    tmpfile1=$(mktemp /tmp/abc-script.XXXXXX)
    tmpfile2=$(mktemp /tmp/abc-script.XXXXXX)
    bart extract 0 20 255 1 25 226 $2 $tmpfile1
    bart extract 0 80 140 1 58 175 $2 $tmpfile2
    bart scale 0.0000015 $tmpfile1 $tmpfile1
    bart scale 0.0000015 $tmpfile2 $tmpfile2
    cfl2png -c $1 -A $tmpfile1 $3
    cfl2png -c $1 -A $tmpfile2 $3_crop
}

declare -a priors=("mag_small" "mag_large"    "cplx_small" "cplx_large" )

if [ 1 == 1 ]; then
for p in "${pattern[@]}"; do
    
for prior in "${priors[@]}";do
    crop_and_cnvrt ../config $dir/$p/pics_$prior pics_${prior}_$p
    crop_and_cnvrt ../config $dir/$p/nlinv_$prior nlinv_${prior}_$p
    crop_and_cnvrt ../phase_config $dir/$p/pics_$prior pics_${prior}_phase_$p
    crop_and_cnvrt ../phase_config $dir/$p/nlinv_$prior nlinv_${prior}_phase_$p
done

crop_and_cnvrt ../config $dir/$p/grd grd
crop_and_cnvrt ../config $dir/$p/nlinv_grd nlinv_grd

crop_and_cnvrt ../config $dir/$p/l1_nlinv l1_nlinv_$p
crop_and_cnvrt ../config $dir/$p/l1_pics l1_pics_$p
crop_and_cnvrt ../config $dir/$p/l2_pics l2_pics_$p
crop_and_cnvrt2 ../config $dir/$p/zero_filled zero_filled_$p
crop_and_cnvrt ../config $dir/$p/zero_filled_nlinv zero_filled_nlinv_$p
crop_and_cnvrt ../config $dir/$p/mask mask_$p

crop_and_cnvrt ../phase_config $dir/$p/l1_nlinv l1_nlinv_phase_$p
crop_and_cnvrt ../phase_config $dir/$p/l1_pics l1_pics_phase_$p
crop_and_cnvrt ../phase_config $dir/$p/zero_filled zero_filled_phase_$p
crop_and_cnvrt ../phase_config $dir/$p/zero_filled_nlinv zero_filled_nlinv_phase_$p

crop_and_cnvrt ../phase_config $dir/$p/grd grd_phase
crop_and_cnvrt ../phase_config $dir/$p/nlinv_grd nlinv_grd_phase
crop_and_cnvrt ../phase_config $dir/$p/l2_pics l2_pics_phase_$p
done
fi

for p in "${pattern[@]}"; do

cd $dir/$p/
echo "========$p==========="

echo "----PICS PSNR----"
bart cabs grd tmp

bart cabs l2_pics tmp1
echo l2 $(bart measure --psnr tmp tmp1)

bart cabs l1_pics tmp1
echo l1 $(bart measure --psnr tmp tmp1)

for prior in "${priors[@]}"; do
bart cabs pics_$prior tmp1
echo $prior $(bart measure --psnr tmp tmp1)
done

echo "----PICS SSIM----"
bart cabs l2_pics tmp1
echo l2 $(bart measure --ssim tmp tmp1)

bart cabs l1_pics tmp1
echo l1 $(bart measure --ssim tmp tmp1)

for prior in "${priors[@]}"; do
bart cabs pics_$prior tmp1
echo $prior $(bart measure --ssim tmp tmp1)
done


echo "----NLINV PSNR----"
bart cabs nlinv_grd tmp

bart cabs zero_filled_nlinv tmp1
echo l2 $(bart measure --psnr tmp tmp1)

bart cabs l1_nlinv tmp1
echo l1 $(bart measure --psnr tmp tmp1)

for prior in "${priors[@]}"; do
bart cabs nlinv_$prior tmp1
echo $prior $(bart measure --psnr tmp tmp1)
done

echo "----NLINV SSIM----"

bart cabs zero_filled_nlinv tmp1
echo l2 $(bart measure --ssim tmp tmp1)

bart cabs l1_nlinv tmp1
echo l1 $(bart measure --ssim tmp tmp1)

for prior in "${priors[@]}"; do
bart cabs nlinv_$prior tmp1
echo $prior $(bart measure --ssim tmp tmp1)
done

done