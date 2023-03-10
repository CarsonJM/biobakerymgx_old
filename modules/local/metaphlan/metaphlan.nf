process METAPHLAN_METAPHLAN {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::metaphlan=4.0.6"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/metaphlan:4.0.6--pyhca03a8a_0':
        'quay.io/biocontainers/4.0.6--pyhca03a8a_0' }"

    input:
    tuple val(meta), path(reads)
    path metaphlan_db_index
    path metaphlan_db_dir
    val metaphlan_db_version

    output:
    tuple val(meta), path("*_profile.txt"), emit: metaphlan_profile
    tuple val(meta), path("*bowtie2.bz2"), emit: metaphlan_bt2
    tuple val(meta), path("*sam.bz2"), emit: metaphlan_sam
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    metaphlan \\
    ${prefix}_kneaddata_paired_1.fastq.gz,${prefix}_kneaddata_paired_2.fastq.gz \\
    --input_type fastq \\
    --bowtie2db ${metaphlan_db_dir} \\
    --index ${metaphlan_db_version} \\
    --bowtie2out ${prefix}.bowtie2.bz2 \\
    --output_file ${prefix}_profile.txt \\
    --samout ${prefix}.sam.bz2 \\
    --unclassified_estimation \\
    --nproc ${task.cpus} \\
    $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metaphlan: \$(echo \$(metaphlan --version 2>&1 | sed 's/^.*metaphlan //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
