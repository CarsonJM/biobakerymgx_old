include { METAPHLAN_DATABASE } from '../../modules/local/metaphlan/database'
include { METAPHLAN_METAPHLAN } from '../../modules/local/metaphlan/metaphlan'
include { METAPHLAN_MERGETABLES } from '../../modules/local/metaphlan/mergetables'

workflow METAPHLAN {

    take:
    ch_preprocessed_short_reads // channel: [ val(meta), [ reads ] ]


    main:

    ch_versions = Channel.empty()

    //
    // MODULE: MetaPhlAn4 database
    //
    // If download_metaphlan_db == False, use metaphlan db specified in resources directory
    if ( !params.download_metaphlan_db ) {
        ch_metaphlan_db_index = file("${params.database_dir}/${params.metaphlan_db_version}*.bt2l")
    }
    // If download_metaphlan_db == True, download specified metaphlan db into resources directory
    else {
        METAPHLAN_DATABASE (
            params.metaphlan_db_version
        )
        ch_metaphlan_db_index = METAPHLAN_DATABASE.out.metaphlan_db_index
    }
    ch_metaphlan_db_dir = file("${params.database_dir}/${params.metaphlan_db_version}")

    //
    // MODULE: MetaPhlAn4
    //
    // If run_metaphlan == True, run MetaPhlAn4 and merge tables
    if ( params.run_metaphlan ) {
        METAPHLAN_METAPHLAN ( 
            ch_preprocessed_short_reads ,
            ch_metaphlan_db_index , 
            ch_metaphlan_db_dir ,
            params.metaphlan_db_version
        )

        //
        // MODULE: MetaPhlAn4 merge tables
        //
        METAPHLAN_MERGETABLES (
            METAPHLAN_METAPHLAN.out.metaphlan_profile.map{it -> it[1]}.collect()
        )
    }

    ch_versions = ch_versions.mix(METAPHLAN_METAPHLAN.out.versions.first())

    emit:
    metaphlan_db_index = ch_metaphlan_db_index
    metaphlan_profiles = METAPHLAN_METAPHLAN.out.metaphlan_profile
    metaphlan_sams = METAPHLAN_METAPHLAN.out.metaphlan_sam
    combined_metaphlan_profile = METAPHLAN_MERGETABLES.out.combined_metaphlan_profile
    
    versions = ch_versions // channel: [ versions.yml ]
}

