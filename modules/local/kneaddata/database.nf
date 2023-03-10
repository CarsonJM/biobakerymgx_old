process KNEADDATA_DATABASE {
    tag 'kneaddata_database'
    label 'process_single'

    conda "bioconda::kneaddata=0.10.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kneaddata:0.10.0--pyhdfd78af_0':
        'quay.io/biocontainers/kneaddata:0.10.0--pyhdfd78af_0' }"

    input:
    val kneaddata_db_type

    output:
    path "kneaddata_${params.kneaddata_db_type}/*.bt2" , emit: kneaddata_db_index
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    kneaddata_database \\
        --download  ${params.kneaddata_db_type} bowtie2 kneaddata_${params.kneaddata_db_type}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kneaddata: \$(echo \$(kneaddata --version 2>&1 | sed 's/^.*kneaddata //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
