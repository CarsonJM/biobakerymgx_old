process HUMANN_HUMANN {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::humann=3.6.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/humann:3.6.1--pyh7cba7a3_1':
        'quay.io/biocontainers/humann:3.6.1--pyh7cba7a3_1' }"

    input:
    tuple val(meta) , path(reads)
    tuple val(meta) , path(metaphlan_profile)
    path chocophlan_db
    path uniref_db

    output:
    tuple val(meta) , path("*_genefamilies.tsv") , emit: humann_genefamilies
    tuple val(meta) , path("*_pathabundance.tsv") , emit: humann_pathabundance
    tuple val(meta) , path("*_pathcoverage.tsv") , emit: humann_pathcoverage
    tuple val(meta) , path("*_humann.log") , emit: humann_log
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    humann \\
    --input $reads \\
    --output ./ \\
    --threads $task.cpus \\
    --taxonomic-profile $metaphlan_profile \\
    --input-format fastq.gz \\
    --nucleotide-database $chocophlan_db \\
    --protein-database $uniref_db \\
    --o-log ${prefix}_humann.log \\
    $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        humann: \$(echo \$(humann --version 2>&1 | sed 's/^.*humann //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
