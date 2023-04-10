//
// Check input samplesheet and get read channels
//

def hasExtension(it, extension) {
    it.toString().toLowerCase().endsWith(extension.toLowerCase())
}

workflow INPUT_CHECK {
    main:
    if(hasExtension(params.input, "csv")){
        // extracts read files from samplesheet CSV and distribute into channels
        ch_input_rows = Channel
            .from(file(params.input))
            .splitCsv(header: true)
            .map { row ->
                    if (row.size() == 4) {
                        def id = row.sample
                        def rep = row.replicate
                        def r1 = row.R1 ? file(row.R1, checkIfExists: true) : false
                        def r2 = row.R2 ? file(row.R2, checkIfExists: true) : false
                        // Check if given combination is valid
                        if (!r1) exit 1, "Invalid input samplesheet: R1 can not be empty."
                        return [ id, rep, r1, r2 ]
                    } else {
                        exit 1, "Input samplesheet contains row with ${row.size()} column(s). Expects 4."
                    }
                }
        // separate short and long reads
        ch_raw_reads = ch_input_rows
            .map { id, rep, r1, r2 ->
                        def meta = [:]
                        meta.id           = id
                        meta.rep          = rep
                        return [ meta, [ r1, r2 ] ]
                }
    }

    emit:
    raw_reads = ch_raw_reads
}
