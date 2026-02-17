#!/usr/bin/env nextflow

/*
 * bridge between Salmon quantification and differential expression analysis.
 * Transcript-level estimates (from Salmon) > Gene-level count matrices (for DESeq2)
 */

process MERGE_QUANT {

    container 'quay.io/biocontainers/bioconductor-tximport:1.30.0--r43hdfd78af_0'

    input:
    path quant_dirs  // ← Now receiving directories, not individual files
    path tx2gene

    output:
    path "merged_counts.tsv", emit: counts
    path "txi.rds", emit: txi

    script:
    """
    #!/usr/bin/env Rscript
    
    library(tximport)
    
    # Find all quant.sf files in subdirectories
    files <- list.files(".", pattern="quant.sf", full.names=TRUE, recursive=TRUE)
    
    cat("Files found:\\n")
    print(files)
    
    # Extract sample IDs from directory names
    sample_ids <- sapply(files, function(f) {
        # Path looks like: ./SRR17382349_quant/quant.sf
        dir_name <- dirname(f)  # ./SRR17382349_quant
        base_dir <- basename(dir_name)  # SRR17382349_quant
        sample_id <- gsub("_quant\$", "", base_dir)  # SRR17382349
        return(sample_id)
    })
    
    names(files) <- sample_ids
    
    cat("\\nSample mapping:\\n")
    print(data.frame(sample_id = names(files), file = files, row.names = NULL))
    
    # Load tx2gene
    tx2gene <- read.delim("${tx2gene}", header = FALSE, stringsAsFactors = FALSE)
    colnames(tx2gene) <- c("transcript_id", "gene_id")
    
    # Import
    txi <- tximport(files, type = "salmon", tx2gene = tx2gene, 
                    ignoreTxVersion = TRUE, ignoreAfterBar = TRUE, 
                    dropInfReps = TRUE)
    
    # Save
    saveRDS(txi, "txi.rds")
    # Create properly formatted counts table
    counts_df <- as.data.frame(txi\$counts)
    counts_df <- cbind(gene_id = rownames(counts_df), counts_df)
    rownames(counts_df) <- NULL

    write.table(counts_df, "merged_counts.tsv", sep = "\t", 
                quote = FALSE, row.names = FALSE, col.names = TRUE)
    
    cat("\\nSuccessfully merged", length(files), "samples\\n")
    cat("Column names:", colnames(txi\$counts), "\\n")
    """
}