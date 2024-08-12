/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SAMTOOLS_FILTER as SAMTOOLS_FILTER_UNIQUE  } from '../../../modules/local/samtoolsfilter.nf'
include { SAMTOOLS_FILTER as SAMTOOLS_FILTER_NU      } from '../../../modules/local/samtoolsfilter.nf'

// samtools stats + grep SN fields we watn to keep
include { FILTER_STATS                               } from '../filter_stats'
include { FILTER_STATS as FILTER_STATS_UNIQUE        } from '../filter_stats'
include { FILTER_STATS as FILTER_STATS_NU            } from '../filter_stats'
/*
========================================================================================
    SUBWORKFLOW TO INITIALISE PIPELINE
========================================================================================
*/

workflow SPLIT_BAM_STATS_AND_BED {
    take:
    bam

    main:

    ch_versions = Channel.empty();

    bamInput = bam.map{tuple(it[0], it[1], [])}

    FILTER_STATS(bamInput)

    SAMTOOLS_FILTER_UNIQUE(bamInput)
    FILTER_STATS_UNIQUE(SAMTOOLS_FILTER_UNIQUE.out.bam.map{tuple(it[0], it[1], [])})

    SAMTOOLS_FILTER_NU(bamInput)
    FILTER_STATS_NU(SAMTOOLS_FILTER_NU.out.bam.map{tuple(it[0], it[1], [])})

    // TODO:  add step to merge stats and calculate percent coverage

    // TODO:  add convert to bed



    emit:
    versions = ch_versions
}
