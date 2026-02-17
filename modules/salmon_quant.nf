#!/usr/bin/env nextflow

/*
 * salmon quant: Quantify reads against index 
 */

process SALMON_QUANT {

    container 'community.wave.seqera.io/library/salmon:1.10.3--fcd0755dd8abb423'

    input:
    tuple val(sample_id), val(condition), val(layout), path(reads)
    each path (index) //the each, allows to use the same index for the multiple tuples

    output:
    tuple val(sample_id), val(condition), val(layout), path ("${sample_id}_quant"), emit: dir 
    path "${sample_id}_quant", emit: quant

    script:
    if (layout == 'PAIRED') {
        """
        salmon quant \
            -i ${index} \
            -l A \
            -1 ${reads[0]} \
            -2 ${reads[1]} \
            -p ${task.cpus} \
            --validateMappings \
            -o ${sample_id}_quant
        """
    }
    else {
        """
        salmon quant \
            -i ${index} \
            -l A \
            -r ${reads[0]} 
            -p ${task.cpus} \
            --validateMappings \
            -o ${sample_id}_quant
        """
    }
}