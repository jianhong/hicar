// Import generic module functions
include { initOptions; saveFiles; getSoftwareName; getProcessName } from '../functions'

params.options = [:]
options        = initOptions(params.options)

process MACS2_CALLPEAK {
    tag "${meta.id}"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['id']) }

    conda (params.enable_conda ? "bioconda::macs2=2.2.7.1" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/macs2:2.2.7.1--py38h0213d0e_1"
    } else {
        container "quay.io/biocontainers/macs2:2.2.7.1--py38h0213d0e_1"
    }

    input:
    tuple val(meta), path(bed)
    val   macs_gsize

    output:
    tuple val(meta), path("*.{narrowPeak,broadPeak}"), emit: peak
    tuple val(meta), path("*.xls")                   , emit: xls
    path "versions.yml"                              , emit: versions

    tuple val(meta), path("*.gappedPeak"), optional:true, emit: gapped
    tuple val(meta), path("*.bed")       , optional:true, emit: bed
    tuple val(meta), path("*.bdg")       , optional:true, emit: bdg
    tuple val(meta), path("*_pileup.bdg"), optional:true, emit: pileup

    script:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    def format   = 'BED'
    """
    macs2 \\
        callpeak \\
        $options.args \\
        --gsize $macs_gsize \\
        --format $format \\
        --name $prefix \\
        --treatment $bed

    cat <<-END_VERSIONS > versions.yml
    ${getProcessName(task.process)}:
        ${getSoftwareName(task.process)}: \$(macs2 --version | sed -e "s/macs2 //g")
    END_VERSIONS
    """
}
