process MERGE_REPLICATES {
    tag "$meta.id"
    label 'process_single'

    conda "bioconda::kneaddata=0.10.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kneaddata:0.10.0--pyhdfd78af_0':
        'quay.io/biocontainers/kneaddata:0.10.0--pyhdfd78af_0' }"

    input:
    tuple val(meta) , path(raw_reads_grouped_1) , path(raw_reads_grouped_2)

    output:
    tuple val(meta) , path("*_derep_*.fastq.gz") , emit: dereplicated_raw_reads
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "$meta.id"
    def group = task.ext.prefix ?: "$meta.group"
    """
    cat $raw_reads_grouped_1 > ${prefix}_derep_1.fastq.gz
    cat $raw_reads_grouped_2 > ${prefix}_derep_2.fastq.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cat: \$(echo \$(cat --version 2>&1 | sed 's/^.*cat //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
