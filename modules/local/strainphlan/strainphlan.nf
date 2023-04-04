process STRAINPHLAN_STRAINPHLAN {
    tag "strainphlan"
    label 'process_high'

    conda "bioconda::metaphlan=4.0.6"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/metaphlan:4.0.6--pyhca03a8a_0':
        'quay.io/biocontainers/4.0.6--pyhca03a8a_0' }"

    input:
    path metaphlan_db
    path consensus_markers
    path db_markers

    output:
    path("*"), emit: strainphlan_outputs
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    mkdir -p ${params.strainphlan_species}_output
    strainphlan \\
    --database $metaphlan_db \\
    --samples $consensus_markers \\
    --clade_markers $db_markers/${params.strainphlan_species}.fna \\
    --output_dir ${params.strainphlan_species}_output \\
    --nprocs $task.cpus \\
    --clade $params.strainphlan_species \\
    $args


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metaphlan: \$(echo \$(metaphlan --version 2>&1 | sed 's/^.*metaphlan //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
