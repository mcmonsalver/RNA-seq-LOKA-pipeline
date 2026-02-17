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

### 1. Launch Codespace

1. Go to the [repository](https://github.com/mcmonsalver/RNA-seq-LOKA-pipeline)
2. Click **Code** → **Codespaces** → **Create codespace on main**
3. Wait 2-3 minutes for environment setup
