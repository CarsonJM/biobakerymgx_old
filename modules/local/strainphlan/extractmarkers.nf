process STRAINPHLAN_EXTRACTMARKERS {
    tag "strainphlan_extract_markers"
    label 'process_high'

    conda "bioconda::metaphlan=4.0.6"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/metaphlan:4.0.6--pyhca03a8a_0':
        'quay.io/biocontainers/4.0.6--pyhca03a8a_0' }"

    input:
    path(consensus_markers_dir)
    path metaphlan_db_dir
    val params.strainphlan_species

    output:
    path("db_markers/*.fna"), emit: consensus_markers
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
