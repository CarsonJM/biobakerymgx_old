process SYMLINK_READS {
    tag "$meta.id"
    label 'process_single'

    conda "bioconda::kneaddata=0.10.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kneaddata:0.10.0--pyhdfd78af_0':
        'quay.io/biocontainers/kneaddata:0.10.0--pyhdfd78af_0' }"

    input:
    tuple val(meta) , path(raw_reads)

    output:
    tuple val(meta) , path("*_linked_*.fastq.gz") , emit: symlinked_raw_reads
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "$meta.id"
    def replicate = task.ext.replicate ?: "$meta.rep"
    """
    [ ! -f  ${prefix}_${replicate}_linked_1.fastq.gz ] && ln -sf ${raw_reads[0]} ${prefix}_${replicate}_linked_1.fastq.gz
    [ ! -f  ${prefix}_${replicate}_linked_2.fastq.gz ] && ln -sf ${raw_reads[1]} ${prefix}_${replicate}_linked_2.fastq.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ln: \$(echo \$(ln --version 2>&1 | sed 's/^.*ln //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
