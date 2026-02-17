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

