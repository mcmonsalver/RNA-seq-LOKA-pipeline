#!/usr/bin/env nextflow

/*
 * pass the local fastq files through a process to publish them in results  
 */


process FETCH_FASTQ {

    input:
    tuple val(sample_id), val(condition), val(layout), path(reads)

    output:
    path (reads)

    script:
    """
    echo ""
    """
}