/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { SAMTOOLS_INDEX                            } from '../../../modules/nf-core/samtools/index/main'

// NOTE:  args set for these are set in task.ext.args
include { SAMTOOLS_VIEW as SAMTOOLS_VIEW_READ_NO_MATE    } from '../../../modules/nf-core/samtools/view/main'
include { SAMTOOLS_VIEW as SAMTOOLS_VIEW_MATE_NO_READ    } from '../../../modules/nf-core/samtools/view/main'
include { SAMTOOLS_VIEW as SAMTOOLS_VIEW_READ_AND_MATE    } from '../../../modules/nf-core/samtools/view/main'

include { SAMTOOLS_MERGE                            } from '../../../modules/nf-core/samtools/merge/main'

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

    SAMTOOLS_VIEW_READ_NO_MATE(sortedBam.join(SAMTOOLS_INDEX.out.bai), tuple([], []), [])
    SAMTOOLS_VIEW_MATE_NO_READ(sortedBam.join(SAMTOOLS_INDEX.out.bai), tuple([], []), [])
    SAMTOOLS_VIEW_READ_AND_MATE(sortedBam.join(SAMTOOLS_INDEX.out.bai), tuple([], []), [])

    combined = combineSamtoolsFilters(
        SAMTOOLS_VIEW_READ_NO_MATE.out.bam,
        SAMTOOLS_VIEW_MATE_NO_READ.out.bam,
        SAMTOOLS_VIEW_READ_AND_MATE.out.bam
        );

    SAMTOOLS_MERGE(combined, tuple([], []), tuple([], []))
    SAMTOOLS_SORT_BY_NAME(SAMTOOLS_MERGE.out.bam, tuple([], []))


    ch_versions = ch_versions.mix(
        SAMTOOLS_INDEX.out.versions.first(),
        SAMTOOLS_VIEW_READ_AND_MATE.out.versions.first(),
        SAMTOOLS_MERGE.out.versions.first(),
        SAMTOOLS_SORT_BY_NAME.out.versions.first()
    );

    emit:
    bam = SAMTOOLS_SORT_BY_NAME.out.bam
    versions = ch_versions
}

def combineSamtoolsFilters(bam1, bam2, bam3) {
    return bam1.join(bam2).join(bam3)
        .map { tuple(it[0], it[1..-1]) }
}
