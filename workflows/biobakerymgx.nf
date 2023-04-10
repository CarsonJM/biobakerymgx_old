/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowBiobakerymgx.initialise(params, log)

// TODO nf-core: Add all file path parameters for the pipeline to the list below
// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.multiqc_config, params.fasta ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULES: Consisting of local modules
//
include { HUMANN_MERGEREADS } from '../modules/local/humann/mergereads.nf'

//
// SUBWORKFLOWS Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK } from '../subworkflows/local/input_check'
include { KNEADDATA } from '../subworkflows/local/kneaddata'
include { METAPHLAN } from '../subworkflows/local/metaphlan'
// include { HUMANN } from '../subworkflows/local/humann'
include { STRAINPHLAN } from '../subworkflows/local/strainphlan'
// include { PANPHLAN } from '../subworkflows/local/panphlan'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULES: Installed directly from nf-core/modules
//
include { MULTIQC                     } from '../modules/nf-core/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow BIOBAKERYMGX {

    // To Do List:
    // TODO: add module to merge replicate reads

    ch_versions = Channel.empty()

    //
    // SUBWORKFLOW: INPUT_CHECK 
    //
    // Check to make sure that all inputs are correct
    INPUT_CHECK ()
    ch_raw_reads = INPUT_CHECK.out.raw_reads

    

    //
    // SUBWORKFLOW: KneadData
    //
    // Trim, quality filter, and remove contaminant reads
    if ( params.run_kneaddata ) {
        KNEADDATA (
            ch_raw_reads
        )
        ch_preprocessed_reads = KNEADDATA.out.preprocessed_reads
    }
    else {
        ch_preprocessed_reads = INPUT_CHECK.out.raw_reads
    }

    //
    // SUBWORKFLOW: MetaPhlAn4
    //
    // Get taxonomic profile of reads
    if ( params.run_metaphlan || params.run_humann || params.run_strainphlan ) {
        METAPHLAN (
            ch_preprocessed_reads
        )
    }

    // //
    // // SUBWORKFLOW: HUMAnN3
    // //
    // if ( params.run_humann ) {
    //     HUMANN (
    //         ch_preprocessed_reads ,
    //         METAPHLAN.out.metaphlan_profiles
    //     )
    //     ch_merged_reads = HUMANN.out.merged_reads
    // }
    else {
        HUMANN_MERGEREADS ( ch_preprocessed_reads )
        ch_merged_reads = HUMANN_MERGEREADS.out.merged_reads
    }



    //
    // SUBWORKFLOW: StrainPhlAn4
    //
    // Get strain profile
    if ( params.run_strainphlan ) {
        STRAINPHLAN (
            METAPHLAN.out.metaphlan_sams ,
            METAPHLAN.out.metaphlan_db
        )
    }


    //
    // SUBWORKFLOW: PanPhlAn3
    //
    // Get gene profile
    // PANPHLAN (
    //     ch_merged_reads ,
        
    // )

    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    // TODO: Change test dataset to MetaPhlan's
    // TODO: Add samples2markers module
    // TODO: Add extract_markers module
    // TODO: Add strainphlan module
    // TODO: Add strainphlan subworkflow
    // TODO: Modify conf/modules.config to publish strainphlan output
    // TODO: Add panphlan_map module
    // TODO: Add panphlan_profiling module
    // TODO: Add panphlan subworkflow
    // TODO: Modify conf/modules.config to publish panphlan output
    // TODO: Add extra arguments for KneadData
    // TODO: Add extra arguments for MetaPhlAn
    // TODO: Add extra arguments for HUMAnN
    // TODO: Add extra arguments for StrainPhlAn
    // TODO: Add extra arguments for PanPhlAn
    // TODO: Enable Strainphlan and Panphlan to accept multiple species


    //
    // MODULE: MultiQC
    //
    workflow_summary    = WorkflowBiobakerymgx.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    methods_description    = WorkflowBiobakerymgx.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description)
    ch_methods_description = Channel.value(methods_description)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )
    multiqc_report = MULTIQC.out.report.toList()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
