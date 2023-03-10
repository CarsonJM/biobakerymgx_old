process HUMANN_JOINTABLES {
    tag "$meta.id"
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
    path("combined_genefamilies.tsv") , emit: humann_combined_genefamilies
    path("combined_pathabundance.tsv") , emit: humann_combined_pathabundance
    path("combined_pathcoverage.tsv") , emit: humann_combined_pathcoverage
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    for file in ${humann_genefamilies}; do ln -s .; done
    humann_join_tables \\
    --input ./ \\
    --output combined_genefamilies.tsv \\
    --filename genefamilies.tsv

    for file in ${humann_pathabundance}; do ln -s .; done
    humann_join_tables \\
    --input ./ \\
    --output combined_pathabundance.tsv \\
    --filename pathabundance.tsv

    for file in ${humann_pathcoverage}; do ln -s .; done
    humann_join_tables \\
    --input ./ \\
    --output combined_pathcoverage.tsv \\
    --filename pathcoverage.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        humann: \$(echo \$(humann --version 2>&1 | sed 's/^.*humann //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
