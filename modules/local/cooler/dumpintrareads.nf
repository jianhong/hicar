// Import generic module functions
include { initOptions; saveFiles; getSoftwareName; getProcessName } from '../functions'

params.options = [:]
options        = initOptions(params.options)

process DUMPINTRAREADS {
    tag "${meta.id}"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['id']) }

    conda (params.enable_conda ? "anaconda::gawk=5.1.0" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/gawk:5.1.0"
    } else {
        container "quay.io/biocontainers/gawk:5.1.0"
    }

    input:
    tuple val(meta), path(bedpe)

    output:
    tuple val(meta), path("*.long.intra.bedpe")  , emit: bedpe
    tuple val(meta), path("*.ginteractions")               , emit: gi
    path  "versions.yml"                                   , emit: versions

    script:
    def prefix   = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    """
    awk -F "\t" \\
        '{if(\$1 == \$4) {print > "${prefix}."\$1".long.intra.bedpe"} }' \\
        $bedpe

    awk -F "\t" '{print 0, \$1, \$2, 0, 0, \$4, \$5, 1, \$7}' $bedpe > \\
        ${prefix}.${meta.bin}.ginteractions

    cat <<-END_VERSIONS > versions.yml
    ${getProcessName(task.process)}:
        ${getSoftwareName(task.process)}: \$(echo \$(awk --version 2>&1) | sed -e "s/GNU Awk //g; s/, API.*\$//")
    END_VERSIONS
    """
}
