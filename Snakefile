## Snakefile for processing Hi-C data

## conda activate snakemake_env

configfile: "config/config.yml"

import re
import glob
import os

# Auto-detect samples from raw data directory
raw_fastq_files = glob.glob("data/raw/*.fastq*")
print("Raw fastq files:", raw_fastq_files)
	# Raw fastq files: ['data/raw/rhesus_HiC_test_R1.fastq.gz', 'data/raw/rhesus_HiC_test_R2.fastq.gz']

reads = [re.sub(r"\.fastq(\.gz)?$", "", os.path.basename(f)) for f in raw_fastq_files]
print("Detected reads:", reads)
	# Detected reads: ['rhesus_HiC_test_R1', 'rhesus_HiC_test_R2']

samples = list(set(re.sub(r"_[Rr][12].*", "", os.path.basename(f)) for f in raw_fastq_files))
print("Detected samples:", samples)
	# Detected samples: ['rhesus_HiC_test']

#####################################
#### RULES
#####################################

rule all:
    input:
        expand("results/fastqc/{read}.html", read=reads),
        "results/fastqc/multiqc_report.html",
        expand("results/hicup/{sample}/{sample}_R1_2.hicup.bam", sample=samples),
        expand("results/pairix/{sample}.bsorted.pairs.gz", sample=samples),
        expand("results/cool/{sample}.cool", sample=samples),
        expand("results/cool/{sample}.mcool", sample=samples),
        expand("results/TADs/{sample}_min10_max60_fdr01_d01_boundaries.bed", sample=samples),
        expand("results/hic-files/{sample}.hic", sample=samples),


# run fastqc on R1 and R2 for all samples
rule fastqc:
    input:
        "data/raw/{read}.fastq.gz"
    output:
        html="results/fastqc/{read}.html",
        zip="results/fastqc/{read}_fastqc.zip"
    log:
        "results/logs/fastqc_{read}.log"
    params:
        "--threads 4"
    wrapper:
        "v1.5.0/bio/fastqc"
        
rule multiqc_raw:
    input:
       expand("results/fastqc/{read}_fastqc.zip", read=reads),
       directory("results/fastqc/multiqc_data"),
    output:
        "results/fastqc/multiqc_report.html"
    log:
        "results/logs/multiqc_raw.log"
    wrapper:
        "v5.8.3/bio/multiqc"

# run hicup mapping (very time intensive step)
rule hicup:
    input:
       "data/raw/{sample}_R1.fastq.gz",
       "data/raw/{sample}_R2.fastq.gz"
    output:
       bam="results/hicup/{sample}/{sample}_R1_2.hicup.bam"
    params:
        index = config["GENOME"],
        digest = config["DIGEST"],
        outdir = "results/hicup/{sample}"
    threads: 16 
    conda:
        "envs/hic.yml"
    log:
        "results/logs/hicup_{sample}.log"
    shell:
        "hicup --bowtie2 $(which bowtie2) "
        "--digest {params.digest} "
        "--format Sanger "
        "--index {params.index} "
        "--longest 800 "
        "--zip "
        "--outdir {params.outdir} "
        "--shortest 50 "
        "--threads {threads} "
        "{input} >{log} 2>&1"
        
# hicup --bowtie2 $(which bowtie2) --digest /home/groups/hoolock2/u0/genomes/ucsc/rheMac10/hicup-digest/Digest_rheMac10_DpnII_Arima_None_08-47-56_19-01-2020.txt --format Sanger --index /home/groups/hoolock2/u0/genomes/ucsc/rheMac10/indexes/bowtie2/rheMac10 --longest 800 --zip --outdir results/hicup/test --shortest 50 --threads 16 data/raw/rhesus_HiC_test_R1.fastq.gz data/raw/rhesus_HiC_test_R2.fastq.gz

rule bam2pairs:
    input:
        "results/hicup/{sample}/{sample}_R1_2.hicup.bam"
    output:
        "results/pairix/{sample}.bsorted.pairs.gz"
    conda:
        "envs/hic.yml"
    log:
        "results/logs/bam2pairs.{sample}.log"
    shell:
    # -c -p to uniqify @SQ and @PG
        "bam2pairs -c {config[CHRSIZES]} {input} results/pairix/{wildcards.sample} >{log} 2>&1"

# make coolers (time intensive)
rule cooler_cload:
    input:
        "results/pairix/{sample}.bsorted.pairs.gz"
    output:
        "results/cool/{sample}.cool"
    conda:
        "envs/hic.yml"
    log:
        "results/logs/cooler_cload.{sample}.log"  # Remove expand and use the same wildcard
    threads: 16
    shell:
        "cooler cload pairix -p {threads} --assembly {config[ASMBLY]} {config[CHRSIZES]}:10000 {input} {output} >{log} 2>&1"
   

# create multiple resolution coolers for visualization in higlass
rule zoomify:
    input:
        "results/cool/{sample}.cool"
    output:
        "results/cool/{sample}.mcool"
    log:
        "results/logs/zoomify.{sample}.log"
    conda:
        "envs/hic.yml"
    threads: 16 
    shell:
        "cooler zoomify -p {threads} --balance -o {output} {input} >{log} 2>&1"

# find TADs using hicFindTADs from hicExplorer at 10kb resolution
rule hicFindTADs:
    input:
        "results/cool/{sample}.mcool"
    output:
        "results/TADs/{sample}_min10_max60_fdr01_d01_boundaries.bed"
    conda:
        "envs/hicexplorer.yml"
    log:
        "results/logs/hicFindTADs_narrow.{sample}.log"
    threads: 16
    shell:
        "hicFindTADs -m {input}::resolutions/10000 --minDepth 100000 --maxDepth 600000 --outPrefix results/TADs/{wildcards.sample}_min10_max60_fdr01_d01 --correctForMultipleTesting fdr -p {threads} >{log} 2>&1"
        
# convert from .pairs to .hic files for viewing using juicer
rule pairs2hic:
    input:
        "results/pairix/{sample}.bsorted.pairs.gz"
    output:
        "results/hic-files/{sample}.hic"
    params:
        chrsize = config["CHRSIZES"],
    conda:
        "envs/hic.yml"
    log:
        "results/logs/pairs2hic.{sample}.log"
    threads: 16
    shell:        
        "java -Xmx64G -jar scripts/juicer_tools_1.22.01.jar pre --threads {threads} {input} {output} {params.chrsize} >{log} 2>&1"



