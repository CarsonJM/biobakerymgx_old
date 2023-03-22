process PANPHLAN_DOWNLOADPANGENOME {
    tag "download_pangenome"
    label 'process_single'

    conda "bioconda::panphlan=4.0.6"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '/gscratch/pedslabs/Labs/Hoffman/carsonjm/apptainer/panphlan.sif':
        '/gscratch/pedslabs/Labs/Hoffman/carsonjm/apptainer/panphlan.sif' }"

    input:
    val panphlan_species

    output:
    path "panphlan_databases/${panphlan_species}/${panphlan_species}_pangenome.tsv" , emit: panphlan_db
    path "panphlan_databases/${panphlan_species}" , emit: panphlan_db_dir
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    mkdir -p panphlan_databases
    panphlan_download_pangenome.py \
        --input_name ${panphlan_species} \
        --output panphlan_databases -v

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metaphlan: \$(echo \$(metaphlan --version 2>&1 | sed 's/^.*metaphlan //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
