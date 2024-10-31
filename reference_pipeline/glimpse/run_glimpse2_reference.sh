#!/bin/bash

# Check if required parameters are provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <CHROM> <bcf_path> <genetic_maps_b37> <maf_thrd>"
    echo "Example: $0 chr22 /path/to/1KG /path/to/genetic_maps 0.005"
    exit 1
fi

# Parse command line arguments
CHROM="$1"
bcf_path="$2"
genetic_maps_b37="$3"
maf_thrd="$4"

# Validate CHROM format
if [[ ${CHROM:0:3} != "chr" ]]; then
    echo "Error: CHROM must start with 'chr'"
    echo "Usage: $0 <CHROM> <bcf_path> <genetic_maps_b37> <maf_thrd>"
    exit 1
fi

# Get script directory and set up paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLIMPSE2="${SCRIPT_DIR}/GLIMPSE2"
WORK_DIR="${SCRIPT_DIR}/glimpse_data"
bcftools="bcftools"

# Create work directory if it doesn't exist
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Check if required tools exist
if ! command -v $bcftools &> /dev/null; then
    echo "Error: bcftools not found"
    exit 1
fi

if [ ! -d "$GLIMPSE2" ]; then
    echo "Error: GLIMPSE2 directory not found at $GLIMPSE2"
    exit 1
fi

# Function to check if previous command succeeded
check_success() {
    if [ $? -ne 0 ]; then
        echo "Error: $1"
        exit 1
    fi
}

# Create directory for current chromosome if it doesn't exist
CHROM_DIR="${WORK_DIR}/${CHROM}"
mkdir -p "$CHROM_DIR"
cd "$CHROM_DIR"

# 1. Filter sites and get SNP list
echo "Starting to filter and get the list of SNPs for ${CHROM}"

# 1.1 MAF filtering
$bcftools view -q ${maf_thrd}:minor ${bcf_path}/1KG_phase3_v5_shapeit2_${CHROM}.bcf -Ob -o 1KG_phase3_v5_shapeit2_${CHROM}_filtered.bcf
check_success "MAF filtering failed"

# 1.2 Index BCF file
$bcftools index 1KG_phase3_v5_shapeit2_${CHROM}_filtered.bcf
check_success "BCF indexing failed"

# 1.3 Extract site information
$bcftools view -G -Oz -o 1KG_phase3_v5_shapeit2_${CHROM}_filtered.sites.vcf.gz 1KG_phase3_v5_shapeit2_${CHROM}_filtered.bcf
check_success "Site information extraction failed"

# 1.4 Index VCF file
$bcftools index -f 1KG_phase3_v5_shapeit2_${CHROM}_filtered.sites.vcf.gz
check_success "VCF indexing failed"

# 1.5 Print site count
echo "Number of sites:"
$bcftools view -G -H 1KG_phase3_v5_shapeit2_${CHROM}_filtered.sites.vcf.gz | wc -l
check_success "Site counting failed"

# 2. Chunk VCF using GLIMPSE2
echo "Starting to chunk VCF for ${CHROM}"
${GLIMPSE2}/GLIMPSE2_chunk_static \
    --input 1KG_phase3_v5_shapeit2_${CHROM}_filtered.sites.vcf.gz \
    --region ${CHROM} \
    --map ${genetic_maps_b37}/${CHROM}.b37.gmap.gz \
    --sequential \
    --output chunks.${CHROM}.txt
check_success "GLIMPSE2 chunking failed"

# 3. Generate GLIMPSE bin format files
echo "Starting to generate bin format files for ${CHROM}"
REF=1KG_phase3_v5_shapeit2_${CHROM}_filtered.bcf
MAP=${genetic_maps_b37}/${CHROM}.b37.gmap.gz

# Create directory for bin files
BIN_DIR="${CHROM_DIR}/mofang_panel_glimpse2/mofang_panel_glimpse2"
mkdir -p "$BIN_DIR"

while IFS="" read -r LINE || [ -n "$LINE" ]; do
    printf -v ID "%02d" $(echo $LINE | cut -d" " -f1)
    IRG=$(echo $LINE | cut -d" " -f3)
    ORG=$(echo $LINE | cut -d" " -f4)
    ${GLIMPSE2}/GLIMPSE2_split_reference_static \
        --reference ${REF} \
        --map ${MAP} \
        --input-region ${IRG} \
        --output-region ${ORG} \
        --output ${BIN_DIR}
    check_success "GLIMPSE2 bin format generation failed for chunk $ID"
done < chunks.${CHROM}.txt

echo "Processing completed successfully"
echo "Results are stored in: ${CHROM_DIR}"

# 要使用此脚本，确保：

# GLIMPSE2目录在脚本同级目录下
# 脚本有执行权限：chmod +x script.sh
# bcftools已经安装且在PATH中