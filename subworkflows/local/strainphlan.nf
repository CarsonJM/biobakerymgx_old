include { STRAINPHLAN_EXTRACTMARKERS } from '../../modules/local/strainphlan/extractmarkers'
include { STRAINPHLAN_SAMPLE2MARKERS } from '../../modules/local/strainphlan/sample2markers'
include { STRAINPHLAN_REFERENCES } from '../../modules/local/strainphlan/references'
include { STRAINPHLAN_STRAINPHLAN } from '../../modules/local/strainphlan/strainphlan'

workflow STRAINPHLAN {

    take:
    ch_metaphlan_sam // channel: [ val(meta), [ sam ] ]
    ch_metaphlan_db

    main:

    ch_versions = Channel.empty()

    // MODULE: SAMPLES2MARKERS
    STRAINPHLAN_SAMPLE2MARKERS (
        ch_metaphlan_sam ,
        ch_metaphlan_db
    )

    // MODULE: EXTRACTMARKERS
    STRAINPHLAN_EXTRACTMARKERS (
        ch_metaphlan_db
    )

    // MODULE: EXTRACTMARKERS
    if (params.strainphlan_references) {
        STRAINPHLAN_REFERENCES ( )
    }


    // MODULE: STRAINPHLAN
    STRAINPHLAN_STRAINPHLAN ( 
        ch_metaphlan_db ,
        STRAINPHLAN_SAMPLE2MARKERS.out.consensus_markers.map{it -> it[1]}.collect() ,
        STRAINPHLAN_EXTRACTMARKERS.out.db_markers ,
        STRAINPHLAN_REFERENCES.out.reference_genomes
    )

    ch_versions = ch_versions.mix(STRAINPHLAN_STRAINPHLAN.out.versions.first())

    emit:
    metaphlan_profiles = STRAINPHLAN_STRAINPHLAN.out.strainphlan_outputs
    
    versions = ch_versions // channel: [ versions.yml ]
}

