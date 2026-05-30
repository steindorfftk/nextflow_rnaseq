FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# ==================================================
# Pacotes básicos
# ==================================================

RUN apt-get update && apt-get install -y \
    wget \
    curl \
    unzip \
    gzip \
    tar \
    git \
    nano \
    vim \
    openjdk-17-jre \
    python3 \
    python3-pip \
    build-essential \
    ca-certificates \
    fastqc \
    hisat2 \
    subread \
    samtools \
    bcftools \
    bedtools \
    parallel \
    pigz \
    sra-toolkit \
    && rm -rf /var/lib/apt/lists/*

# ==================================================
# Trimmomatic
# ==================================================

RUN mkdir -p /opt/trimmomatic && \
    wget -q -O /tmp/trimmomatic.zip \
    https://github.com/usadellab/Trimmomatic/releases/download/v0.39/Trimmomatic-0.39.zip && \
    unzip -q /tmp/trimmomatic.zip -d /opt/trimmomatic && \
    rm /tmp/trimmomatic.zip

ENV TRIMMOMATIC_JAR=/opt/trimmomatic/Trimmomatic-0.39/trimmomatic-0.39.jar

# Nextflow
RUN wget -qO- https://get.nextflow.io | bash && \
    mv nextflow /usr/local/bin/ && \
    chmod +x /usr/local/bin/nextflow

# ==================================================
# ==================================================
# Diretórios padrão
# ==================================================

RUN mkdir -p \
    /data/input \
    /data/sra \
    /data/fastq \
    /data/reference \
    /data/qc \
    /data/alignment \
    /data/counts

# ==================================================
# Configuração SRA Toolkit
# ==================================================

RUN mkdir -p /root/.ncbi && \
    printf '/repository/user/main/public/root = "/data/sra"\n' \
    > /root/.ncbi/user-settings.mkfg

# ==================================================
# Arquivo para featureCounts
# ==================================================

RUN wget -O /data/reference/hg38_RefSeq_exon.txt \
    https://raw.githubusercontent.com/steindorfftk/Hisat2-RNA-seq-pre-processing/main/feature_counts/data/hg38_RefSeq_exon.txt

WORKDIR /workspace

CMD ["/bin/bash"]
