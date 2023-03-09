process METAPHLAN_DATABASE {
    tag 'metaphlan_database'
    label 'process_single'

    conda "bioconda::metaphlan=4.0.6"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/metaphlan:4.0.6--pyhca03a8a_0':
        'quay.io/biocontainers/4.0.6--pyhca03a8a_0' }"

    input:
    val metaphlan_db_version
    path database_dir

    output:
    path "metaphlan_database/*.bt2l" , emit: metaphlan_db_index
    path "metaphlan_database" , emit: metaphlan_db_dir
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    metaphlan \\
        --install \\
        --index ${params.metaphlan_db_version} \\
        --bowtie2db metaphlan_database

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metaphlan: \$(echo \$(metaphlan --version 2>&1 | sed 's/^.*metaphlan //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
