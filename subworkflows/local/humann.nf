include { HUMANN_CHOCOPHLANDB } from '../../modules/local/humann/chocophlandb'
include { HUMANN_UNIREFDB } from '../../modules/local/humann/unirefdb'
include { HUMANN_UTILITYMAPPINGDB } from '../../modules/local/humann/utilitymappingdb'
include { HUMANN_MERGEPAIRS } from '../../modules/local/humann/mergepairs'
include { HUMANN_HUMANN } from '../../modules/local/humann/humann'
include { HUMANN_JOINTABLES } from '../../modules/local/humann/jointables'

workflow HUMANN {

    take:
    ch_preprocessed_short_reads // channel: [ val(meta), [ reads ] ]
    ch_metaphlan_profile // channel: [ val(meta), [ metaphlan_profile ] ]

    main:

    ch_versions = Channel.empty()

    //
    // MODULE: HUMAnN3 chocophlan database
    //
    // If download_chocophlan_db == False, use chocophlan db specified in resources directory
    if ( !params.download_chocophlan_db ) {
        ch_chocophlan_db = file("${params.database_dir}/humann_databases/chocophlan/alaS.centroids.v201901_v31.ffn.gz")
    }
    // If download_chocophlan_db == True, download chocophlan db into resources directory
    else {
        HUMANN_CHOCOPHLANDB (
            params.database_dir
        )
        ch_chocophlan_db = HUMANN_CHOCOPHLANDB.out.chocophlan_db
    }
    ch_chocophlan_db_dir = file("${params.database_dir}/humann_databases/chocophlan/")
    
    // If download_uniref_db == True, download uniref db into resources directory
    if ( !params.download_uniref_db ) {
        ch_uniref_db = file("${params.database_dir}/humann_databases/uniref/uniref90_201901b_full.dmnd")
    }
    else {
        HUMANN_UNIREFDB (
            params.database_dir
        )
        ch_uniref_db = HUMANN_UNIREFDB.out.uniref_db
    }
    ch_uniref_db_dir = file("${params.database_dir}/humann_databases/uniref")

    // If download_utilitymapping_db == True, download utilitymapping db into resources directory
    if ( !params.download_utilitymapping_db ) {
        ch_utilitymapping_db = file("${params.database_dir}/humann_databases/utilitymapping/map_ec_name.txt.gz")
    }
    else {
        HUMANN_UTILITYMAPPINGDB (
            params.database_dir
        )
        ch_utilitymapping_db = HUMANN_UTILITYMAPPINGDB.out.utilitymapping_db
    }
    ch_utilitymapping_db_dir = file("${params.database_dir}/humann_databases/utilitymapping")

    //
    // MODULE: HUMAnN3
    //
    // If run_humann == True, run HUMAnN3 and join tables
    if ( params.run_humann ) {
        HUMANN_MERGEPAIRS (
            ch_preprocessed_short_reads
        )

        HUMANN_HUMANN ( 
            HUMANN_MERGEPAIRS.out.reads ,
            ch_metaphlan_profile ,
            ch_chocophlan_db , 
            ch_chocophlan_db_dir ,
            ch_uniref_db ,
            ch_uniref_db_dir ,
            ch_utilitymapping_db ,
            ch_utilitymapping_db_dir
        )

        //
        // MODULE: HUMAnN3 join tables
        //
        HUMANN_JOINTABLES (
            HUMANN_HUMANN.out.humann_genefamilies.map{it -> it[1]}.collect() ,
            HUMANN_HUMANN.out.humann_pathabundance.map{it -> it[1]}.collect() ,
            HUMANN_HUMANN.out.humann_pathcoverage.map{it -> it[1]}.collect()
        )
    }

    ch_versions = ch_versions.mix(HUMANN_HUMANN.out.versions.first())

    emit:
    merged_reads = HUMANN_MERGEPAIRS.out.reads
    humann_combined_genefamilies = HUMANN_JOINTABLES.out.humann_combined_genefamilies
    humann_combined_pathabundance = HUMANN_JOINTABLES.out.humann_combined_pathabundance
    humann_combined_pathcoverage = HUMANN_JOINTABLES.out.humann_combined_pathcoverage

    versions = ch_versions // channel: [ versions.yml ]
}

