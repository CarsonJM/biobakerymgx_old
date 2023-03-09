process METAPHLAN_MERGETABLES {
    tag "metaphlan_mergetables"
    label 'process_single'

    conda "bioconda::metaphlan=4.0.6"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/metaphlan:4.0.6--pyhca03a8a_0':
        'quay.io/biocontainers/4.0.6--pyhca03a8a_0' }"

    input:
    path(metaphlan_profiles)

    output:
    path "combined_metaphlan_profile.txt" , emit: combined_metaphlan_profile

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    merge_metaphlan_tables.py \\
    ${metaphlan_profiles} > combined_metaphlan_profile.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metaphlan: \$(echo \$(metaphlan --version 2>&1 | sed 's/^.*metaphlan //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
