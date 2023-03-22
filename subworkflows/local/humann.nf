include { HUMANN_CHOCOPHLANDB } from '../../modules/local/humann/chocophlandb'
include { HUMANN_UNIREFDB } from '../../modules/local/humann/unirefdb'
include { HUMANN_UTILITYMAPPINGDB } from '../../modules/local/humann/utilitymappingdb'
include { HUMANN_MERGEREADS } from '../../modules/local/humann/mergereads'
include { HUMANN_HUMANN } from '../../modules/local/humann/humann'
include { HUMANN_REGROUP } from '../../modules/local/humann/regroup'
include { HUMANN_REGROUPJOINTABLES } from '../../modules/local/humann/regroupjointables'
include { HUMANN_REGROUPJOINTABLES as HUMANN_REGROUPRENORMJOINTABLES } from '../../modules/local/humann/regroupjointables'
include { HUMANN_REGROUPRENORM } from '../../modules/local/humann/regrouprenorm'
include { HUMANN_JOINTABLES } from '../../modules/local/humann/jointables'
include { HUMANN_RENORM } from '../../modules/local/humann/renorm'
include { HUMANN_JOINTABLES as HUMANN_RENORMJOINTABLES } from '../../modules/local/humann/jointables'

workflow HUMANN {

    take:
    ch_preprocessed_reads // channel: [ val(meta), [ reads ] ]
    ch_metaphlan_profile // channel: [ val(meta), [ metaphlan_profile ] ]

    main:

    ch_versions = Channel.empty()

    //
    // MODULE: HUMAnN3 chocophlan database
    //
    HUMANN_CHOCOPHLANDB (
        params.database_dir
    )
    ch_chocophlan_db = HUMANN_CHOCOPHLANDB.out.chocophlan_db
    ch_chocophlan_db_dir = HUMANN_CHOCOPHLANDB.out.chocophlan_db_dir

    //
    // MODULE: HUMAnN3 Uniref database
    //
    HUMANN_UNIREFDB (
        params.database_dir
    )
    ch_uniref_db = HUMANN_UNIREFDB.out.uniref_db
    ch_uniref_db_dir = HUMANN_UNIREFDB.out.uniref_db_dir

    //
    // MODULE: HUMAnN3 utility mapping database
    //
    HUMANN_UTILITYMAPPINGDB (
        params.database_dir
    )
    ch_utilitymapping_db = HUMANN_UTILITYMAPPINGDB.out.utilitymapping_db
    ch_utilitymapping_db_dir = HUMANN_UTILITYMAPPINGDB.out.utilitymapping_db_dir

    //
    // MODULE: HUMAnN3 merge reads
    //
    HUMANN_MERGEREADS (
        ch_preprocessed_reads
    )

    //
    // MODULE: HUMAnN3
    //
    HUMANN_HUMANN ( 
        HUMANN_MERGEREADS.out.merged_reads ,
        ch_metaphlan_profile ,
        ch_chocophlan_db , 
        ch_chocophlan_db_dir ,
        ch_uniref_db ,
        ch_uniref_db_dir
    )
    ch_combined_humann_genefamilies = HUMANN_HUMANN.out.humann_genefamilies.map{it -> it[1]}.collect()
    ch_combined_humann_pathcoverage = HUMANN_HUMANN.out.humann_pathcoverage.map{it -> it[1]}.collect()
    ch_combined_humann_pathabundance = HUMANN_HUMANN.out.humann_pathabundance.map{it -> it[1]}.collect()

    //
    // MODULE: HUMAnN3 regroup
    //
    if ( params.regroup_gene_families ) {
        HUMANN_REGROUP (
            ch_utilitymapping_db ,
            ch_utilitymapping_db_dir ,
            HUMANN_HUMANN.out.humann_genefamilies ,
            params.regroup_option
        )
        ch_combined_humann_regroup = HUMANN_REGROUP.out.humann_regrouped.map{it -> it[1]}.collect()
    
        HUMANN_REGROUPJOINTABLES (
            ch_combined_humann_regroup ,
            params.regroup_option
        )

        if ( params.renorm_output ) {
            HUMANN_REGROUPRENORM (
                HUMANN_REGROUP.out.humann_regrouped ,
                params.renorm_option
            )
            ch_combined_humann_regroup_renorm = HUMANN_REGROUPRENORM.out.humann_regrouped_renorm.map{it -> it[1]}.collect()

            HUMANN_REGROUPRENORMJOINTABLES (
                ch_combined_humann_regroup_renorm ,
                "${params.regroup_option}_${params.renorm_option}"
            )
        }
    }

    //
    // MODULE: HUMAnN3 join tables
    //
    HUMANN_JOINTABLES (
        ch_combined_humann_genefamilies ,
        ch_combined_humann_pathcoverage ,
        ch_combined_humann_pathabundance ,
        ""
    )

    if ( params.renorm_output ) {
            HUMANN_RENORM (
                HUMANN_HUMANN.out.humann_genefamilies ,
                HUMANN_HUMANN.out.humann_pathcoverage ,
                HUMANN_HUMANN.out.humann_pathabundance ,
                params.renorm_option
            )
            ch_combined_humann_genefamilies_renorm = HUMANN_RENORM.out.humann_genefamilies_renorm.map{it -> it[1]}.collect()
            ch_combined_humann_pathcoverage_renorm = HUMANN_RENORM.out.humann_pathcoverage_renorm.map{it -> it[1]}.collect()
            ch_combined_humann_pathabundance_renorm = HUMANN_RENORM.out.humann_pathabundance_renorm.map{it -> it[1]}.collect()

            HUMANN_RENORMJOINTABLES (
                ch_combined_humann_genefamilies_renorm ,
                ch_combined_humann_pathcoverage_renorm ,
                ch_combined_humann_pathabundance_renorm ,
                "_${params.renorm_option}"
            )
        }

    ch_versions = ch_versions.mix(HUMANN_HUMANN.out.versions.first())

    emit:
    merged_reads = HUMANN_MERGEREADS.out.merged_reads
    // humann_combined_genefamilies = HUMANN_JOINTABLES.out.humann_combined_genefamilies
    // humann_combined_pathabundance = HUMANN_JOINTABLES.out.humann_combined_pathabundance
    // humann_combined_pathcoverage = HUMANN_JOINTABLES.out.humann_combined_pathcoverage

    versions = ch_versions // channel: [ versions.yml ]
}

