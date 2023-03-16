process HUMANN_RENORM {
    tag "humann_renorm"
    label 'process_low'

    conda "bioconda::humann=3.6.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/humann:3.6.1--pyh7cba7a3_1':
        'quay.io/biocontainers/humann:3.6.1--pyh7cba7a3_1' }"

    input:
    tuple val(meta), path(humann_genefamilies)
    tuple val(meta), path(humann_pathcoverage)
    tuple val(meta), path(humann_pathabundance)
    val renorm_option

    output:
    tuple val(meta) , path("*genefamilies_${renorm_option}.tsv") , emit: humann_genefamilies_renorm
    tuple val(meta) , path("*pathcoverage_${renorm_option}.tsv") , emit: humann_pathcoverage_renorm
    tuple val(meta) , path("*pathabundance_${renorm_option}.tsv") , emit: humann_pathabundance_renorm
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    humann_renorm_table \\
    --input ${humann_genefamilies} \\
    --output ${prefix}_genefamilies_${renorm_option}.tsv \\
    --units ${renorm_option} \\
    --special n

    humann_renorm_table \\
    --input ${humann_pathcoverage} \\
    --output ${prefix}_pathcoverage_${renorm_option}.tsv \\
    --units ${renorm_option} \\
    --special n

    humann_renorm_table \\
    --input ${humann_pathabundance} \\
    --output ${prefix}_pathabundance_${renorm_option}.tsv \\
    --units ${renorm_option} \\
    --special n

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        humann: \$(echo \$(humann --version 2>&1 | sed 's/^.*humann //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
