include { KNEADDATA_DATABASE } from '../../modules/local/kneaddata/database'
include { KNEADDATA_KNEADDATA } from '../../modules/local/kneaddata/kneaddata'
include { KNEADDATA_READCOUNTS } from '../../modules/local/kneaddata/readcounts'
include { KNEADDATA_COMBINEREADCOUNTS } from '../../modules/local/kneaddata/combinereadcounts'

workflow KNEADDATA {

    take:
    ch_raw_short_reads // channel: [ val(meta), [ reads ] ]


    main:

    ch_versions = Channel.empty()

    //
    // MODULE: KneadData database
    //
    KNEADDATA_DATABASE ()

    //
    // MODULE: KneadData
    //
    KNEADDATA_KNEADDATA ( 
        ch_raw_short_reads ,
        KNEADDATA_DATABASE.out.kneaddata_db
    )

    //
    // MODULE: KneadData read counts
    //
    KNEADDATA_READCOUNTS (
        KNEADDATA_KNEADDATA.out.kneaddata_log
    )

    //
    // MODULE: KneadData combine read counts
    //
    KNEADDATA_COMBINEREADCOUNTS (
        KNEADDATA_READCOUNTS.out.kneaddata_read_count_table.map{it -> it[1]}.collect()
    )

    ch_versions = ch_versions.mix(KNEADDATA_KNEADDATA.out.versions.first())

    emit:
    reads = KNEADDATA_KNEADDATA.out.reads // channel: [ val(meta), [ reads ] ]

    versions = ch_versions // channel: [ versions.yml ]
}

