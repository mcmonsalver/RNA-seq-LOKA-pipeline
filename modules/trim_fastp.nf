#!/usr/bin/env nextflow

/*
 * trimming leftover adapters, low-quality bases at read ends, PCR artifacts
 */

process TRIM_FASTP {

    container 'community.wave.seqera.io/library/fastp:1.1.0--08aa7c5662a30d57'

    input:
    tuple val(sample_id), val(condition), val(layout), path(reads)

    output:
    tuple val(sample_id), val (condition), val(layout), path("${sample_id}*trimmed.fastq.gz"), emit: trimmed_reads
    path "*.html", emit: html
    path "*.json", emit: json

    script:
    if (layout == 'PAIRED') {
        """
        fastp \
            -i ${reads[0]} \
            -I ${reads[1]} \
            -o ${sample_id}_1_trimmed.fastq.gz \
            -O ${sample_id}_2_trimmed.fastq.gz \
            --html ${sample_id}_fastp.html \
            --json ${sample_id}_fastp.json
        """
    }
    else {
        """
        fastp \
            -i ${reads[0]} \
            -o ${sample_id}_trimmed.fastq.gz \
            --html ${sample_id}_fastp.html \
            --json ${sample_id}_fastp.json
        """
    }
}