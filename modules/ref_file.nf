#!/usr/bin/env nextflow

/*
 * pass the local fastq files through a process to publish them in results  
 */


process REF_FILE {

    input:
    path ref_input

    output:
    path (ref_input)

    script:
    """
    echo ""
    """
}