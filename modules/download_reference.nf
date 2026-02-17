#!/usr/bin/env nextflow

/*
 * Downloads the reference fasta file if a link is provided 
 */

 process REF_FASTA_DOWNLOAD {

    input:
    val link

    output:
    path "*.fa.gz"

    script:
    """
    wget -q ${link}
    """
}