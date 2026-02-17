#!/usr/bin/env nextflow

/*
 * DESeq2: Which genes are differentially expressed between conditions
 */

process DESEQ2_ANALYSIS {
    // NOTE: Requires ≥2 biological replicates per condition for valid statistics
    // With n=1 per condition, results are for demonstration only
    
    container 'quay.io/biocontainers/mulled-v2-8849acf39a43cdd6c839a369a74c0adc823e2f91:ab110436faf952a33575c64dd74615a84011450b-0'
    
    input:
    path txi
    path metadata  // CSV with columns: sample;condition;fastq_1;fastq_2
    
    output:
    path "deg_results.csv", emit: results
    path "normalized_counts.csv", emit: norm_counts
    path "pca_plot.pdf", emit: pca
    path "volcano_plot.pdf", emit: volcano
    path "sample_info.txt", emit: info
    
    when:
    true  // Changed to true - ready to run!
    
    script:
    """
    #!/usr/bin/env Rscript
    library(DESeq2)
    library(ggplot2)
    
    # Load tximport object
    txi <- readRDS("${txi}")
    
    cat("TXI object structure:\\n")
    cat("Samples in txi:", colnames(txi\$counts), "\\n")
    cat("Number of genes:", nrow(txi\$counts), "\\n\\n")
    
    # Load metadata (semicolon-separated)
    metadata <- read.csv("${metadata}", sep=";", stringsAsFactors = FALSE)
    
    cat("Metadata loaded:\\n")
    print(metadata)
    cat("\\n")
    
    # Create coldata for DESeq2 (only sample and condition)
    coldata <- data.frame(
        condition = factor(metadata\$condition),
        row.names = metadata\$sample
    )
    
    # Ensure coldata rows match txi columns
    if (!all(colnames(txi\$counts) %in% rownames(coldata))) {
        cat("ERROR: Sample ID mismatch!\\n")
        cat("Samples in txi:", colnames(txi\$counts), "\\n")
        cat("Samples in metadata:", rownames(coldata), "\\n")
        stop("Sample IDs in txi do not match metadata!")
    }
    
    coldata <- coldata[colnames(txi\$counts), , drop = FALSE]
    
    cat("Final sample information for DESeq2:\\n")
    print(coldata)
    cat("\\n")
    
    # Save sample info
    sink("sample_info.txt")
    cat("DESeq2 Analysis - Arabidopsis Cold Stress\\n")
    cat("==========================================\\n\\n")
    cat("Samples:\\n")
    print(coldata)
    cat("\\nCondition levels:", levels(coldata\$condition), "\\n")
    cat("Samples per condition:\\n")
    print(table(coldata\$condition))
    cat("\\nNOTE: With n=1 per condition, statistical power is limited.\\n")
    cat("Results are for pipeline demonstration purposes.\\n")
    sink()
    
    # Create DESeq2 dataset
    dds <- DESeqDataSetFromTximport(txi, coldata, design = ~condition)
    
    cat("DESeq2 dataset created\\n")
    cat("Design formula: ~condition\\n\\n")
    
    # Run DESeq2 (will warn about low replicates)
    cat("Running DESeq2 analysis...\\n")
    dds <- DESeq(dds)
    cat("DESeq2 analysis complete\\n\\n")
    
    # Get results (specify contrast for clarity)
    res <- results(dds, contrast = c("condition", "cold", "control"))
    
    cat("Results summary:\\n")
    summary(res)
    cat("\\n")
    
    write.csv(as.data.frame(res), "deg_results.csv", row.names = TRUE)
    
    # Normalized counts
    norm_counts <- counts(dds, normalized = TRUE)
    write.csv(norm_counts, "normalized_counts.csv", row.names = TRUE)
    
    # Visualizations
    cat("Generating visualizations...\\n")
    
    # Transform data for visualization
    vsd <- vst(dds, blind = FALSE)
    
    # PCA plot
    pdf("pca_plot.pdf", width = 8, height = 6)
    p <- plotPCA(vsd, intgroup = "condition") + 
          theme_bw() +
          ggtitle("PCA - Cold vs Control") +
          theme(plot.title = element_text(hjust = 0.5))
    print(p)
    dev.off()
    
    # Volcano plot
    pdf("volcano_plot.pdf", width = 10, height = 8)
    
    # Remove NAs for plotting
    res_plot <- as.data.frame(res)
    res_plot <- res_plot[!is.na(res_plot\$padj), ]
    
    # Create color vector
    res_plot\$color <- "gray"
    res_plot\$color[res_plot\$padj < 0.05 & res_plot\$log2FoldChange > 1] <- "red"
    res_plot\$color[res_plot\$padj < 0.05 & res_plot\$log2FoldChange < -1] <- "blue"
    
    plot(res_plot\$log2FoldChange, -log10(res_plot\$pvalue), 
         pch = 20, 
         col = res_plot\$color,
         main = "Volcano Plot - Cold vs Control",
         xlab = "log2 Fold Change (Cold / Control)",
         ylab = "-log10(p-value)",
         xlim = c(min(res_plot\$log2FoldChange, na.rm=TRUE)-1, 
                  max(res_plot\$log2FoldChange, na.rm=TRUE)+1))
    
    abline(h = -log10(0.05), col = "darkgray", lty = 2, lwd = 1.5)
    abline(v = c(-1, 1), col = "darkgray", lty = 2, lwd = 1.5)
    
    legend("topright", 
           legend = c("Upregulated (padj<0.05, log2FC>1)", 
                     "Downregulated (padj<0.05, log2FC<-1)", 
                     "Not significant"),
           col = c("red", "blue", "gray"), 
           pch = 20,
           cex = 0.8)
    
    dev.off()
    
    # Final summary
    cat("\\n=== Analysis Summary ===\\n")
    cat("Total genes analyzed:", nrow(res), "\\n")
    cat("Genes with padj < 0.05:", sum(res\$padj < 0.05, na.rm = TRUE), "\\n")
    cat("Upregulated in cold (padj<0.05, log2FC>1):", 
        sum(res\$padj < 0.05 & res\$log2FoldChange > 1, na.rm = TRUE), "\\n")
    cat("Downregulated in cold (padj<0.05, log2FC<-1):", 
        sum(res\$padj < 0.05 & res\$log2FoldChange < -1, na.rm = TRUE), "\\n")
    
    cat("\\nOutput files created:\\n")
    cat("- deg_results.csv: Full DESeq2 results\\n")
    cat("- normalized_counts.csv: Normalized count matrix\\n")
    cat("- pca_plot.pdf: PCA visualization\\n")
    cat("- volcano_plot.pdf: Volcano plot\\n")
    cat("- sample_info.txt: Sample metadata summary\\n")
    """
}