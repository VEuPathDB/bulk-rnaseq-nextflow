/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { SAMTOOLS_INDEX                            } from '../../../modules/nf-core/samtools/index/main'

// NOTE:  args set for this process in task.ext.args
include { SAMTOOLS_VIEW as SAMTOOLS_VIEW_READ_OR_MATE_MAPPED } from '../../../modules/nf-core/samtools/view/main'

// NOTE:  args set for this process in task.ext.args
include { SAMTOOLS_SORT as SAMTOOLS_SORT_BY_NAME    } from '../../../modules/nf-core/samtools/sort/main'


/*
========================================================================================
    SUBWORKFLOW TO INITIALISE PIPELINE
========================================================================================
*/

workflow BAM_FILTER_AND_SORT_BY_NAME {

    take:
    sortedBam

    main:

    ch_versions = Channel.empty();

    SAMTOOLS_INDEX(sortedBam)

    bamSortedByDefaultWithIndex = sortedBam.join(SAMTOOLS_INDEX.out.bai)

    SAMTOOLS_VIEW_READ_OR_MATE_MAPPED(bamSortedByDefaultWithIndex, tuple([], []), [])
    SAMTOOLS_SORT_BY_NAME(SAMTOOLS_VIEW_READ_OR_MATE_MAPPED.out.bam, tuple([], []))


    ch_versions = ch_versions.mix(
        SAMTOOLS_INDEX.out.versions.first(),
        SAMTOOLS_VIEW_READ_OR_MATE_MAPPED.out.versions.first(),
        SAMTOOLS_SORT_BY_NAME.out.versions.first()
    );

    emit:
    bamSortedByName = SAMTOOLS_SORT_BY_NAME.out.bam
    bamSortedByDefaultWithIndex = bamSortedByDefaultWithIndex
    versions = ch_versions
}
