#!/usr/bin/env nextflow

/*
 * Downloads the tx2gene file if a link is provided 
 */

 process GTF_DOWNLOAD {

    input:
    val link

    output:
    path "*.gtf.gz", emit: gtf
    path "tx2gene.tsv", emit: tx2gene

    script:
    """
    wget -q ${link}
    
    GTF_FILE=\$(basename "${link}")
    
    # Convert to uppercase AND strip version numbers for consistency
    zcat "\$GTF_FILE" | \\
    perl -ne 'if (/\\ttranscript\\t/) {
        /gene_id "([^"]+)"/; my \$gene=uc(\$1);
        /transcript_id "([^"]+)"/; my \$tx=uc(\$1);
        # Remove version numbers (everything after dot)
        \$gene =~ s/\\.\\d+\$//;
        \$tx =~ s/\\.\\d+\$//;
        print "\$tx\\t\$gene\\n" if \$tx && \$gene;
    }' | sort -u > tx2gene.tsv
    
    if [ ! -s tx2gene.tsv ]; then
        echo "ERROR: tx2gene.tsv is empty!" >&2
        exit 1
    fi
    
    echo "Created tx2gene.tsv with \$(wc -l < tx2gene.tsv) mappings (versions stripped)"
    head -10 tx2gene.tsv
    """
}