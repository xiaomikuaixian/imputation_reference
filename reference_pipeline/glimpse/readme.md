# GLIMPSE2 参考基因组数据处理流程-0.5%位点集合
#### 目的：
	减小插补位点集合，为23mofang 标准版panel使用，插补v22芯片中的民族成分和基因关系位点。panel数据位点深度很高。
#### 参考链接：
	[[https://odelaneau.github.io/GLIMPSE]]
	reference_pipeline/glimpse/run_glimpse2_reference.sh
	运行 bash run_glimpse2_reference.sh chr22 /path/1KG /path/genetic_maps 0.005
#### 软件路径：
	reference_pipeline/glimpse/GLIMPSE2

# 核心步骤讲解

## 输入文件
- 原始文件：
  - `1KG_phase3_v5_shapeit2_${CHROM}.bcf`
  - `1KG_phase3_v5_shapeit2_${CHROM}.csi`
  - 1KG_phase3_v5 来源
- 已经做过的处理步骤
  - 添加AC字段到info列
  - bcftools norm -m -any：将多等位基因位点分解成多个双等位基因记录
  - 染色体加chr前缀
  - bcftools view -v snps,indels：保留indel和snp类型的位点

## 常见过滤操作
- RAF/MAF过滤/Alt个数过滤
- 多等位基因位点过滤-选择策略
- 指定alt类型位点过滤
- 指定位点集合/区间过滤
- indel 的长度过滤
- 选择snp位点 -v snps

## 1. GLIMPSE位点提取

### 命令
```bash
# 脚本传入的参数为染色体编号
CHROM="chr22"
GLIMPSE2="reference_pipeline/glimpse/GLIMPSE2"

# MAF过滤（MAF>=0.5%）
# 输出1KG_phase3_v5_shapeit2_${CHROM}_filtered.bcf
bcftools view -q 0.005:minor 1KG_phase3_v5_shapeit2_{CHROM}.bcf -Ob -o 1KG_phase3_v5_shapeit2_${CHROM}_filtered.bcf
bcftools index 1KG_phase3_v5_shapeit2_${CHROM}_filtered.bcf

# 提取位点信息(不含基因型,view -G ),生成vcf.gz(-Oz)
bcftools view -G -Oz -o 1KG_phase3_v5_${CHROM}_filtered.sites.vcf.gz 1KG_phase3_v5_shapeit2_${CHROM}_filtered.bcf

# 为vcf.gz建立索引(index)
bcftools index -f 1KG_phase3_v5_${CHROM}_filtered.sites.vcf.gz

# 使用GLIMPSE2进对vcf.gz进行分块
{GLIMPSE2}/GLIMPSE2_chunk_static \
  --input 1KG_phase3_v5_${CHROM}_filtered.sites.vcf.gz \
  --region ${CHROM} \
  --map genetic_maps_b37/${CHROM}.b37.gmap.gz \
  --sequential \
  --output chunks.${CHROM}.txt
```

### 输出文件
- 输出:
  - `1KG_phase3_v5_chr22.sites.vcf.gz`，只包含位点信息
  - `chunks.chr22.txt` ，分块文件

## 2. 获得GLIMPSE的bin格式
将第一步得到的bcf文件，依据`chunks.chr{1-22}.txt`文件转换为GLIMPSE2专用的bin格式

```bash
CHROM="chr22"
if [[ ${CHROM:0:3} != "chr" ]]; then
    echo "usage: ./split_panel.sh chrN"
    exit
fi
echo "start split panel for ${CHROM}"
REF=1KG_phase3_v5_shapeit2_${CHROM}_filtered.bcf
MAP=${CHROM}.b37.gmap.gz
while IFS="" read -r LINE || [ -n "$LINE" ];
do
  printf -v ID "%02d" $(echo $LINE | cut -d" " -f1)
  IRG=$(echo $LINE | cut -d" " -f3)
  ORG=$(echo $LINE | cut -d" " -f4)
  ${GLIMPSE2}/GLIMPSE2_split_reference_static --reference ${REF} --map ${MAP} --input-region ${IRG} --output-region ${ORG} --output panel
done < chunks.${CHROM}.txt
```

### 输出文件
- 输出：
  - `wgs_chr22_91182114_94924793.bin`
  - `wgs_chr22_93102579_98544975.bin`
  - ...

## 3. GLIMPSE参考集合说明

### 基本信息
- 种群：未过滤,包含全部人种
- 样本数：2504个
- 总位点数：47,069,698个

### 位点信息提取
```bash
for i in {1..22}; do
  CHROM="chr$i"
  echo "process $CHROM"
  bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\n' 1KG_phase3_v5_${CHROM}.sites.vcf.gz > ./${CHROM}_snp_info.txt
done
```

### 等位基因频率计算
```bash
for i in {1..22}; do
  CHROM="chr$i"
  echo "process $CHROM"
  vcftools --bcf 1KG_phase3_v5_shapeit2_${CHROM}.bcf --freq --out ${CHROM}_analysis_freq
done
```

## 4. bcftoosl常用命令

## 5. glimpse官方文档和相关文献

## TODO
 - 最后的bin文件未保存到指定的路径下
 - 目前多等位基因型拆分后，可能存在重复行
 - 支持按位点清单：chrom+pos + ref + alt进行过滤