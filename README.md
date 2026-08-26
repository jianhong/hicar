<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/nf-core-hicar_logo_dark.png">
    <img alt="nf-core/hicar" src="docs/images/nf-core-hicar_logo_light.png">
  </picture>
</h1>

[![GitHub Actions CI Status](https://github.com/nf-core/hicar/actions/workflows/ci.yml/badge.svg)](https://github.com/nf-core/hicar/actions/workflows/ci.yml)
[![GitHub Actions Linting Status](https://github.com/nf-core/hicar/actions/workflows/linting.yml/badge.svg)](https://github.com/nf-core/hicar/actions/workflows/linting.yml)[![AWS CI](https://img.shields.io/badge/CI%20tests-full%20size-FF9900?labelColor=000000&logo=Amazon%20AWS)](https://nf-co.re/hicar/results)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.6515312-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.6515312)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/version-%E2%89%A524.04.2-green?style=flat&logo=nextflow&logoColor=white&color=%230DC09D&link=https%3A%2F%2Fnextflow.io)](https://www.nextflow.io/)
[![nf-core template version](https://img.shields.io/badge/nf--core_template-3.3.1-green?style=flat&logo=nfcore&logoColor=white&color=%2324B064&link=https%3A%2F%2Fnf-co.re)](https://github.com/nf-core/tools/releases/tag/3.3.1)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Seqera%20Platform-%234256e7)](https://cloud.seqera.io/launch?pipeline=https://github.com/nf-core/hicar)

[![Get help on Slack](http://img.shields.io/badge/slack-nf--core%20%23hicar-4A154B?labelColor=000000&logo=slack)](https://nfcore.slack.com/channels/hicar)[![Follow on Bluesky](https://img.shields.io/badge/bluesky-%40nf__core-1185fe?labelColor=000000&logo=bluesky)](https://bsky.app/profile/nf-co.re)[![Follow on Mastodon](https://img.shields.io/badge/mastodon-nf__core-6364ff?labelColor=FFFFFF&logo=mastodon)](https://mstdn.science/@nf_core)[![Watch on YouTube](http://img.shields.io/badge/youtube-nf--core-FF0000?labelColor=000000&logo=youtube)](https://www.youtube.com/c/nf-core)

## Introduction

**nf-core/hicar** is a bioinformatics best-practice analysis pipeline for [HiC on Accessible Regulatory DNA (HiCAR)](https://doi.org/10.1016/j.molcel.2022.01.023) data, a robust and sensitive assay for simultaneous measurement of chromatin accessibility and cis-regulatory chromatin contacts. Unlike the immunoprecipitation-based methods such as HiChIP, PlAC-seq and ChIA-PET, HiCAR does not require antibodies. HiCAR utilizes a Transposase-Accessible Chromatin assay to anchor the chromatin interactions. HiCAR is a tool to study chromatin interactions for low input samples and samples with no available antibodies.

The pipeline can also handle the experiment of HiChIP, ChIA-PET, and PLAC-Seq. It will ask user to input the peak file for the anchor peaks.

<!-- TODO nf-core: Include a figure that guides the user through the major workflow steps. Many nf-core
     workflows use the "tube map" design for that. See https://nf-co.re/docs/guidelines/graphic_design/workflow_diagrams#examples for examples.   -->
<!-- TODO nf-core: Fill in short bullet-pointed list of the default steps in the pipeline -->1. Read QC ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))2. Present QC for raw reads ([`MultiQC`](http://multiqc.info/))

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
group,replicate,fastq_1,fastq_2
CONTROL,1,AEG588A1_S1_L002_R1_001.fastq.gz,AEG588A1_S1_L002_R2_001.fastq.gz
```

Each row represents a fastq file (single-end) or a pair of fastq files (paired end).

Now, you can run the pipeline using:

```console
nextflow run nf-core/hicar \
     -profile <docker/singularity/podman/shifter/charliecloud/conda/institute> \
     --input samplesheet.csv \   # Input data
     --qval_thresh 0.01 \    # Cut-off q-value for MACS2
     --genome GRCh38 \       # Genome Reference
     --mappability /path/mappability/bigWig/file  # Provide mappability to avoid memory intensive calculation
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/usage/getting_started/configuration#custom-configuration-files).

For more details, please refer to the [usage documentation](https://nf-co.re/hicar/usage) and the [parameter documentation](https://nf-co.re/hicar/parameters).
For release candidate (RC) version, please refer to the [usage documentation](docs/usage.md) and [output documentation](docs/output.md). To setup your parameters for RC version, please refer to [parameter configureation page](https://jianhong.github.io/hicar_doc/launch.html).

## Pipeline output

To see the results of an example test run with a full size dataset refer to the [results](https://nf-co.re/hicar/results) tab on the nf-core website pipeline page.
For more details about the output files and reports, please refer to the
[output documentation](https://nf-co.re/hicar/output).

## Credits

nf-core/hicar was originally written by [Jianhong Ou](https://github.com/jianhong), [Yu Xiang](https://github.com/yuxuth), and [Yarui Diao](https://www.diaolab.org/).

We thank the following people for their extensive assistance in the development of this pipeline: Luke Zappia, James A. Fellows Yates, Phil Ewels, Mahesh Binzer-Panchal and Friederike Hanssen.

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [Slack `#hicar` channel](https://nfcore.slack.com/channels/hicar) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citations

If you use nf-core/hicar for your analysis, please cite it using the following doi: [10.5281/zenodo.6515312](https://doi.org/10.5281/zenodo.6515312)

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
