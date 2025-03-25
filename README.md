# Hi-C Workflow

Snakemake workflow for QC and processing of HiC data. Results in .cool, .mcool, .hic files and TAD calls for the data. All commands used to QC, and process hic-data are contained in the main Snakefile. This Snakemake workflow was streamlined and expanded by Jimi Rosenkrantz in 2025, following workflow established by Jake in Carbone lab in 2023.

---

## Requirements

This workflow requires:
   - **Conda** (for environment management)
   - **Snakemake** and **git** (for workflow download and automation)

---

## Installation & Setup

If you haven’t installed Conda and Snakemake, follow these steps:

1. **Install Conda**  
   Follow the instructions at [Miniconda installation](https://docs.conda.io/en/latest/miniconda.html).

2. **Install Snakemake and git**:
   ```bash
   mamba create -n snakemake_env -c conda-forge -c bioconda -c defaults snakemake git
   ```
   
3. **Activate the Snakemake environment**:  
   ```bash
   conda activate snakemake_env
   ```
   
4. **Download/clone the Hi-C workflow git repository**:
   ```bash
   git clone https://github.com/JLRosenkrantz/snakemake-hic.git
   ```  

---

## Input Data Requirements

### 1. Raw Data
#### Create a new directory to store raw data:
   ```bash
   mkdir -p data/raw
   ```

#### Place raw Hi-C sequencing reads (fastq.gz) in new directory:
- If you have **write access** to the raw data files, create symbolic links to avoid duplication:
   ```bash
   ln -s /path/to/raw-data/*.fastq.gz data/raw/
   ```

- If you **do not have write access**, copy the files instead:
   ```bash
   cp /path/to/raw-data/*.fastq.gz data/raw/
   ```

#### Ensure that all files are gzip-compressed (`.fastq.gz`).
The workflow will error if uncompressed (`.fastq`) or incorrecly named (`.fa.gz`) files are used.

### 2. File/Sample Naming Convention:
Files must be named using the following format: 
`Sample1_R1.fastq.gz`, `Sample1_R2.fastq.gz`
   - `_R1` → Read 1 of paired-end sequencing
   - `_R2` → Read 2 of paired-end sequencing

Incorrect names will cause the workflow to fail. Manually rename files if needed before running the workflow.

---

## Configuration Setup
Before running the workflow, update the configuration file: `config/config.yml` and set the correct file paths for the data you are analyzing. See example below:
   - GENOME: "/home/groups/hoolock2/u0/genomes/ucsc/rheMac10/indexes/bowtie2/rheMac10"
   - DIGEST: "/home/groups/hoolock2/u0/genomes/ucsc/rheMac10/hicup-digest/Digest_rheMac10_DpnII_Arima_None_08-47-56_19-01-2020.txt"
   - CHRSIZES: "/home/groups/hoolock2/u0/genomes/ucsc/rheMac10/rheMac10.chrom.sizes"

#### GENOME:
Path to bowtie2 index of genome

#### DIGEST:
Path to restriction site file. To generate Arima HIC genome restriction site file using the [hicup](https://www.bioinformatics.babraham.ac.uk/projects/hicup/) command [hicup_digester](https://www.bioinformatics.babraham.ac.uk/projects/hicup/) with the flag `--arima` for compatability with the Arima HIC protocol.

examples:
```bash
hicup_digester --re1 ^GATC,MboI --genome Mouse_mm10 --outdir hicup-digest/ *.fa &
hicup_digester --arima --genome Human_hg38 --outdir hicup-digest/ *.fa &
```

#### CHRSIZES:
Path to chromosome size file. Can be downloaded from UCSC genome browser or other sources. 

---

## Execution:
Run the following command from the main directory to execute **practice dry run**:
```bash
snakemake --use-conda -np
```

Run the following command from the main directory to **execute snakemake workflow**:
```bash
snakemake --use-conda -j32 > $(date +"%y%m%d%H%M%S")_snakemake.out 2>&1
```

---

## Runtime:
The hicup pipeline is the most resource intensive step that can be expected to run for at least 24 hours for a sample with a sequencing depth of 500 million reads and 8 threads.

---

## Results:
Once the workflow completes, the following output files will be generated:

### 1. Quality Control Reports
- **FastQC Reports**: `results/fastqc/{sample}_fastqc.html`
- **MultiQC Summary**: `results/fastqc/multiqc_report.html`
   - Aggregates FastQC results for an overview of sequencing quality.

### 2. Processed Hi-C Data
- **Aligned Reads (BAM format)**:
   - `results/hicup/{sample}/{sample}_R1_2.hicup.bam`
   - Deduplicated and mapped Hi-C read pairs.

- **Contact Matrices**:
   - `.cool` file: `results/cool/{sample}.cool`
   - `.mcool` file: `results/cool/{sample}.mcool`
   - `.hic` file (for Juicebox visualization): `results/hic/{sample}.hic`

### 3. TAD and Chromatin Structure Analysis
- **TAD calls**:
   - `results/tads/{sample}_tads.bed`
- **Hi-C interaction maps**:
   - `.mcool` files can be loaded into **HiGlass** for visualization.

---

## Visualization
To visualize Hi-C contact matrices:

- **Juicebox**:
Use `.hic` files

- **HiGlass**:
Use .mcool files for interactive genome contact visualization.








