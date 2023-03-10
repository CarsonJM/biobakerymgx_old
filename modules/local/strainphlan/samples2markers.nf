process STRAINPHLAN_SAMPLES2MARKERS {
    tag "strainphlan_samples2markers"
    label 'process_high'

    conda "bioconda::metaphlan=4.0.6"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/metaphlan:4.0.6--pyhca03a8a_0':
        'quay.io/biocontainers/4.0.6--pyhca03a8a_0' }"

    input:
    path(sam)
    val metaphlan_db_version

    output:
    path("consensus_markers/*.pkl"), emit: consensus_markers
    path("consensus_markers"), emit: consensus_markers_dir
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    samples2markers.py \\
    --input ${sam} \\
    --input_format bz2 \\
    --output_dir consensus_markers \\
    --database ${metaphlan_db_version} \\
    --nprocs ${task.cpus} \\
    $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metaphlan: \$(echo \$(metaphlan --version 2>&1 | sed 's/^.*metaphlan //; s/Using.*\$//' ))
    END_VERSIONS
    """
}