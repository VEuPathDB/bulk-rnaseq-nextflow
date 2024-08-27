/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SAMTOOLS_FILTER as SAMTOOLS_FILTER_UNIQUE  } from '../../../modules/local/samtoolsfilter.nf'
include { SAMTOOLS_FILTER as SAMTOOLS_FILTER_NU      } from '../../../modules/local/samtoolsfilter.nf'

include { SAMTOOLS_FILTER as SAMTOOLS_FILTER_UNIQUE_SECOND  } from '../../../modules/local/samtoolsfilter.nf'
include { SAMTOOLS_FILTER as SAMTOOLS_FILTER_NU_SECOND      } from '../../../modules/local/samtoolsfilter.nf'


// samtools stats + grep SN fields we watn to keep
include { FILTER_STATS                               } from '../filter_stats'
include { FILTER_STATS as FILTER_STATS_UNIQUE_AND_NU } from '../filter_stats'

include { BEDTOOLS_BAMTOBED } from '../../../modules/nf-core/bedtools/bamtobed/main'

//include { MERGE_FILTERED_STATS                       } from '../../../modules/local/mergeFilteredStats.nf'
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
    ch_filtered_bams = Channel.empty();

    bamInput = bam.map{tuple(it[0], it[1], [])}

    FILTER_STATS(bamInput)

    if(params.isStranded) {
        SAMTOOLS_FILTER_UNIQUE(bamInput, 'firststrand')
        SAMTOOLS_FILTER_UNIQUE_SECOND(bamInput, 'secondstrand')
        SAMTOOLS_FILTER_NU(bamInput, 'firststrand')
        SAMTOOLS_FILTER_NU_SECOND(bamInput, 'secondstrand')
        ch_filtered_bams = SAMTOOLS_FILTER_UNIQUE.out.bam.mix(SAMTOOLS_FILTER_UNIQUE_SECOND.out.bam,
                                                              SAMTOOLS_FILTER_NU.out.bam,
                                                              SAMTOOLS_FILTER_NU_SECOND.out.bam)
    }
    else {
        SAMTOOLS_FILTER_UNIQUE(bamInput, 'unstranded')
        SAMTOOLS_FILTER_NU(bamInput, 'unstranded')
        ch_filtered_bams = SAMTOOLS_FILTER_UNIQUE.out.bam.mix(SAMTOOLS_FILTER_NU.out.bam)
    }

    //ch_filtered_bams.view()

    FILTER_STATS_UNIQUE_AND_NU(ch_filtered_bams.map{tuple(it[0], it[1], [])})

    BEDTOOLS_BAMTOBED(ch_filtered_bams)

    // TODO:  add step to merge stats and calculate percent coverage
// MERGE_FILTERED_STATS(FILTER_STATS.out.)

    emit:
    versions = ch_versions
}
