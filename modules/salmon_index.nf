#!/usr/bin/env nextflow

/*
 * salmon index: Build an index from your reference transcriptome 
 */

process SALMON_INDEX {

    container 'community.wave.seqera.io/library/salmon:1.10.3--fcd0755dd8abb423'

    input:
    path fasta

    output:
    path "salmon_index"

    script:
    """
    salmon index \
        -t ${fasta} \
        -i salmon_index \
        -k 31
    """
}