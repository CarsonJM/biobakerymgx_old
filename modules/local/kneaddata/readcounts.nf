process KNEADDATA_READCOUNTS {
    label 'process_single'

    conda "bioconda::kneaddata=0.12.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kneaddata:0.12.0--pyhdfd78af_1':
        'quay.io/biocontainers/kneaddata:0.12.0--pyhdfd78af_1' }"

    input:
    path(kneaddata_log)

    output:
    path("kneaddata_read_count_table.tsv") , emit: kneaddata_read_count_table

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    kneaddata_read_count_table \\
        --input ./ \\
        --output kneaddata_read_count_table.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kneaddata: \$(echo \$(kneaddata --version 2>&1 | sed 's/^.*kneaddata //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
