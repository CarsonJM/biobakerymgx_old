process HUMANN_REGROUP {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::humann=3.6.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/humann:3.6.1--pyh7cba7a3_1':
        'quay.io/biocontainers/humann:3.6.1--pyh7cba7a3_1' }"

    input:
    path utilitymapping_db
    tuple val(meta) , path(humann_genefamilies)

    output:
    tuple val(meta) , path("*${params.humann_regroup_option}.tsv") , emit: humann_regrouped
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    humann_regroup_table \\
    --input ${humann_genefamilies} \\
    --output ${prefix}_${params.humann_regroup_option}.tsv \\
    --custom ${utilitymapping_db}/${params.humann_regroup_option}.txt.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        humann: \$(echo \$(humann --version 2>&1 | sed 's/^.*humann //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
