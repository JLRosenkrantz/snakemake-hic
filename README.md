# Hi-C Workflow

Snakemake workflow for QC and processing of HiC data. Results in .cool, .mcool, .hic files and TAD calls for the data. All commands used to QC, and process hic-data are contained in the main Snakefile. This Snakemake workflow was streamlined and expanded by Jimi Rosenkrantz in 2025, following workflow established by Jake in Carbone lab in 2023.

---

## Requirements

This workflow requires:
•	**Conda** (for environment management)
•	**Snakemake** and **git** (for workflow download and automation)

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
Create a new directory to store raw data:
   ```bash
   mkdir -p data/raw
   ```

Place raw Hi-C sequencing reads (fastq.gz) in new directory:

If you have write access to the raw data files, create symbolic links to avoid duplication:

ln -s /path/to/raw-data/*.fastq.gz data/raw/

If you do not have write access, copy the files instead:
cp /path/to/raw-data/*.fastq.gz data/raw/

Ensure that all files are gzip-compressed (`.fastq.gz`). The workflow will error if uncompressed (`.fastq`) files are used.

File/Sample Naming Convention:
•	Files must be named using the following format: `Sample1_1.fastq.gz`, `Sample1_2.fastq.gz`
o	`_1` → Read 1 of paired-end sequencing
o	`_2` → Read 2 of paired-end sequencing
•	Incorrect names will cause the workflow to fail.
•	Manually rename files if needed before running the workflow.

![image](https://github.com/user-attachments/assets/cacb3833-8315-457e-888e-4cadce6ae12d)






Hi-C raw sequencing reads should be placed in a designated directory:

```bash
mkdir -p data/raw
```

If you have **write access** to the raw data files, create symbolic links to avoid duplication:
```bash
ln -s /path/to/raw-data/*.fastq.gz data/raw/
```

If you **do not have write access**, copy the files instead:
```bash
cp /path/to/raw-data/*.fastq.gz data/raw/
```

Ensure that all files are **gzip-compressed** (`.fastq.gz`). The workflow will error if uncompressed (`.fastq`) files are used.

Manually rename files to desired sampleID plus _1 (for forward read) and _2 (for reverse read). For example:
rhesus_HiC_test_1.fastq.gz
rhesus_HiC_test_2.fastq.gz










---

### 2. File names and sample names





































# HIC Workflow

Snakemake workflow for QC and processing of HIC data. Results in on .cool file and TAD calls for the data. All commands used to QC, and process hic-data are contianed in the main Snakefile.

**Prep**:

Place raw HIC reads in a new directory data/raw

```
mkdir -p data/raw
ln -s /home/groups/hoolock2/u0/jimi/raw_data/250305-Novogene-HiC-MicroC-test/merged/*.fastq.gz data/raw/
```
Make sure files are compressed with gzip (.fastq.gz NOT .fastq). snakemake workflow will error if files are unzipped .fastq

```
/home/groups/hoolock2/u0/jvc/TAD-RO1/GEO_SUB/nomLeu4_HiC_2_R1.fastq.gz
/home/groups/hoolock2/u0/jvc/TAD-RO1/GEO_SUB/nomLeu4_HiC_2_R2.fastq.gz
/home/groups/hoolock2/u0/bd/tmp_data/gibbon_hic/Vok_NLE_HiC_S3_L006_R1_001.fastq.gz
/home/groups/hoolock2/u0/bd/tmp_data/gibbon_hic/Vok_NLE_HiC_S3_L006_R2_001.fastq.gz

SAMPLES:
    - "Gibbon_nomLeu4"
    - "Gibbon_Vok_NLE"

```


**Configure the file**: src/config.yml

Generate Arima HIC genome restriction site file using the [hicup](https://www.bioinformatics.babraham.ac.uk/projects/hicup/) command [hicup_digester](https://www.bioinformatics.babraham.ac.uk/projects/hicup/) with the flag `--arima` for compatability with the Arima HIC protocol.

All commands used to QC, and process hic-data are contianed in the main Snakefile. The pipeline uses conda for dependency management. Make sure you have installed a recent version of snakemake and conda.
```
example:
hicup_digester --re1 ^GATC,MboI --genome Mouse_mm10 --outdir hicup-digest/ *.fa &
hicup_digester --arima --genome Human_hg38 --outdir hicup-digest/ *.fa &
```

**Execution**:

```
snakemake --use-conda -j20
snakemake --use-conda -j20 > 240905h_snakemake.out 2>&1
snakemake --use-conda -j20 > $(date +"%y%m%d%H%M%S")_snakemake.out 2>&1

snakemake --use-conda -j20 cooler_cload zoomify hicFindTADs > $(date +"%y%m%d%H%M%S")_snakemake.out 2>&1


```

**Runtime**

The hicup pipeline is the most resource intensive step that can be expected to run for at least 24 hours for a sample with a sequencing depth of 500 million reads and 8 threads.










