/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SAMTOOLS_FILTER as SAMTOOLS_FILTER_UNIQUE                     } from '../../../modules/local/samtoolsfilter.nf'
include { SAMTOOLS_FILTER as SAMTOOLS_FILTER_NU                         } from '../../../modules/local/samtoolsfilter.nf'

include { SAMTOOLS_FILTER as SAMTOOLS_FILTER_UNIQUE_SECOND              } from '../../../modules/local/samtoolsfilter.nf'
include { SAMTOOLS_FILTER as SAMTOOLS_FILTER_NU_SECOND                  } from '../../../modules/local/samtoolsfilter.nf'

// samtools stats + grep SN fields we watn to keep
include { FILTER_STATS                                                  } from '../filter_stats'
include { FILTER_STATS as FILTER_STATS_UNIQUE_AND_NU                    } from '../filter_stats'


include { BEDTOOLS_GENOME_COVERAGE_BG                                   } from '../../../modules/local/genomeCoverage.nf'

include { BEDTOOLS_GENOME_COVERAGE                                      } from '../../../modules/local/genomeCoverage.nf'
include { BEDTOOLS_GENOME_COVERAGE as BEDTOOLS_GENOME_COVERAGE_FULL_BAM } from '../../../modules/local/genomeCoverage.nf'

include { MERGE_FILTERED_STATS                                          } from '../../../modules/local/mergeFilteredStats.nf'

/*
========================================================================================
    SUBWORKFLOW TO INITIALISE PIPELINE
========================================================================================
*/

workflow SPLIT_BAM_STATS_AND_BED {
    take:
    bam
    fastaIndex

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

        // Mixes bams from samples together. No longer per sample
        ch_filtered_bams = ch_filtered_bams.mix(
            addMetaData(SAMTOOLS_FILTER_UNIQUE.out.bam, "firststrand", "unique"),
            addMetaData(SAMTOOLS_FILTER_UNIQUE_SECOND.out.bam, "secondstrand", "unique"),
            addMetaData(SAMTOOLS_FILTER_NU.out.bam, "firststrand", "nu"),
            addMetaData(SAMTOOLS_FILTER_NU_SECOND.out.bam, "secondstrand", "nu")
        )
    }
    else {
        SAMTOOLS_FILTER_UNIQUE(bamInput, 'unstranded')
        SAMTOOLS_FILTER_NU(bamInput, 'unstranded')
        ch_filtered_bams = ch_filtered_bams.mix(
            addMetaData(SAMTOOLS_FILTER_UNIQUE.out.bam, "unstranded", "unique"),
            addMetaData(SAMTOOLS_FILTER_NU.out.bam, "unstranded", "nu")
        )
    }




    FILTER_STATS_UNIQUE_AND_NU(ch_filtered_bams.map{tuple(it[0], it[1], [])})


    BEDTOOLS_GENOME_COVERAGE_BG(ch_filtered_bams, fastaIndex)

    BEDTOOLS_GENOME_COVERAGE(ch_filtered_bams, fastaIndex)
    BEDTOOLS_GENOME_COVERAGE_FULL_BAM(addMetaData(bamInput, "both", "all"), fastaIndex)

    mergeStatsInput = BEDTOOLS_GENOME_COVERAGE.out.coverage.mix(
        BEDTOOLS_GENOME_COVERAGE_FULL_BAM.out.coverage,
        FILTER_STATS_UNIQUE_AND_NU.out.stats,
        addMetaData(FILTER_STATS.out.stats, "both", "all")
    ).map{ tuple(it[0].sampleId, it[1])}
        .groupTuple()


    MERGE_FILTERED_STATS(mergeStatsInput)

    emit:
    stats = MERGE_FILTERED_STATS.out.stats
    versions = ch_versions
}



def addMetaData(ch, strand, align) {
    return ch.map {
        meta = it[0]
        def newId = meta.id
        def bedfilename = "";
        def alignPretty = "all_results";

        if(align == "unique") {
            newId = "unique_results." + meta.id + "." + strand
            alignPretty = "unique_results";
        }
        if(align == "nu"){
            newId = "non_unique_results." + meta.id + "." + strand
            alignPretty = "non_unique_results";

        }
        newMeta = meta.clone();
        newMeta.sampleId = meta.id
        newMeta.id = newId

        newMeta.bedfileName = alignPretty + "." + strand
        if(strand == "unstranded") {
            newMeta.bedfileName = alignPretty
        }
        tuple(newMeta, it[1])

    }
}
