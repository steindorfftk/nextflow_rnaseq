FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    pigz \
    sra-toolkit \
    && rm -rf /var/lib/apt/lists/*

# SRA Toolkit cache config
RUN mkdir -p /root/.ncbi && \
    printf '/repository/user/main/public/root = "/data/sra"\n' \
    > /root/.ncbi/user-settings.mkfg

RUN mkdir -p /data/sra /data/fastq

WORKDIR /workspace
CMD ["/bin/bash"]
