#!/usr/bin/env nextflow

/*
 * use the fastqc function from docker container to read fastq 
 * files and output .zip and .html files 
 */

process FASTQC {

    container 'community.wave.seqera.io/library/fastqc:0.12.1--af7a5314d5015c29'

    input:
    tuple val(sample_id), val(condition), val(layout), path(reads)
    val stage

    output:
    path "*_${stage}_fastqc.html", emit: html
    path "*_${stage}_fastqc.zip", emit: zip

    script:
    """
    fastqc ${reads}

    for file in *_fastqc.html; do
        base=\$(basename \$file _fastqc.html)
        mv \$file \${base}_${stage}_fastqc.html
    done

    for file in *_fastqc.zip; do
        base=\$(basename \$file _fastqc.zip)
        mv \$file \${base}_${stage}_fastqc.zip
    done
    """
}

