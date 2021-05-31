exprs=(1d_random 1d_equal 2d_random 2d_equal poisson)

shift=60
width=50
width2=160
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