#!/bin/bash
echo "Setting up analysis environment"

conda install  -n base -c conda-forge mamba --yes

mamba env create -f environment.yml

source ~/anaconda3/etc/profile.d/conda.sh
conda activate genepi-box

cd ..
cp scripts/php.ini ~/anaconda3/envs/genepi-box/lib

echo "Enviroment set up complete"
