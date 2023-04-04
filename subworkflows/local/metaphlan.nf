include { METAPHLAN_DATABASE } from '../../modules/local/metaphlan/database'
include { METAPHLAN_METAPHLAN } from '../../modules/local/metaphlan/metaphlan'
include { METAPHLAN_MERGETABLES } from '../../modules/local/metaphlan/mergetables'

workflow METAPHLAN {

    take:
    ch_preprocessed_reads // channel: [ val(meta), [ reads ] ]


    main:

    ch_versions = Channel.empty()

    //
    // MODULE: MetaPhlAn4 database
    //
    METAPHLAN_DATABASE ()

    //
    // MODULE: MetaPhlAn4
    //
    METAPHLAN_METAPHLAN ( 
        ch_preprocessed_reads ,
        METAPHLAN_DATABASE.out.metaphlan_db ,
    )

    //
    // MODULE: MetaPhlAn4 merge tables
    //
    METAPHLAN_MERGETABLES (
        METAPHLAN_METAPHLAN.out.metaphlan_profile.map{it -> it[1]}.collect()
    )

    ch_versions = ch_versions.mix(METAPHLAN_METAPHLAN.out.versions.first())

    emit:
    metaphlan_db = METAPHLAN_DATABASE.out.metaphlan_db
    metaphlan_profiles = METAPHLAN_METAPHLAN.out.metaphlan_profile
    metaphlan_sams = METAPHLAN_METAPHLAN.out.metaphlan_sam
    
    versions = ch_versions // channel: [ versions.yml ]
}

