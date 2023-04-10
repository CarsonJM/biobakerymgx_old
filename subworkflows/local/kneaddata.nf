include { SYMLINK_READS } from '../../modules/local/utils/symlinkreads'
include { MERGE_REPLICATES } from '../../modules/local/utils/mergereplicates'
include { KNEADDATA_DATABASE } from '../../modules/local/kneaddata/database'
include { KNEADDATA_KNEADDATA } from '../../modules/local/kneaddata/kneaddata'
include { KNEADDATA_READCOUNTS } from '../../modules/local/kneaddata/readcounts'
include { KNEADDATA_COMBINEREADCOUNTS } from '../../modules/local/kneaddata/combinereadcounts'

workflow KNEADDATA {

    take:
    ch_raw_reads // channel: [ val(meta), [ reads ] ]


    main:

    ch_versions = Channel.empty()

    //
    // MODULE: SYMLINK_READS
    //
    SYMLINK_READS ( ch_raw_reads )


    // short reads
    // group and set group as new id
    ch_raw_reads_grouped = SYMLINK_READS.out.symlinked_raw_reads
        .map { meta, reads -> [ meta.id, meta, reads ] }
        .groupTuple(by: 0)
        .map { id, metas, reads ->
                def meta = [:]
                meta.id          = id
                [ meta, reads.collect { it[0] }, reads.collect { it[1] } ]
        }

    //
    // MODULE: MERGE_REPLICATES
    //
    MERGE_REPLICATES ( ch_raw_reads_grouped )

    //
    // MODULE: KneadData database
    //
    KNEADDATA_DATABASE ()

    //
    // MODULE: KneadData
    //
    KNEADDATA_KNEADDATA ( 
        MERGE_REPLICATES.out.dereplicated_raw_reads ,
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
    preprocessed_reads = KNEADDATA_KNEADDATA.out.preprocessed_reads // channel: [ val(meta), [ reads ] ]

    versions = ch_versions // channel: [ versions.yml ]
}

