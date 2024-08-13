/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SAMTOOLS_STATS } from '../../../modules/nf-core/samtools/stats/main'
include { SN_FILTER } from '../../../modules/local/grepStatsSN.nf'

/*
========================================================================================
    SUBWORKFLOW TO INITIALISE PIPELINE
========================================================================================
*/

workflow FILTER_STATS {
    take:
    bamInput

    main:
    ch_versions = Channel.empty();


    // TODO:  This needs to accept bam input which is multiple files (firststrand and second strand)

    referenceInput = tuple(params.genome, [])

    SAMTOOLS_STATS(bamInput, referenceInput)

    SN_FILTER(SAMTOOLS_STATS.out.stats)

    emit:
    versions = ch_versions
    stats = SN_FILTER.out.stats
    total = SN_FILTER.out.total_reads
}
