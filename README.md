# RNA-Seq Preprocessing Pipeline

A Nextflow DSL2 pipeline for automated RNA-Seq preprocessing directly from NCBI SRA accessions. The workflow downloads sequencing data, performs quality control, trims low-quality reads, and generates consolidated quality reports.

---

## Overview

This pipeline performs the following steps:

1. Download sequencing data from NCBI SRA
2. Convert SRA files to FASTQ format
3. Run FastQC on raw reads
4. Trim adapters and low-quality bases using Fastp
5. Run FastQC on trimmed reads
6. Generate a MultiQC summary report

The workflow supports both:

* Single-end RNA-Seq data
* Paired-end RNA-Seq data

All processing is containerized using Docker (one image per process) and orchestrated with Nextflow.

---

## Workflow

```text
SRA Accession IDs
        │
        ▼
 DOWNLOAD_SRA
        │
        ▼
   FASTQC_RAW
        │
        ▼
      FASTP
        │
        ▼
 FASTQC_TRIMMED
        │
        ▼
     MULTIQC
```

---

## Requirements

* Docker
* Nextflow (v22+ recommended)

---

## Docker Images

Each process runs in its own dedicated container. The images are located under `docker/`:

| Process                            | Image       | Directory           |
| ---------------------------------- | ----------- | ------------------- |
| `DOWNLOAD_SRA`                     | `sra-tools` | `docker/sra-tools/` |
| `FASTQC_RAW` and `FASTQC_TRIMMED`  | `fastqc`    | `docker/fastqc/`    |
| `FASTP`                            | `fastp`     | `docker/fastp/`     |
| `MULTIQC`                          | `multiqc`   | `docker/multiqc/`   |

### Build All Images

```bash
docker build -t sra-tools docker/sra-tools/
docker build -t fastqc    docker/fastqc/
docker build -t fastp     docker/fastp/
docker build -t multiqc   docker/multiqc/
```

---

## Input

Create a file:

```text
input/samples.tsv
```

Containing one SRA accession per line:

```text
SRR12345678
SRR12345679
SRR12345680
```

---

## Running the Pipeline

```bash
nextflow run main.nf
```

Or specify custom parameters:

```bash
nextflow run main.nf \
    --samples input/samples.tsv \
    --outdir results
```

---

## Configuration

Pipeline resources and container assignments are defined in `nextflow.config`:

| Process          | Container   | CPUs | Memory |
| ---------------- | ----------- | ---- | ------ |
| `DOWNLOAD_SRA`   | `sra-tools` | 8    | 16 GB  |
| `FASTQC_RAW`     | `fastqc`    | 4    | 4 GB   |
| `FASTP`          | `fastp`     | 8    | 8 GB   |
| `FASTQC_TRIMMED` | `fastqc`    | 4    | 4 GB   |
| `MULTIQC`        | `multiqc`   | 2    | 2 GB   |

Docker execution is enabled by default:

```groovy
docker.enabled = true
```

---

## Output Structure

```text
results/
│
├── fastq/
│   └── Raw FASTQ files
│
├── trimmed/
│   └── Trimmed FASTQ files
│
├── fastqc/
│   ├── raw/
│   └── trimmed/
│
├── fastp/
│   ├── *.html
│   └── *.json
│
└── multiqc/
    └── multiqc_report.html
```

---

## Fastp Parameters

### Paired-End Reads

```bash
--detect_adapter_for_pe
--cut_right
--cut_right_mean_quality 20
--length_required 20
```

### Single-End Reads

```bash
--cut_right
--cut_right_mean_quality 20
--length_required 20
```

This removes:

* Adapter contamination
* Low-quality bases from read ends
* Reads shorter than 20 bp after trimming

---

## Generated Reports

### FastQC

Generated for raw and trimmed reads:

```text
*_fastqc.html
*_fastqc.zip
```

### Fastp

Generated per sample:

```text
*.fastp.html
*.fastp.json
```

### MultiQC

Aggregates all FastQC and Fastp reports into:

```text
multiqc_report.html
```

---

## Notes

* The workflow automatically detects whether a sample is single-end or paired-end based on the number of FASTQ files produced by `fasterq-dump`.
* FASTQ files are compressed using `pigz` for faster parallel compression.
* Each process runs in its own minimal Docker container, keeping images small and dependencies isolated.
* MultiQC combines FastQC and Fastp outputs into a single report for easier assessment of preprocessing quality.

