#!/usr/bin/env nextflow

/*
 * multiQC takes all the FASTQC .zip files from the FASQC process to create a single multiQC file
 */

process MULTIQC {

    container 'community.wave.seqera.io/library/multiqc:1.33--ee7739d47738383b'

    input:
    path fastqc_files
    val stage

    output:
    path "*.html", emit: html
    path "*_data", emit: data

    script:
    """
    multiqc ${fastqc_files} \
        --filename ${stage}_multiqc_report \
        --outdir .
    """
}