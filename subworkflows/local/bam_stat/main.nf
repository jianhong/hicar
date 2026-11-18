/*
 * Createing Stats for mapping results
 */

include { SAMTOOLS_SORT      } from '../../../modules/nf-core/samtools/sort/main'
include { SAMTOOLS_STATS     } from '../../../modules/nf-core/samtools/stats/main'
include { SAMTOOLS_FLAGSTAT  } from '../../../modules/nf-core/samtools/flagstat/main'
include { SAMTOOLS_DEPTH     } from '../../../modules/nf-core/samtools/depth/main'
include { SAMTOOLS_IDXSTATS  } from '../../../modules/nf-core/samtools/idxstats/main'

workflow BAM_STAT {

    take:
    // TODO nf-core: edit input (take) channels
    ch_bam // channel: [ val(meta), [ bam ] ]
    ch_ref // channel [val(meta2), path(fasta), path(fai)]
    index_format // value: 'bai' or 'csi'

    main:
    SAMTOOLS_SORT ( ch_bam, ch_ref, index_format )

    bam_bai = SAMTOOLS_SORT.out.bam.join(SAMTOOLS_SORT.out.index)

    SAMTOOLS_STATS ( bam_bai, ch_ref )

    SAMTOOLS_FLAGSTAT ( bam_bai )

    SAMTOOLS_DEPTH ( bam_bai.map { meta, bam, bai -> [meta, bam, bai, []] }, ch_ref )

    SAMTOOLS_IDXSTATS ( bam_bai )

    emit:
    stats = SAMTOOLS_STATS.out.stats
    flagstat = SAMTOOLS_FLAGSTAT.out.flagstat
    depth = SAMTOOLS_DEPTH.out.tsv
    idxstats = SAMTOOLS_IDXSTATS.out.idxstats
}
