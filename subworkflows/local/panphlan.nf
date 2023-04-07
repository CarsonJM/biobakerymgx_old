include { PANPHLAN_DOWNLOADPANGENOME } from '../../modules/local/panphlan/downloadpangenome'
include { PANPHLAN_MAP } from '../../modules/local/panphlan/map'
include { PANPHLAN_PROFILE } from '../../modules/local/panphlan/profile'

workflow PANPHLAN {

    take:
    ch_merged_reads // channel: [ val(meta), [ reads ] ]


    main:
    // TODO: Reformat to match other modules

    ch_versions = Channel.empty()

    //
    // MODULE: PanPhlAn3 downloadpangenome
    //
    PANPHLAN_DOWNLOADPANGENOME (
        params.panphlan_species
    )
    ch_panphlan_db = PANPHLAN_DOWNLOADPANGENOME.out.panphlan_db
    ch_panphlan_db_dir = PANPHLAN_DOWNLOADPANGENOME.out.panphlan_db_dir

    //
    // MODULE: PanPhlAn3 map
    //
    if ( params.run_panphlan ) {
        PANPHLAN_MAP ( 
            ch_merged_reads ,
            params.panphlan_species ,
            ch_panphlan_db_dir ,
            ch_panphlan_db
        )

        //
        // MODULE: PanPhlAn3 profile
        //
        PANPHLAN_PROFILE (
            params.panphlan_species ,
            ch_panphlan_db ,
            PANPHLAN_MAP.out.panphlan_map
        )
    }

    ch_versions = ch_versions.mix(PANPHLAN_PROFILE.out.versions.first())

    emit:
    panphlan_profile = PANPHLAN_PROFILE.out.panphlan_profile

    versions = ch_versions // channel: [ versions.yml ]
}

