/*
 * call peak by MACS2 for ATAC reads
 */
params.options = [:]

include { PAIRTOOLS_SELECT
    as  PAIRTOOLS_SELECT_SHORT} from '../../modules/nf-core/modules/pairtools/select/main'           addParams(options: params.options.pairtools_select_short)
include { SHIFTREADS          } from '../../modules/local/atacreads/shiftreads'       addParams(options: params.options.shift_reads)
include { MERGEREADS          } from '../../modules/local/atacreads/mergereads'       addParams(options: params.options.merge_reads)
include { MACS2_CALLPEAK      } from '../../modules/local/atacreads/macs2'            addParams(options: params.options.macs2_atac)
include { DUMPREADS           } from '../../modules/local/atacreads/dumpreads'        addParams(options: params.options.dump_reads_per_group)
include { DUMPREADS
    as DUMPREADS_SAMPLE       } from '../../modules/local/atacreads/dumpreads'        addParams(options: params.options.dump_reads_per_sample)
include { MERGE_PEAK          } from '../../modules/local/atacreads/mergepeak'        addParams(options: params.options.merge_peak)
include { ATACQC              } from '../../modules/local/atacreads/atacqc'           addParams(options: params.options.atacqc)
include { BEDTOOLS_GENOMECOV  } from '../../modules/nf-core/modules/bedtools/genomecov/main'  addParams(options: params.options.bedtools_genomecov_per_group)
include { BEDTOOLS_GENOMECOV
    as BEDTOOLS_GENOMECOV_SAM } from '../../modules/nf-core/modules/bedtools/genomecov/main'  addParams(options: params.options.bedtools_genomecov_per_sample)
include { BEDTOOLS_SORT       } from '../../modules/nf-core/modules/bedtools/sort/main'  addParams(options: params.options.bedtools_sort_per_group)
include { BEDTOOLS_SORT
    as BEDTOOLS_SORT_SAM      } from '../../modules/nf-core/modules/bedtools/sort/main'  addParams(options: params.options.bedtools_sort_per_sample)
include { UCSC_BEDCLIP        } from '../../modules/nf-core/modules/ucsc/bedclip/main'  addParams(options: params.options.ucsc_bedclip)
include { UCSC_BEDGRAPHTOBIGWIG  } from '../../modules/nf-core/modules/ucsc/bedgraphtobigwig/main'  addParams(options: params.options.ucsc_bedgraphtobigwig_per_group)
include { UCSC_BEDGRAPHTOBIGWIG
    as UCSC_BEDGRAPHTOBIGWIG_SAM } from '../../modules/nf-core/modules/ucsc/bedgraphtobigwig/main'  addParams(options: params.options.ucsc_bedgraphtobigwig_per_sample)

workflow ATAC_PEAK {
    take:
    validpair  // channel: [ val(meta), [pairs] ]
    chromsizes // channel: [ path(size) ]
    macs_gsize // channel: value
    gtf        // channel: [ path(gtf) ]

    main:
    // extract ATAC reads, split the pairs into longRange_Trans pairs and short pairs
    ch_version = PAIRTOOLS_SELECT_SHORT(validpair).versions
    // shift Tn5 insertion for longRange_Trans pairs
    SHIFTREADS(PAIRTOOLS_SELECT_SHORT.out.unselected)
    ch_version = ch_version.mix(SHIFTREADS.out.versions)

    // merge the read in same group
    SHIFTREADS.out.bed
            .map{meta, bed -> [meta.group, bed]}
            .groupTuple()
            .map{it -> [[id:it[0]], it[1]]} // id is group
            .set{read4merge}
    MERGEREADS(read4merge)
    ch_version = ch_version.mix(MERGEREADS.out.versions)

    // call ATAC narrow peaks for group
    MACS2_CALLPEAK(MERGEREADS.out.bed, macs_gsize)
    ch_version = ch_version.mix(MACS2_CALLPEAK.out.versions)

    // merge peaks
    atac_peaks = MACS2_CALLPEAK.out.peak.map{it[1]}.collect()
    MERGE_PEAK(atac_peaks)

    // stats
    ATACQC(atac_peaks, MERGEREADS.out.bed.map{it[1]}.collect(), gtf)
    ch_version = ch_version.mix(ATACQC.out.versions)

    // dump ATAC reads for each group for maps
    DUMPREADS(MERGEREADS.out.bed)
    BEDTOOLS_SORT(MACS2_CALLPEAK.out.pileup, "bedgraph")
    UCSC_BEDCLIP(BEDTOOLS_SORT.out.sorted, chromsizes)
    UCSC_BEDGRAPHTOBIGWIG(UCSC_BEDCLIP.out.bedgraph, chromsizes)

    // dump ATAC reads for each samples for differential analysis
    DUMPREADS_SAMPLE(SHIFTREADS.out.bed)
    ch_version = ch_version.mix(DUMPREADS.out.versions)
    BEDTOOLS_GENOMECOV_SAM(SHIFTREADS.out.bed.map{[it[0], it[1], "1"]}, chromsizes, "bedgraph")
    BEDTOOLS_SORT_SAM(BEDTOOLS_GENOMECOV_SAM.out.genomecov, "bedgraph")
    ch_version = ch_version.mix(BEDTOOLS_GENOMECOV_SAM.out.versions)
    UCSC_BEDGRAPHTOBIGWIG_SAM(BEDTOOLS_SORT_SAM.out.sorted, chromsizes)
    ch_version = ch_version.mix(UCSC_BEDGRAPHTOBIGWIG_SAM.out.versions)

    emit:
    peak       = MACS2_CALLPEAK.out.peak              // channel: [ val(meta), path(peak) ]
    xls        = MACS2_CALLPEAK.out.xls               // channel: [ val(meta), path(xls) ]
    mergedpeak = MERGE_PEAK.out.peak                  // channel: [ path(bed) ]
    stats      = ATACQC.out.stats                     // channel: [ path(csv) ]
    reads      = DUMPREADS.out.peak                   // channel: [ val(meta), path(bedgraph) ]
    samplereads= DUMPREADS.out.peak                   // channel: [ val(meta), path(bedgraph) ]
    bws        = UCSC_BEDGRAPHTOBIGWIG.out.bigwig     // channel: [ val(meta), path(bigwig) ]
    versions   = ch_version                           // channel: [ path(version) ]
}
