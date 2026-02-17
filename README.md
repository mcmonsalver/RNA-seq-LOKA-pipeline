# RNA-seq-LOKA-pipeline
A production-ready Nextflow pipeline for RNA-seq differential expression analysis, implementing both primary and secondary analysis stages.

## Overview
This pipeline processes RNA-seq data from raw FASTQ files through quality control, trimming, quantification, and differential expression analysis. It was developed as part of a bioinformatics technical assessment and demonstrates end-to-end workflow orchestration using Nextflow.

### Pipeline Stages

**Primary Analysis:**
- Quality control assessment (FastQC)
- Adapter trimming and quality filtering (fastp)
- Transcript-level quantification (Salmon)
- Quality report aggregation (MultiQC)

**Secondary Analysis:**
- Transcript-to-gene count aggregation (tximport)
- Differential expression analysis (DESeq2)
- Statistical visualization (PCA, volcano plots)

## Features

✅ Modular, containerized processes  
✅ Support for both local FASTQ files and SRA accessions  
✅ Paired-end and single-end read support  
✅ Automatic reference genome/transcriptome download  
✅ Comprehensive quality control at each step  
✅ Reproducible analysis with Docker containers  

## Requirements

### Software Dependencies

- **Nextflow** >= version 25.10.3
- **Docker** 
- **Git** (for cloning the repository)

### System Requirements

**Minimum (for demo dataset):**
- 4 CPU cores
- 16 GB RAM
- 50 GB disk space

**Recommended (for full datasets):**
- 8+ CPU cores
- 32+ GB RAM
- 100+ GB disk space

### Option 1: GitHub Codespaces (Recommended - Zero Setup!)

**Fastest way to get started** - everything is pre-configured:

1. Go to [https://github.com/mcmonsalver/RNA-seq-LOKA-pipeline](https://github.com/mcmonsalver/RNA-seq-LOKA-pipeline)
2. Click **Code** → **Codespaces** → **Create codespace on main**
3. Wait 2-3 minutes while the environment sets up automatically

The `.devcontainer` configuration automatically installs:
- ✅ Nextflow (latest version)
- ✅ Java 17 (Nextflow dependency)
- ✅ Docker-in-Docker (for containers)
- ✅ Helpful VS Code extensions

**Skip to [Quick Start](#quick-start) section - you're ready to run!**

---
## Installation

### Option 2: Local Installation (Manual Setup)

For running on your own machine or HPC cluster:

#### 1. Install Nextflow

```bash
# Download Nextflow
curl -s https://get.nextflow.io | bash

# Make it executable
chmod +x nextflow

# Move to a directory in your PATH
sudo mv nextflow /usr/local/bin/

# Verify installation
nextflow -version
```

**Without sudo access (HPC/shared systems):**
```bash
curl -s https://get.nextflow.io | bash
mkdir -p ~/bin
mv nextflow ~/bin/
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
nextflow -version
```

#### 2. Install Docker

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y docker.io
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect
```

**macOS:**
```bash
brew install --cask docker
```

**For other systems:** See https://docs.docker.com/get-docker/

#### 3. Clone the Repository

```bash
git clone https://github.com/mcmonsalver/RNA-seq-LOKA-pipeline.git
cd RNA-seq-LOKA-pipeline
```

## Quick Start

### Running the Demo Dataset

The pipeline includes a metadata file for 4 Arabidopsis thaliana samples (2 cold stress, 2 control). You just need to download the FASTQ files:

#### 1. Download Demo Data

```bash
# Go the the data directory
cd data

# Download the 4 demo samples (paired-end) (~2-3 GB total)
wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR173/049/SRR17382349/SRR17382349_1.fastq.gz
wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR173/049/SRR17382349/SRR17382349_2.fastq.gz
wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR173/051/SRR17382351/SRR17382351_1.fastq.gz
wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR173/051/SRR17382351/SRR17382351_2.fastq.gz
wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR173/066/SRR17382366/SRR17382366_1.fastq.gz
wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR173/066/SRR17382366/SRR17382366_2.fastq.gz
wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR173/070/SRR17382370/SRR17382370_1.fastq.gz
wget -nc ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR173/070/SRR17382370/SRR17382370_2.fastq.gz

# Return to main directory
cd ..
```

#### 2. Run the Pipeline

```bash
# Run with default settings (uses local_metadataDEMO.csv)
nextflow run main.nf
```

## Input Data

The repository includes two metadata files in the `data/` directory:

### 1. `local_metadataDEMO.csv` (Default - Local FASTQ Files)

Pre-configured metadata for the 4-sample demo. Points to local FASTQ files you download with wget:

```csv
sample;condition;fastq_1;fastq_2
SRR17382349;cold;data/SRR17382349_1.fastq.gz;data/SRR17382349_2.fastq.gz
SRR17382351;control;data/SRR17382351_1.fastq.gz;data/SRR17382351_2.fastq.gz
SRR17382366;cold;data/SRR17382366_1.fastq.gz;data/SRR17382366_2.fastq.gz
SRR17382370;control;data/SRR17382370_1.fastq.gz;data/SRR17382370_2.fastq.gz
```

**This is used by default** - no configuration needed after downloading files.

### 2. `sra_metadata.csv` (Alternative - Automatic SRA Download)

Contains all samples from the complete experiment. Use this to automatically download data from SRA:

```csv
Run;treatment;LibraryLayout
SRR17382349;cold;PAIRED
SRR17382351;control;PAIRED
SRR17382366;cold;PAIRED
SRR17382370;control;PAIRED
...additional samples...
```

**To use SRA mode**:

```bash
nextflow run main.nf --input_mode sra
```

The pipeline will automatically download FASTQ files from SRA.

---

### Creating Your Own Metadata

#### For Local FASTQ Files (Paired-End)

Create a semicolon-separated CSV:

```csv
sample;condition;fastq_1;fastq_2
sample1;treatment;data/sample1_R1.fastq.gz;data/sample1_R2.fastq.gz
sample2;treatment;data/sample2_R1.fastq.gz;data/sample2_R2.fastq.gz
sample3;control;data/sample3_R1.fastq.gz;data/sample3_R2.fastq.gz
sample4;control;data/sample4_R1.fastq.gz;data/sample4_R2.fastq.gz
```

**Requirements:**
- ≥2 samples per condition (for DESeq2)
- Semicolon-separated (not comma)
- Column names must match exactly: `sample;condition;fastq_1;fastq_2`

#### For Local FASTQ Files (Single-End)

```csv
sample;condition;fastq
sample1;treatment;data/sample1.fastq.gz
sample2;control;data/sample2.fastq.gz
```

Update `nextflow.config`:
```groovy
params {
    PE_or_SE = 'SE'  // Change from 'PE' to 'SE'
    samplesheet_local = 'data/your_metadata.csv'
}
```
## Configuration

### Basic Parameters

Edit `nextflow.config` to customize the pipeline:

```groovy
params {
    // Input mode: 'local' or 'sra'
    input_mode = 'local'
    
    // For local FASTQ files
    PE_or_SE = 'PE'  // 'PE' for paired-end, 'SE' for single-end
    samplesheet_local = 'data/local_metadataDEMO.csv'
    
    // For SRA downloads
    samplesheet_sra = 'data/sra_metadata.csv'
    
    // Reference genome/transcriptome
    reference_fasta_link = 'https://ftp.ensemblgenomes.ebi.ac.uk/pub/plants/release-62/fasta/arabidopsis_thaliana/cdna/Arabidopsis_thaliana.TAIR10.cdna.all.fa.gz'
    reference_gtf_link = 'https://ftp.ensemblgenomes.ebi.ac.uk/pub/plants/release-62/gtf/arabidopsis_thaliana/Arabidopsis_thaliana.TAIR10.62.gtf.gz'
}
```
### Resource Configuration

**Local execution (default):**
```groovy
process {
    executor = 'local'
    cpus = 2
    memory = '4 GB'
}
```

**AWS Batch execution:**
```bash
nextflow run main.nf -profile aws
```

