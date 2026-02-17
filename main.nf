#!/usr/bin/env nextflow

// Include modules
include { FETCH_SRA } from './modules/fetch_SRA.nf'
include { FASTQC as FASTQC_RAW } from './modules/fastqc.nf'
include { FASTQC as FASTQC_TRIMMED } from './modules/fastqc.nf'
include { MULTIQC as MULTIQC_RAW } from './modules/multiQC.nf'
include { MULTIQC as MULTIQC_TRIMMED } from './modules/multiQC.nf'
include { TRIM_FASTP } from './modules/trim_fastp.nf'
include { REF_FASTA_DOWNLOAD } from './modules/download_reference.nf'
include { FETCH_FASTQ } from './modules/fetch_fastq.nf'
include { REF_FILE } from './modules/ref_file.nf'
include { SALMON_INDEX } from './modules/salmon_index.nf'
include { SALMON_QUANT } from './modules/salmon_quant.nf'
include { GTF_DOWNLOAD } from './modules/download_gtf.nf'
include { MERGE_QUANT } from './modules/salmon_merge_counts.nf'
include { DESEQ2_ANALYSIS } from './modules/deseq2.nf'

workflow {

    main:

    // 1. FASTQ RECEIVED THROUGH SRA ACCESSION NUMBER
    if (params.input_mode == 'sra') {

        sra_input_ch = channel.fromPath(params.samplesheet_sra)
                        .splitCsv(header: true, sep: ';')
                        .map{row ->
                            tuple (row.Run, row.treatment, row.LibraryLayout)
                        }

        fastq_ch = FETCH_SRA(sra_input_ch)
    }

    // 1. Input_mode == 'local'. FASTQs stored locally. METADATA contains the paths. define if PE or SE in params
    else {

        if (params.PE_or_SE == 'SE') {
            
            fastq_ch = channel.fromPath(params.samplesheet_local)
                                .splitCsv(header: true, sep: ';')
                                .map{row ->
                                    tuple (row.sample, row.condition, 'SINGLE', [file(row.fastq)])
                                    }
        }

        //for PE data
        else { 

            fastq_ch = channel.fromPath(params.samplesheet_local)
                                .splitCsv(header: true, sep: ';')
                                .map{row ->
                                    tuple (row.sample, row.condition, 'PAIRED', [file(row.fastq_1), file(row.fastq_2)])
                                    }
        }

    }

    // to publish the fastq files in the results directory the FETCH FASTQ process is used
    FETCH_FASTQ(fastq_ch)
    
    // 2. Obtain the QC reports for the raw fastq files
    
    FASTQC_RAW(fastq_ch, "raw")
    fastqc_results_ch = FASTQC_RAW.out.zip.collect()
    MULTIQC_RAW(fastqc_results_ch, "raw")

    // 3. Use fastp to obtain trimmed files and new QC reports
    
    TRIM_FASTP(fastq_ch)
    trimmed_reads_ch = TRIM_FASTP.out.trimmed_reads

    FASTQC_TRIMMED(trimmed_reads_ch, "trimmed")
    fastqc_trimmed_results = FASTQC_TRIMMED.out.zip.collect()
    fastp_jsons = TRIM_FASTP.out.json.collect()
    trimmed_qc = fastqc_trimmed_results.mix(fastp_jsons).collect()

    MULTIQC_TRIMMED(trimmed_qc, "trimmed")

    // 4. REFERENCE FASTA TRANSCRIPTOME

    if (params.reference_fasta_link) {

        ref_link_ch = channel.of(params.reference_fasta_link)
        
        REF_FASTA_DOWNLOAD(ref_link_ch)

        ref_FASTA_ch = REF_FASTA_DOWNLOAD.out
    }

    else {
        println("No reference link was provided, looking for local file in ${params.reference_fasta_path}")

        ref_FASTA_ch = channel.fromPath(params.reference_fasta_path)
    }

    //to publish de ref file in the results directory REF FILE process is used
    transcriptome_ch = REF_FILE(ref_FASTA_ch)

    // 5. Salmon index reference transcriptome
    index_ch = SALMON_INDEX(transcriptome_ch)

    // 6. Salmon quant channel 
    SALMON_QUANT(trimmed_reads_ch, index_ch)
    quant_dirs_ch = SALMON_QUANT.out.quant.collect()

    // 7. Get tx2gene file
    gtf_files = GTF_DOWNLOAD(params.reference_gtf_link)

    //9. Merge quantification for downstream DESeq2
    MERGE_QUANT(quant_dirs_ch, gtf_files.tx2gene)

    // 10. DESeq2 differential expression
    txi_file = MERGE_QUANT.out.txi
    metadata_file = file(params.samplesheet_local)
    DESEQ2_ANALYSIS(txi_file, metadata_file)

    publish:
    //RAW
    //fastq_files = FETCH_FASTQ.out 
    //report1_QC = FASTQC_RAW.out.html
    //report2_QC = FASTQC_RAW.out.zip
    //multiQC_html = MULTIQC_RAW.out.html
    //multiQC_data = MULTIQC_RAW.out.data
    
    //TRIMMING 
    //trimmed_reads = TRIM_FASTP.out.trimmed_reads
    //report1_QC_trimmed = TRIM_FASTP.out.html
    //report2_QC_trimmed = TRIM_FASTP.out.json
    //report1_QC_t = FASTQC_TRIMMED.out.html
    //report2_QC_t = FASTQC_TRIMMED.out.zip
    //multiQC_html_t = MULTIQC_TRIMMED.out.html
    //multiQC_data_t = MULTIQC_TRIMMED.out.data
    
    // QUANTIFICATION
    //reference_fasta = REF_FILE.out
    //salmon_index = SALMON_INDEX.out
    salmon_quant = SALMON_QUANT.out.quant

    //COUNTS
    tsv = MERGE_QUANT.out.counts

    //DESeq2
    deg_res = DESEQ2_ANALYSIS.out.results
    norm_counts = DESEQ2_ANALYSIS.out.norm_counts
    pca_plot = DESEQ2_ANALYSIS.out.pca
    volcano_plot = DESEQ2_ANALYSIS.out.volcano
    deseq_info = DESEQ2_ANALYSIS.out.info
}


output {
    //RAW
    /*
    fastq_files {
        path 'raw/fastq'
    }
    
    report1_QC {
        path 'raw/qc/fastQC'
    }
    
    report2_QC {
        path 'raw/qc/fastQC'
    }
    */
    /*
    multiQC_html {
        path 'raw/qc/multiqc'
    }
    
    multiQC_data {
        path 'raw/qc/multiqc'
    }
    */
    //TRIMMED
    /*
    trimmed_reads {
        path 'trimmed/fastq'
    }
    
    report1_QC_trimmed {
        path 'trimmed/qc/fastp'
    }

    report2_QC_trimmed {
        path 'trimmed/qc/fastp'
    }

    report1_QC_t {
        path 'trimmed/qc/fastQC'
    }

    report2_QC_t {
        path 'trimmed/qc/fastQC'
    }
    
    multiQC_html_t {
        path 'trimmed/qc/multiqc'
    }
    */
    /*
    multiQC_data_t {
        path 'trimmed/qc/multiqc'
    }
    
    //QUANTIFICATION
    reference_fasta {
        path 'quant/reference_transcriptome'
    }

    salmon_index {
        path 'quant/salmon_index'
    }
    */
    salmon_quant {
        path 'quant'
    }

    //COUNTS
    tsv {
        path 'count'
    }

    //DESeq2
    deg_res {
        path 'DESeq2'
    }

    norm_counts {
        path 'DESeq2'
    }

    pca_plot {
        path 'DESeq2'
    }

    volcano_plot {
        path 'DESeq2'
    }

    deseq_info {
        path 'DESeq2'
    }

}