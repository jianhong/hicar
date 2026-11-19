//
// Call ATAC peaks from the R2 ends of the valid pairs
//
include { PAIRTOOLS_SELECT as PAIRTOOLS_SELECT_SHORT } from '../../../modules/nf-core/pairtools/select/main'
include { SHIFT_READS                                } from '../../../modules/local/atacreads/shiftreads'
include { MERGE_READS                                } from '../../../modules/local/atacreads/mergereads'
include { MACS2_CALLPEAK                             } from '../../../modules/nf-core/macs2/callpeak/main'
include { BEDTOOLS_GENOMECOV                         } from '../../../modules/nf-core/bedtools/genomecov/main'
include { MERGE_PEAK                                 } from '../../../modules/local/atacreads/mergepeak'
include { ATACQC                                     } from '../../../modules/local/atacreads/atacqc'
include { BEDFILES_SORT                              } from '../../../modules/local/atacreads/bedsort'
include { UCSC_BEDCLIP                               } from '../../../modules/nf-core/ucsc/bedclip/main'
include { UCSC_BEDGRAPHTOBIGWIG                      } from '../../../modules/nf-core/ucsc/bedgraphtobigwig/main'

workflow ATAC_PEAK {
    take:
    validpair    // channel: [ val(meta), path(pairs.gz) ]
    chromsizes   // channel: [ path(chrom.sizes) ]
    macs_gsize   // channel: value, e.g. '3e7'
    gtf          // channel: [ path(gtf) ]
    method       // value: e.g. 'HiCAR'; HiCAR R2 reads get the Tn5 shift
    anchor_peaks // value: path to user-defined peaks, or null to call peaks with MACS2

    main:
    // 1. split off short-range pairs; the rest (long-range + trans) carry the ATAC signal on R2
    PAIRTOOLS_SELECT_SHORT(validpair)

    // 2. turn R2 ends into Tn5 insertion sites (bed)
    def do_shift = method.toLowerCase() == 'hicar'
    SHIFT_READS(PAIRTOOLS_SELECT_SHORT.out.unselected, do_shift)

    // 3. pool all samples of the same group
    //    v4 samplesheet has no "group" column yet, so fall back to the sample id
    def ch_read4merge = SHIFT_READS.out.bed
        .map { meta, bed -> [ meta.group ?: meta.id, bed ] }
        .groupTuple()
        .map { group, beds -> [ [ id: group ], beds ] }
    MERGE_READS(ch_read4merge)

    // 4. peaks: use the user's peaks if given, otherwise call them with MACS2 per group
    def ch_group_bdg
    def ch_group_peak
    def ch_all_peaks
    if (anchor_peaks) {
        def ch_anchor = channel.value(file(anchor_peaks, checkIfExists: true))
        BEDTOOLS_GENOMECOV(
            MERGE_READS.out.bed.map { meta, bed -> [ meta, bed, 1 ] },
            chromsizes,
            'bedgraph',
            true
        )
        ch_group_bdg  = BEDTOOLS_GENOMECOV.out.genomecov
        ch_group_peak = MERGE_READS.out.bed.combine(ch_anchor).map { meta, _bed, peak -> [ meta, peak ] }
        ch_all_peaks  = ch_anchor
    } else {
        MACS2_CALLPEAK(MERGE_READS.out.bed.map { meta, bed -> [ meta, bed, [] ] }, macs_gsize)
        // -B makes two bedgraphs per group; keep the treatment pileup
        ch_group_bdg  = MACS2_CALLPEAK.out.bdg.map { meta, bdgs ->
            def files = [ bdgs ].flatten()
            [ meta, files.find { f -> f.name.contains('treat_pileup') } ?: files[0] ]
        }
        ch_group_peak = MACS2_CALLPEAK.out.peak
        ch_all_peaks  = MACS2_CALLPEAK.out.peak.map { _meta, peak -> peak }.collect()
    }

    // 5. merge the peaks from all groups into one set
    MERGE_PEAK(ch_all_peaks)

    // 6. ATAC QC
    ATACQC(ch_all_peaks, MERGE_READS.out.bed.map { _meta, bed -> bed }.collect(), gtf)

    // 7. one bigwig per group for genome browsers
    BEDFILES_SORT(ch_group_bdg, 'bedgraph')
    UCSC_BEDCLIP(BEDFILES_SORT.out.sorted, chromsizes)
    UCSC_BEDGRAPHTOBIGWIG(UCSC_BEDCLIP.out.bedgraph, chromsizes)

    emit:
    peak        = ch_group_peak                  // channel: [ val(meta), path(peak) ]
    mergedpeak  = MERGE_PEAK.out.peak            // channel: [ path(bed) ]
    stats       = ATACQC.out.stats               // channel: [ path(csv) ]
    reads       = MERGE_READS.out.bed            // channel: [ val(meta), path(bed.gz) ]  per group
    samplereads = SHIFT_READS.out.bed            // channel: [ val(meta), path(bed.gz) ]  per sample
    bws         = UCSC_BEDGRAPHTOBIGWIG.out.bigwig // channel: [ val(meta), path(bigwig) ]
}
