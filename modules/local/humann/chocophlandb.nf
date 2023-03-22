process HUMANN_CHOCOPHLANDB {
    tag 'humann_chocophlandb'
    label 'process_single'

    conda "bioconda::humann=3.6.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/humann:3.6.1--pyh7cba7a3_1':
        'quay.io/biocontainers/humann:3.6.1--pyh7cba7a3_1' }"

    input:
    path database_dir

    output:
    path "humann_databases/chocophlan/alaS.centroids.v201901_v31.ffn.gz" , emit: chocophlan_db
    path "humann_databases/chocophlan/" , emit: chocophlan_db_dir
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    mkdir -p humann_databases
    humann_databases \\
        --download chocophlan full \\
        humann_databases

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        humann: \$(echo \$(humann --version 2>&1 | sed 's/^.*humann //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
