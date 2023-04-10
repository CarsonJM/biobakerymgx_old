process HUMANN_JOINTABLES {
    tag "humann_join_tables"
    label 'process_single'

    conda "bioconda::humann=3.6.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/humann:3.6.1--pyh7cba7a3_1':
        'quay.io/biocontainers/humann:3.6.1--pyh7cba7a3_1' }"

    input:
    path(humann_genefamilies)
    path(humann_pathabundance)
    path(humann_pathcoverage)

    output:
    path("combined_genefamilies${renorm}.tsv") , emit: humann_combined_genefamilies
    path("combined_pathabundance${renorm}.tsv") , emit: humann_combined_pathabundance
    path("combined_pathcoverage${renorm}.tsv") , emit: humann_combined_pathcoverage
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    humann_join_tables \\
    --input ./ \\
    --output combined_genefamilies${params.humann_renorm_option}.tsv \\
    --file_name genefamilies

    humann_join_tables \\
    --input ./ \\
    --output combined_pathabundance${params.humann_renorm_option}.tsv \\
    --file_name pathabundance

    humann_join_tables \\
    --input ./ \\
    --output combined_pathcoverage${params.humann_renorm_option}.tsv \\
    --file_name pathcoverage

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        humann: \$(echo \$(humann --version 2>&1 | sed 's/^.*humann //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
