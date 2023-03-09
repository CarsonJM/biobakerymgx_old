process KNEADDATA_COMBINEREADCOUNTS {
    tag '$kneaddata_combine_read_counts'
    label 'process_single'

    conda "bioconda::kneaddata=0.10.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kneaddata:0.10.0--pyhdfd78af_0':
        'quay.io/biocontainers/kneaddata:0.10.0--pyhdfd78af_0' }"

    input:
    path(kneaddata_read_count_table)

    output:
    path "combined_read_count_table.tsv" , emit: kneaddata_combined_read_count_table

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    awk 'FNR>1 || NR==1' ${kneaddata_read_count_table} > combined_read_count_table.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kneaddata: \$(echo \$(kneaddata --version 2>&1 | sed 's/^.*kneaddata //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
