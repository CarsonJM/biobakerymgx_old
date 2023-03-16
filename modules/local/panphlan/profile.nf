process PANPHLAN_PROFILE {
    tag "panphlan_profile"
    label 'process_high'

    conda "bioconda::panphlan=4.0.6"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/panphlan:3.1--py_0':
        'quay.io/biocontainers/panphlan:3.1--py_0' }"

    input:
    val panphlan_species
    path panphlan_db
    path panphlan_map

    output:
    path "${panphlan_species}_profile.tsv" , emit: panphlan_profile
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    panphlan_profiling.py \\
        --i_dna panphlan_output \\
        --o_matrix ${panphlan_species} \\
        --pangenome ${panphlan_db}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metaphlan: \$(echo \$(metaphlan --version 2>&1 | sed 's/^.*metaphlan //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
