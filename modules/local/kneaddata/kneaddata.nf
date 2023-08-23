process KNEADDATA_KNEADDATA {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::kneaddata=0.12.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kneaddata:0.12.0--pyhdfd78af_1':
        'quay.io/biocontainers/kneaddata:0.12.0--pyhdfd78af_1' }"

    input:
    tuple val(meta), path(reads)
    path kneaddata_db

    output:
    tuple val(meta), path("*paired_{1,2}.fastq"), emit: preprocessed_reads
    tuple val(meta), path("*kneaddata.log"), emit: kneaddata_log
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    [ ! -f  ${prefix}_1.fastq.gz ] && ln -sf ${reads[0]} ${prefix}_1.fastq.gz
    [ ! -f  ${prefix}_2.fastq.gz ] && ln -sf ${reads[1]} ${prefix}_2.fastq.gz
    kneaddata \\
        --input1 ${prefix}_1.fastq.gz \\
        --input2 ${prefix}_2.fastq.gz \\
        --output . \\
        --output-prefix ${prefix}_kneaddata \\
        --reference-db $kneaddata_db \\
        --threads $task.cpus \\
        --trimmomatic $params.kneaddata_trimmomatic_path \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kneaddata: \$(echo \$(kneaddata --version 2>&1 | sed 's/^.*kneaddata //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
