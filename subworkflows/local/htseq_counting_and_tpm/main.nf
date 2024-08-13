/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { HTSEQ_COUNT as HTSEQCOUNT_FOR    } from '../../../modules/nf-core/htseq/count/main'
include { HTSEQ_COUNT as HTSEQCOUNT_REV    } from '../../../modules/nf-core/htseq/count/main'
include { HTSEQ_COUNT as HTSEQCOUNT_FOR_NU } from '../../../modules/nf-core/htseq/count/main'
include { HTSEQ_COUNT as HTSEQCOUNT_REV_NU } from '../../../modules/nf-core/htseq/count/main'
include { HTSEQ_COUNT                      } from '../../../modules/nf-core/htseq/count/main'
include { HTSEQ_COUNT as HTSEQ_COUNT_NU    } from '../../../modules/nf-core/htseq/count/main'

/*
========================================================================================
    SUBWORKFLOW TO INITIALISE PIPELINE
========================================================================================
*/

workflow HTSEQ_COUNTS_AND_TPM {
    take:
    bamSortedByName

    main:

    ch_versions = Channel.empty();

    bamInput = bamSortedByName.map{tuple(it[0], it[1], [])}
    gtfInput = tuple(params.genome, [params.gtf])

    if(params.isStranded) {
        HTSEQ_COUNT_FOR(bamInput, gtfInput)
        HTSEQ_COUNT_FOR_NU(bamInput, gtfInput)

        HTSEQ_COUNT_REV(bamInput, gtfInput)
        HTSEQ_COUNT_REV_NU(bamInput, gtfInput)

        ch_versions = ch_versions.mix(HTSEQ_COUNT_FOR.out.versions.first());
    }
    else {
        HTSEQ_COUNT(bamInput, gtfInput)
        HTSEQ_COUNT_NU(bamInput, gtfInput)


        // TODO:  MAKE TPM FILES HERE FOR BOTH UNIQUE AND NU (AND ABOVE)
        // HTSEQ_COUNT.out.txt.join(HTSEQ_COUNT_NU.out.txt).view();

        ch_versions = ch_versions.mix(HTSEQ_COUNT.out.versions.first());
    }


    emit:
    versions = ch_versions
}
