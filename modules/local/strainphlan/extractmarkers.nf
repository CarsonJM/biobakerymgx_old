process STRAINPHLAN_EXTRACTMARKERS {
    tag "strainphlan_extract_markers"
    label 'process_high'

    conda "bioconda::metaphlan=4.0.6"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/metaphlan:4.0.6--pyhca03a8a_0':
        'quay.io/biocontainers/4.0.6--pyhca03a8a_0' }"

    input:
    path metaphlan_db_index
    path metaphlan_db_dir

    output:
    path("db_markers/*.fna"), emit: db_markers
    path("db_markers/"), emit: db_markers_dir
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    mkdir -p db_markers
    extract_markers.py \\
    --clades ${params.strainphlan_species} \\
    --database ${metaphlan_db_dir}/${params.metaphlan_db_version}.pkl \\
    --output_dir db_markers \\


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metaphlan: \$(echo \$(metaphlan --version 2>&1 | sed 's/^.*metaphlan //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
