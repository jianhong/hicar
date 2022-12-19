process HOMER_ANALYZEHIC {
    tag "$meta.id"
    label 'process_medium'

    // WARN: Version information not provided by tool on CLI. Please update version string below when bumping container versions.
    conda "bioconda::homer=4.11 bioconda::samtools=1.11 conda-forge::r-base=4.0.2 bioconda::bioconductor-deseq2=1.30.0 bioconda::bioconductor-edger=3.32.0 anaconda::perl=5.26.2"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-29293b111ffe5b4c1d1e14c711264aaed6b97b4a:594338b771cacf1623bd27772b5e12825f8835f2-0' :
        'quay.io/biocontainers/mulled-v2-29293b111ffe5b4c1d1e14c711264aaed6b97b4a:594338b771cacf1623bd27772b5e12825f8835f2-0' }"

    input:
    tuple val(meta), val(bin), path(tagdir)

    output:
    tuple val(meta), val(bin), path("*.bedpe")             , emit: bedpe
    tuple val(meta), val(bin), path("*.interactions.txt")  , emit: interactions
    path  "versions.yml"                                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = '4.11' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    """
    analyzeHiC \\
        $tagdir \\
        -res $bin \\
        $args \\
        -interactions ${meta.id}_binsize_${bin}.interactions.txt

    awk 'BEGIN {OFS="\t"}; NR>1 { print \$3, \$4, \$5, \$9, \$10, \$11, \$1, \$15, \$6, \$12}' \\
        ${meta.id}_binsize_${bin}.interactions.txt \\
        > ${meta.id}_binsize_${bin}.bedpe

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        homer: $VERSION
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
