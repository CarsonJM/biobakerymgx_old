process HUMANN_REGROUPJOINTABLES {
    tag "humann_join_tables"
    label 'process_single'

    conda "bioconda::humann=3.6.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/humann:3.6.1--pyh7cba7a3_1':
        'quay.io/biocontainers/humann:3.6.1--pyh7cba7a3_1' }"

    input:
    path(ombined_humann_regroup)
    val regroup_option

    output:
    path("combined_${regroup_option}.tsv") , emit: humann_combined_regroup
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    humann_join_tables \\
    --input ./ \\
    --output combined_${regroup_option}.tsv \\
    --file_name ${regroup_option}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        humann: \$(echo \$(humann --version 2>&1 | sed 's/^.*humann //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
