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
    HUMANN_CHOCOPHLANDB ( )

    //
    // MODULE: HUMAnN3 Uniref database
    //
    HUMANN_UNIREFDB ( )

    //
    // MODULE: HUMAnN3 utility mapping database
    //
    HUMANN_UTILITYMAPPINGDB ( )

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
        HUMANN_CHOCOPHLANDB.out.chocophlan_db ,
        HUMANN_UNIREFDB.out.uniref_db
    )

    //
    // MODULE: HUMAnN3 regroup
    //
    if ( params.regroup_gene_families ) {
        HUMANN_REGROUP (
            HUMANN_UTILITYMAPPINGDB.out.utilitymappingdb ,
            HUMANN_HUMANN.out.humann_genefamilies
        )
    
        HUMANN_REGROUPJOINTABLES (
            HUMANN_REGROUP.out.humann_regrouped.map{it -> it[1]}.collect() ,
            params.humann_regroup_option
        )

        if ( params.renorm_output ) {
            HUMANN_REGROUPRENORM (
                HUMANN_REGROUP.out.humann_regrouped ,
            )

            HUMANN_REGROUPRENORMJOINTABLES (
                HUMANN_REGROUPRENORM.out.humann_regrouped_renorm.map{it -> it[1]}.collect() ,
                "${params.humann_regroup_option}_${params.humann_renorm_option}"
            )
        }
    }

    //
    // MODULE: HUMAnN3 join tables
    //
    HUMANN_JOINTABLES (
        HUMANN_HUMANN.out.humann_genefamilies.map{it -> it[1]}.collect() ,
        HUMANN_HUMANN.out.humann_pathcoverage.map{it -> it[1]}.collect() ,
        HUMANN_HUMANN.out.humann_pathabundance.map{it -> it[1]}.collect() ,
        ""
    )

    if ( params.renorm_output ) {
            HUMANN_RENORM (
                HUMANN_HUMANN.out.humann_genefamilies ,
                HUMANN_HUMANN.out.humann_pathcoverage ,
                HUMANN_HUMANN.out.humann_pathabundance
            )

            HUMANN_RENORMJOINTABLES (
                HUMANN_RENORM.out.humann_genefamilies_renorm.map{it -> it[1]}.collect() ,
                HUMANN_RENORM.out.humann_pathcoverage_renorm.map{it -> it[1]}.collect() ,
                HUMANN_RENORM.out.humann_pathabundance_renorm.map{it -> it[1]}.collect() ,
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

