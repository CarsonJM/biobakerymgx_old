include { STRAINPHLAN_EXTRACTMARKERS } from '../../modules/local/strainphlan/extractmarkers'
include { STRAINPHLAN_SAMPLE2MARKERS } from '../../modules/local/strainphlan/sample2markers'
include { STRAINPHLAN_STRAINPHLAN } from '../../modules/local/strainphlan/strainphlan'

workflow STRAINPHLAN {

    take:
    ch_metaphlan_sam // channel: [ val(meta), [ sam ] ]
    ch_metaphlan_db_index


    main:

    ch_versions = Channel.empty()

    // If run_strainphlan == True, run StrainPhlAn4
    ch_metaphlan_db_dir = file("${params.database_dir}/${params.metaphlan_db_version}")
    if ( params.run_strainphlan ) {

        // MODULE: SAMPLES2MARKERS
        STRAINPHLAN_SAMPLE2MARKERS (
            ch_metaphlan_sam ,
            ch_metaphlan_db_index ,
            ch_metaphlan_db_dir
        )

        // MODULE: EXTRACTMARKERS
        STRAINPHLAN_EXTRACTMARKERS ( 
            ch_metaphlan_db_index ,
            ch_metaphlan_db_dir
        )


        // MODULE: STRAINPHLAN
        STRAINPHLAN_STRAINPHLAN ( 
            ch_metaphlan_db_index ,
            ch_metaphlan_db_dir ,
            STRAINPHLAN_SAMPLE2MARKERS.out.consensus_markers.map{it -> it[1]}.collect() ,
            STRAINPHLAN_SAMPLE2MARKERS.out.consensus_markers_dir ,
            STRAINPHLAN_EXTRACTMARKERS.out.db_markers_dir
        )
    }

    ch_versions = ch_versions.mix(STRAINPHLAN_STRAINPHLAN.out.versions.first())

    emit:
    metaphlan_profiles = STRAINPHLAN_STRAINPHLAN.out.strainphlan_outputs
    
    versions = ch_versions // channel: [ versions.yml ]
}

