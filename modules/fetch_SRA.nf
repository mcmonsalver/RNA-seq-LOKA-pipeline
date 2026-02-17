#!/usr/bin/env nextflow

/*
 * fetch the fastq files from the RNAseq data from SRA  
 */

process FETCH_SRA {

    container 'community.wave.seqera.io/library/sra-tools:3.2.1--2063130dadd340c5'

    input:
    tuple val(sample_id), val(condition), val(layout)

    output:
    tuple val(sample_id), val(condition), val(layout), path("*.fastq.gz")

    script:
    """
    prefetch ${sample_id} --max-size 50G
    
    fasterq-dump '${sample_id}' --split-files --threads 4
    gzip *.fastq
    """
}
