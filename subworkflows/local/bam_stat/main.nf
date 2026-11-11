// TODO nf-core: If in doubt look at other nf-core/subworkflows to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/subworkflows
//               You can also ask for help via your pull request or on the #subworkflows channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// TODO nf-core: A subworkflow SHOULD import at least two modules

include { SAMTOOLS_SORT                } from '../../../modules/local/samtools/sort/main'
include { SAMTOOLS_INDEX               } from '../../../modules/nf-core/samtools/index/main'
include { SAMTOOLS_STATS               } from '../../../modules/nf-core/samtools/stats/main'
include { SAMTOOLS_IDXSTATS            } from '../../../modules/nf-core/samtools/idxstats/main'
include { SAMTOOLS_FLAGSTAT            } from '../../../modules/nf-core/samtools/flagstat/main'

workflow BAM_STAT {

    take:
    // TODO nf-core: edit input (take) channels
    bam // channel: [ val(meta), [ bam ] ]

    main:
    // TODO nf-core: substitute modules here for the modules of your subworkflow
    SAMTOOLS_SORT(bam)
    SAMTOOLS_INDEX(SAMTOOLS_SORT.out.bam)
    ch_bam_bai = SAMTOOLS_SORT.out.bam.join(SAMTOOLS_INDEX.out.index, by: [0])
    SAMTOOLS_STATS(ch_bam_bai, [])
    SAMTOOLS_FLAGSTAT(ch_bam_bai)
    SAMTOOLS_IDXSTATS(ch_bam_bai)

    emit:
    // TODO nf-core: edit emitted channels
    stats    = SAMTOOLS_STATS.out.stats           // channel: [ val(meta), [ stats ] ]
    flagstat = SAMTOOLS_FLAGSTAT.out.flagstat     // channel: [ val(meta), [ flagstat ] ]
    idxstats = SAMTOOLS_IDXSTATS.out.idxstats     // channel: [ val(meta), [ idxstats ] ]
}
