process KNEADDATA_READCOUNTS {
    tag '$kneaddata_read_count_table'
    label 'process_single'

    conda "bioconda::kneaddata=0.10.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kneaddata:0.10.0--pyhdfd78af_0':
        'quay.io/biocontainers/kneaddata:0.10.0--pyhdfd78af_0' }"

    input:
    tuple val(meta) , path(kneaddata_log)

    output:
    tuple val(meta) , path("*_read_count_table.tsv") , emit: kneaddata_read_count_table

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    kneaddata_read_count_table \\
        --input ./ \\
        --output ${prefix}_read_count_table.tsv

    sed -i '2d' ${prefix}_read_count_table.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kneaddata: \$(echo \$(kneaddata --version 2>&1 | sed 's/^.*kneaddata //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
