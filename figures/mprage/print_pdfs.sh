#!/bin/bash

set -e
nail_tex()
{
    cd $1
    pdflatex $1.tex
    pdfcrop $1.pdf ../$1.pdf
    cd ..
}

# use shell script print_subfigs.sh to convert cfls to figures
bash print_subfigs.sh

nail_tex mprage_full
nail_tex boxplot
nail_tex dataset
nail_tex filter