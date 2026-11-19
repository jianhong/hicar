//
// Turn mapped reads (BAM) into filtered, deduplicated, indexed valid pairs
//
include { PAIRTOOLS_PARSE                           } from '../../../modules/nf-core/pairtools/parse/main'
include { PAIRTOOLS_SELECT as PAIRTOOLS_SELECT_VP   } from '../../../modules/nf-core/pairtools/select/main'
include { PAIRTOOLS_RESTRICT                        } from '../../../modules/nf-core/pairtools/restrict/main'
include { PAIRTOOLS_SELECT as PAIRTOOLS_SELECT_LONG } from '../../../modules/nf-core/pairtools/select/main'
include { PAIRTOOLS_FLIP                            } from '../../../modules/nf-core/pairtools/flip/main'
include { PAIRTOOLS_SORT                            } from '../../../modules/nf-core/pairtools/sort/main'
include { PAIRTOOLS_DEDUP                           } from '../../../modules/nf-core/pairtools/dedup/main'
include { PAIRIX                                    } from '../../../modules/nf-core/pairix/main'

workflow PAIRTOOLS_PAIRE {
    take:
    ch_bam     // channel: [ val(meta), path(bam) ]  reads grouped by name (unsorted bwa output is fine)
    chromsizes // channel: [ path(chrom.sizes) ]
    frag       // channel: [ path(digest.bed) ]      restriction fragments from PREPARE_GENOME

    main:
    // 1. BAM -> raw pairs
    PAIRTOOLS_PARSE(ch_bam, chromsizes)

    // 2. keep pairs where both ends mapped (UU, UR, RU)
    PAIRTOOLS_SELECT_VP(PAIRTOOLS_PARSE.out.pairsam)

    // 3. tag each read end with its restriction fragment
    PAIRTOOLS_RESTRICT(PAIRTOOLS_SELECT_VP.out.selected, frag)

    // 4. pairs inside the same fragment are "selected"; keep the rest ("unselected")
    PAIRTOOLS_SELECT_LONG(PAIRTOOLS_RESTRICT.out.restrict)

    // 5. flip, sort, remove duplicates, index
    PAIRTOOLS_FLIP(PAIRTOOLS_SELECT_LONG.out.unselected, chromsizes)
    PAIRTOOLS_SORT(PAIRTOOLS_FLIP.out.flip)
    PAIRTOOLS_DEDUP(PAIRTOOLS_SORT.out.sorted)
    PAIRIX(PAIRTOOLS_DEDUP.out.pairs)

    emit:
    pair       = PAIRIX.out.index                                    // channel: [ val(meta), path(pairs.gz), path(px2) ]
    validpair  = PAIRTOOLS_SELECT_VP.out.selected                    // channel: [ val(meta), path(pairs.gz) ]  input for ATAC_PEAK
    distalpair = PAIRTOOLS_SELECT_LONG.out.unselected                // channel: [ val(meta), path(pairs.gz) ]
    raw        = PAIRTOOLS_PARSE.out.pairsam                         // channel: [ val(meta), path(pairsam.gz) ]
    stat       = PAIRTOOLS_PARSE.out.stat.mix(PAIRTOOLS_DEDUP.out.stat) // channel: [ val(meta), path(stat) ]
}
