process KNEADDATA_KNEADDATA {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::kneaddata=0.10.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kneaddata:0.10.0--pyhdfd78af_0':
        'quay.io/biocontainers/kneaddata:0.10.0--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(reads)
    path kneaddata_db_folder
    path kneaddata_db_index
    // path trimmomatic_path

    output:
    tuple val(meta), path("*.fastq.gz"), emit: reads
    tuple val(meta), path("*.log"), emit: log
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    [ ! -f  ${prefix}_1.fastq.gz ] && ln -sf ${reads[0]} ${prefix}_1.fastq.gz
    [ ! -f  ${prefix}_2.fastq.gz ] && ln -sf ${reads[1]} ${prefix}_2.fastq.gz
    kneaddata \\
        --input ${prefix}_1.fastq.gz \\
        --input ${prefix}_2.fastq.gz \\
        --output /home/carsonjm/resources/ \\
        --output-prefix ${prefix} \\
        --reference-db /home/carsonjm/resources/kneaddata/ \\
        --threads ${task.cpus} \\
        --trimmomatic /usr/local/share/trimmomatic-0.39-2 \\
        --bypass-trf \\
        $args

    gzip ./*.fastq.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kneaddata: \$(echo \$(kneaddata --version 2>&1) | sed 's/^.*kneaddata //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
