process HUMANN_REGROUPRENORM {
    tag "humann_regroup_renorm"
    label 'process_low'

    conda "bioconda::humann=3.6.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/humann:3.6.1--pyh7cba7a3_1':
        'quay.io/biocontainers/humann:3.6.1--pyh7cba7a3_1' }"

    input:
    tuple val(meta), path(humann_regroup)
    val renorm_option

    output:
    tuple val(meta) , path("*${renorm_option}.tsv") , emit: humann_regrouped_renorm
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    humann_renorm_table \\
    --input ${humann_regroup} \\
    --output ${prefix}_${params.regroup_option}_${renorm_option}.tsv \\
    --units ${renorm_option} \\
    --special n

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        humann: \$(echo \$(humann --version 2>&1 | sed 's/^.*humann //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
