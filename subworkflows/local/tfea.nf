//
// Transcription factor enrichment analysis
//

include { HOMER_FINDMOTIFSGENOME     } from '../../modules/local/homer/find_motifs_genome'
include { BIOC_ATACSEQTFEA           } from '../../modules/local/bioc/atacseqtfea'

workflow TFEA {
    take:
    bed                     // peaks regions [meta, R1/2, [peak]]
    additional_param        // singals for each tools

    main:
    ch_versions             = Channel.empty()
    ch_multiqc_files        = Channel.empty()

    switch(params.tfea_tool){
        case "homer":
            HOMER_FINDMOTIFSGENOME(bed, additional_param) // additional_param: genome
            ch_versions = ch_versions.mix(HOMER_FINDMOTIFSGENOME.out.versions.ifEmpty(null))
            break
        case "atacseqtfea":
            BIOC_ATACSEQTFEA(bed, additional_param)
            ch_versions = ch_versions.mix(BIOC_ATACSEQTFEA.out.versions.ifEmpty(null))
            break
        default:
            HOMER_FINDMOTIFSGENOME(bed, additional_param) // additional_param: genome
            ch_versions = ch_versions.mix(HOMER_FINDMOTIFSGENOME.out.versions.ifEmpty(null))
            break
    }

    emit:
    versions        = ch_versions          // channel: [ versions.yml ]
    mqc             = ch_multiqc_files
}
