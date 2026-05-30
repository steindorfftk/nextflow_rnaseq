nextflow.enable.dsl=2

params.samples = "input/samples.tsv"
params.outdir  = "results"


Channel
    .fromPath(params.samples)
    .splitText()
    .map { it.trim() }
    .filter { it }
    .set { srr_ids }


process DOWNLOAD_SRA {

    tag "$srr"

    publishDir "${params.outdir}/fastq", mode: 'copy'

    input:
    val srr

    output:
    tuple val(srr), path("*.fastq.gz")

    script:
    """
    prefetch ${srr}

    fasterq-dump \
        --threads ${task.cpus} \
        --split-files \
        ${srr}

    pigz *.fastq
    """
}


process FASTQC_RAW {

    tag "$srr"

    publishDir "${params.outdir}/fastqc/raw", mode: 'copy'

    input:
    tuple val(srr), val(layout), path(reads)

    output:
    tuple val(srr), val(layout), path(reads), emit: reads
    path("*_fastqc.zip"), emit: zip
    path("*_fastqc.html"), emit: html

    script:
    """
    fastqc \
        --threads ${task.cpus} \
        ${reads.join(' ')}
    """
}


process FASTP {

    tag "$srr"

    publishDir "${params.outdir}/trimmed", mode: 'copy', pattern: "*.fastq.gz"
    publishDir "${params.outdir}/fastp", mode: 'copy', pattern: "*.html"
    publishDir "${params.outdir}/fastp", mode: 'copy', pattern: "*.json"

    input:
    tuple val(srr), val(layout), path(reads)

    output:
    tuple val(srr), val(layout), path("*.trimmed.fastq.gz"), emit: reads
    path("*.html"), emit: html
    path("*.json"), emit: json

    script:

    if (layout == 'PAIRED') {
        """
        fastp \
            --detect_adapter_for_pe \
            --cut_right \
            --cut_right_mean_quality 20 \
            --length_required 20 \
            -i ${reads[0]} \
            -I ${reads[1]} \
            -o ${srr}_R1.trimmed.fastq.gz \
            -O ${srr}_R2.trimmed.fastq.gz \
            --html ${srr}.fastp.html \
            --json ${srr}.fastp.json
        """
    }
    else {
        """
        fastp \
            --cut_right \
            --cut_right_mean_quality 20 \
            --length_required 20 \
            -i ${reads[0]} \
            -o ${srr}.trimmed.fastq.gz \
            --html ${srr}.fastp.html \
            --json ${srr}.fastp.json
        """
    }
}


process FASTQC_TRIMMED {

    tag "$srr"

    publishDir "${params.outdir}/fastqc/trimmed", mode: 'copy'

    input:
    tuple val(srr), val(layout), path(reads)

    output:
    tuple val(srr), val(layout), path(reads), emit: reads
    path("*_fastqc.zip"), emit: zip
    path("*_fastqc.html"), emit: html

    script:
    """
    fastqc \
        --threads ${task.cpus} \
        ${reads.join(' ')}
    """
}


process MULTIQC {

    publishDir "${params.outdir}/multiqc", mode: 'copy'

    input:
    path qc_files

    output:
    path "multiqc_report.html"

    script:
    """
    multiqc . --outdir .
    """
}


workflow {

    downloaded = DOWNLOAD_SRA(srr_ids)

    samples = downloaded.map { srr, reads ->

        def ordered_reads = reads.sort { it.name }

        assert ordered_reads.size() in [1, 2] :
            "Unexpected number of FASTQ files for ${srr}: ${ordered_reads.size()}"

        def layout = ordered_reads.size() == 2 ? 'PAIRED' : 'SINGLE'

        tuple(
            srr,
            layout,
            ordered_reads
        )
    }

    raw_qc = FASTQC_RAW(samples)

    trimmed = FASTP(raw_qc.reads)

    trimmed_qc = FASTQC_TRIMMED(trimmed.reads)

    qc_reports = raw_qc.zip
        .mix(raw_qc.html)
        .mix(trimmed.html)
        .mix(trimmed.json)
        .mix(trimmed_qc.zip)
        .mix(trimmed_qc.html)
        .collect()

    MULTIQC(qc_reports)
}
