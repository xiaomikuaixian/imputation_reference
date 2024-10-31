# #!/bin/bash

bcf_path='/home/mihao/mofang/snp_impute/data/reference/Phasing'
map_path='/home/mihao/mofang/snp_impute/data/maps'
maf_thrd=0.005
for chr in {1..22}; do
    echo "Processing chromosome $chr..."
    ./run_glimpse2_reference.sh chr$chr $bcf_path $map_path $maf_thrd > log_$chr.txt 2>&1
done