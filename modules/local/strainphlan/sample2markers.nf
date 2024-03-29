process STRAINPHLAN_SAMPLE2MARKERS {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::metaphlan=4.0.6"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/metaphlan:4.0.6--pyhca03a8a_0':
        'quay.io/biocontainers/4.0.6--pyhca03a8a_0' }"

    input:
    tuple val(meta), path(metaphlan_sam)
    path metaphlan_db

    output:
    tuple val(meta), path("*.pkl"), emit: consensus_markers
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p consensus_markers
    sample2markers.py \\
    --input $metaphlan_sam \\
    --input_format bz2 \\
    --output_dir ./ \\
    --database $metaphlan_db \\
    --nprocs $task.cpus \\
    $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metaphlan: \$(echo \$(metaphlan --version 2>&1 | sed 's/^.*metaphlan //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
