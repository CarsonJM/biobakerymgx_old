process PANPHLAN_MAP {
    tag "$meta.id"
    label 'process_single'

    conda "bioconda::panphlan=4.0.6"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/panphlan:3.1--py_0':
        'quay.io/biocontainers/panphlan:3.1--py_0' }"

    input:
    tuple val(meta) , path(reads)
    val panphlan_species
    path panphlan_db_dir
    path panphlan_db

    output:
    tuple val(meta) , path("panphlan_output/${panphlan_species}_${prefix}.tsv") , emit: panphlan_map
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p panphlan_output
    panphlan_map.py \
        --input ${reads} \
        --indexes ${panphlan_db_dir}/${panphlan_species} \
        --pangenome ${panphlan_db} \
        --output panphlan_output/${panphlan_species}_${prefix}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metaphlan: \$(echo \$(metaphlan --version 2>&1 | sed 's/^.*metaphlan //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
