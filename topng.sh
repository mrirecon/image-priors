export TF_CPP_MIN_LOG_LEVEL=3
exprs=(1d_random 1d_equal 2d_random 2d_equal poisson)

shift=60
width=50
width2=160

# convert cfl to png for fig1
if [ "0" == "1" ]; then
    for expr in ${exprs[@]}
    do
        bart transpose 0 1 $expr/mask $expr/mask_t
        cfl2png -IN $expr/mask_t $expr/mask

        bart transpose 0 1 $expr/zero_filled $expr/zero_filled_t
        cfl2png -IN $expr/zero_filled_t $expr/zero_filled
        bart pad -a 1 $shift $expr/zero_filled_t $expr/tmp
        bart resize -c 0 $width2 1 $width $expr/tmp $expr/zero_filled_crop
        cfl2png -IN $expr/zero_filled_crop $expr/zero_filled_crop

        bart transpose 0 1 $expr/l1_recon $expr/l1_recon_t
        cfl2png -IN $expr/l1_recon_t $expr/l1_recon
        bart pad -a 1 $shift $expr/l1_recon_t $expr/tmp
        bart resize -c 0 $width2 1 $width $expr/tmp $expr/l1_recon_crop
        cfl2png -IN $expr/l1_recon_crop $expr/l1_recon_crop

        bart transpose 0 1 $expr/prior_recon $expr/prior_recon_t
        cfl2png -IN $expr/prior_recon_t $expr/prior_recon
        bart pad -a 1 $shift $expr/prior_recon_t $expr/tmp
        bart resize -c 0 $width2 1 $width $expr/tmp $expr/prior_recon_crop
        cfl2png -IN $expr/prior_recon_crop $expr/prior_recon_crop

        bart transpose 0 1 $expr/rss $expr/rss_t
        cfl2png -IN $expr/rss_t $expr/rss
        bart pad -a 1 $shift $expr/rss_t $expr/tmp
        bart resize -c 0 $width2 1 $width $expr/tmp $expr/rss_crop
        cfl2png -IN $expr/rss_crop $expr/rss_crop

    done
fi

# convert cfl to png for fig2
chn=1
for expr in ${exprs[@]}
do
    bart slice 3 $chn $expr/proj $expr/tmp
    bart transpose 0 1 $expr/tmp $expr/coil
    cfl2png -IN $expr/coil $expr/chn
    
    bart transpose 0 1 $expr/l1_recon_projection_residual_rss $expr/tmp
    cfl2png -IN $expr/tmp  $expr/espirit_projection_residual_rss

    bart transpose 0 1 $expr/prior_recon_projection_residual_rss $expr/tmp
    cfl2png -IN $expr/tmp  $expr/
    
    bart slice 3 $chn $expr/coilsen $expr/tmp
    bart transpose 0 1 $expr/tmp $expr/sensitivity
    cfl2png -IN -CP $expr/sensitivity $expr/sensitivity

    bart slice 3 $chn $expr/prior_recon_coils $expr/tmp
    bart transpose 0 1 $expr/tmp $expr/sensitivity_nlinv
    cfl2png -IN -CP $expr/sensitivity_nlinv $expr/sensitivity_nlinv
    
done

# convert clf to png for fig3
for expr in ${exprs[@]}
do
    echo $expr
    bart transpose 0 1 $expr/prior_recon $expr/prior_recon_t
    bart transpose 0 1 $expr/prior_recon_coils $expr/prior_recon_coils_t
    bart transpose 0 1 $expr/prior_recon_coils_normalized $expr/prior_recon_coils_normalized_t

    bart fmac $expr/prior_recon_t $expr/prior_recon_coils_normalized_t $expr/prior_recon_coilimg

    cfl2png -IN -CP $expr/prior_recon_coils_normalized_t $expr/prior_recon_coils
    cfl2png -IN $expr/prior_recon_coilimg $expr/prior_recon_coilimg
done
