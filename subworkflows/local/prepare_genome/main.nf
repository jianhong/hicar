include { GUNZIP as GUNZIP_FASTA     } from '../../../modules/nf-core/gunzip/main'
include { GUNZIP as GUNZIP_GTF       } from '../../../modules/nf-core/gunzip/main'
include { GUNZIP as GUNZIP_GFF       } from '../../../modules/nf-core/gunzip/main'
include { GUNZIP as GUNZIP_BLACKLIST } from '../../../modules/nf-core/gunzip/main'
include { GFFREAD                    } from '../../../modules/nf-core/gffread/main'
include { BWA_INDEX                  } from '../../../modules/nf-core/bwa/index/main'
include { SAMTOOLS_FAIDX             } from '../../../modules/nf-core/samtools/faidx/main'
include { KHMER_UNIQUEKMERS          } from '../../../modules/nf-core/khmer/uniquekmers/main'
include { GENMAP_INDEX               } from '../../../modules/nf-core/genmap/index/main'
include { GENMAP_MAPPABILITY         } from '../../../modules/local/genmap/mappability/main'
include { RE_CUTSITE                 } from '../../../modules/local/re_cutsite/main'
include { COOLER_DIGEST              } from '../../../modules/nf-core/cooler/digest/main'
include { UCSC_WIGTOBIGWIG           } from '../../../modules/nf-core/ucsc/wigtobigwig/main'

workflow PREPARE_GENOME {
    take:
    genome       // string
    fasta        // string/path
    gtf          // string/path or null
    gff          // string/path or null
    bwa_index    // string/path or null
    read_length  // integer
    macs_gsize   // value or null
    ucscname     // string or null
    blacklist    // string/path or null
    mappability  // string/path or null    
    enzyme       // string or null

    main:
    ch_versions = Channel.empty()

    // FASTA
    ch_fasta_in = Channel.value([ [id: 'fasta'], file(fasta, checkIfExists: true) ])
    if (fasta.endsWith('.gz')) {
        GUNZIP_FASTA(ch_fasta_in)
        ch_fasta = GUNZIP_FASTA.out.gunzip
    } else {
        ch_fasta = ch_fasta_in
    }

    // GTF: use GTF if given, otherwise convert GFF -> GTF
    if (gtf) {
        ch_gtf_in = Channel.value([ [id: 'annotation'], file(gtf, checkIfExists: true) ])
        if (gtf.endsWith('.gz')) {
            GUNZIP_GTF(ch_gtf_in)
            ch_gtf = GUNZIP_GTF.out.gunzip
        } else {
            ch_gtf = ch_gtf_in
        }
    } else if (gff) {
        ch_gff_in = Channel.value([ [id: 'annotation'], file(gff, checkIfExists: true) ])
        if (gff.endsWith('.gz')) {
            GUNZIP_GFF(ch_gff_in)
            ch_gff_in = GUNZIP_GFF.out.gunzip
        }
        GFFREAD(ch_gff_in)   // add the fasta input if your module version requires it
        ch_gtf = GFFREAD.out.gtf
        ch_versions = ch_versions.mix(GFFREAD.out.versions)
    } else {
        ch_gtf = Channel.empty()
    }

    // BWA index
    if (bwa_index) {
        ch_bwa_index = Channel.value([ [id: 'genome'], file(bwa_index, checkIfExists: true) ])
    } else {
        BWA_INDEX(ch_fasta)
        ch_bwa_index = BWA_INDEX.out.index
        ch_versions = ch_versions.mix(BWA_INDEX.out.versions_bwa)
    }

    // Chromosome sizes and fai
    SAMTOOLS_FAIDX(ch_fasta.map { [it[0], it[1], []] }, true)
    ch_versions = ch_versions.mix(SAMTOOLS_FAIDX.out.versions_samtools)


    // Prepare ucsc annotation name
    if(ucscname){
        ch_ucscname = Channel.value(ucscname)
    } else {
        ucsc_map = ["GRCh38":"hg38", "GRCh37":"hg19",
                    "GRCm38":"mm10", "TAIR10":"tair10",
                    "UMD3.1":"bosTau8", "CanFam3.1":"canFam3",
                    "WBcel235":"ce11", "GRCz10":"danRer10",
                    "BDGP6":"dm6", "EquCab2":'equCab2',
                    "Galgal4":"galGal4", "CHIMP2.1.4":"panTro4",
                    "Rnor_6.0":"rn6", "R64-1-1":"sacCer3",
                    "Sscrofa10.2":"susScr3"]
        ch_ucscname = Channel.value(ucsc_map[genome] ?: genome)
    }

    // Effective genome size
    if (macs_gsize) {
        ch_gsize = Channel.value(macs_gsize)
    } else {
        KHMER_UNIQUEKMERS(ch_fasta.map { it[1] }, read_length)
        ch_gsize = KHMER_UNIQUEKMERS.out.kmers.map { it.text.trim() }
        ch_versions = ch_versions.mix(KHMER_UNIQUEKMERS.out.versions)
    }

    // Blacklist
    if (blacklist) {
        ch_bl_in = Channel.value([ [id: 'blacklist'], file(blacklist, checkIfExists: true) ])
        if (blacklist.endsWith('.gz')) {
            GUNZIP_BLACKLIST(ch_bl_in)
            ch_blacklist = GUNZIP_BLACKLIST.out.gunzip
        } else {
            ch_blacklist = ch_bl_in
        }
    } else {
        ch_blacklist = Channel.value([ [id: 'blacklist'], [] ])
    }

    // Mappability: use provided file, otherwise compute with GenMap
    if (mappability) {
        ch_mappability = Channel.value(file(mappability, checkIfExists: true))
    } else {
        GENMAP_INDEX(ch_fasta.map { it[1] })
        GENMAP_MAPPABILITY(GENMAP_INDEX.out.index, read_length, 0) // kmer, errors
        ch_mappability = UCSC_WIGTOBIGWIG(
            GENMAP_MAPPABILITY.out.bedgraph
        )
        ch_versions = ch_versions.mix(GENMAP_INDEX.out.versions, GENMAP_MAPPABILITY.out.versions, UCSC_WIGTOBIGWIG.out.versions)
    }

    /*
     * Create digest genome file for PAIRTOOLS_PAIRE
     */
    digest_genome_bed = COOLER_DIGEST (
        ch_fasta.map { it[1] },
        SAMTOOLS_FAIDX.out.sizes,
        params.enzyme
    ).bed
    ch_versions = ch_versions.mix(COOLER_DIGEST.out.versions_cooler)

    /*
     * get enzyme cut site and position for function maps:cut or enzyme_cut
     */
    RE_CUTSITE ( params.enzyme )
    ch_versions = ch_versions.mix(RE_CUTSITE.out.versions)

    emit:
    fasta         = ch_fasta
    gtf           = ch_gtf
    bwa_index     = ch_bwa_index
    chrom_sizes   = SAMTOOLS_FAIDX.out.sizes
    gsize         = ch_gsize
    ucscname      = ch_ucscname
    blacklist     = ch_blacklist
    mappability   = ch_mappability
    digest_genome = digest_genome_bed
    sites         = RE_CUTSITE.out.site
    versions  = ch_versions
}