# bulk-rnaseq-nextflow

A Nextflow DSL2 pipeline, built on nf-core tooling, that aligns short-read bulk RNA-Seq FASTQ files to a reference genome and produces gene counts, coverage tracks, alignment statistics, and splice-junction data.

## Overview

This pipeline is VEuPathDB's bulk RNA-Seq processing step: given per-sample paired- or single-end FASTQ files, it runs QC and adapter trimming, aligns reads to a reference genome with HISAT2, and derives the downstream data products used for gene expression analysis and genome browser tracks — HTSeq gene counts (stranded or unstranded, unique and multi-mapped), genome coverage bedGraphs split by strand and mapping uniqueness, merged alignment statistics, and splice-junction reads for intron detection. It can take FASTQ files directly or retrieve them from NCBI's SRA first.

## Requirements

- [Nextflow](https://www.nextflow.io/) `>=23.04.0`
- [Docker](https://www.docker.com/) or [Singularity](https://sylabs.io/singularity/)/[Apptainer](https://apptainer.org/) (profiles for both are provided; an `lsf` profile combining Singularity with LSF batch submission is also available)

## Usage

The pipeline has two entry points.

### Default entry point — align and quantify

```bash
nextflow run VEuPathDB/bulk-rnaseq-nextflow -r main \
  -profile docker \
  --input samplesheet.csv \
  --fasta /path/to/genome.fasta \
  --gtf /path/to/genome.gtf \
  --genome pfal3D7 \
  --outdir <OUTDIR> \
  -resume -C <config>
```

`samplesheet.csv` has one row per FASTQ file or FASTQ pair:

```csv
sample,fastq_1,fastq_2
CONTROL_REP1,AEG588A1_S1_L002_R1_001.fastq.gz,AEG588A1_S1_L002_R2_001.fastq.gz
```

This runs `PIPELINE_INITIALISATION` (samplesheet parsing/validation) followed by the `BULKRNASEQ` workflow: FastQC → Trimmomatic → HISAT2 build (or reuse of an existing index) and align → samtools sort → strand/uniqueness-filtered BAM splitting → HTSeq counting → genome coverage bedGraphs and merged alignment stats → splice-junction read extraction.

### `getFromSra` — retrieve reads from SRA

```bash
nextflow run VEuPathDB/bulk-rnaseq-nextflow -r main -entry getFromSra \
  -profile docker \
  --input sra_accessions.csv \
  --outdir <OUTDIR> \
  -resume -C <config>
```

Downloads the runs listed in `--input` via `prefetch`/`fasterq-dump` and writes a formatted samplesheet (`formattedSraInput.csv`) suitable for use as `--input` to the default entry point.

## Key parameters

| Parameter | Description |
|---|---|
| `--input` | Samplesheet CSV (`sample`, `fastq_1`, `fastq_2`) for the default entry point, or a list of SRA accessions for `getFromSra` |
| `--fasta` | Reference genome FASTA |
| `--gtf` | Reference genome annotation GTF |
| `--genome` | Genome/organism identifier, used to tag the HISAT2 index and other intermediate files |
| `--outdir` | Output directory |
| `--isStranded` | Whether the library is strand-specific; controls whether HTSeq counting and coverage/BAM splitting run in stranded (forward/reverse) or unstranded mode |
| `--useExistingIndex` | Skip `HISAT2_BUILD` and align against a prebuilt index at `--hisatIndex` instead of building one from `--fasta` |
| `--hisatIndex` | Path to a prebuilt HISAT2 index, used when `--useExistingIndex` is set |
| `--intronLength` | Maximum intron length passed to splice-junction/read-crossing detection |
| `--cdsOrExon` | Feature type (`exon` by default) used when counting reads against the GTF |
| `--fromSra` | Whether the default workflow's input should be treated as coming from SRA |
| `--publish_dir_mode` | File publishing mode for outputs (`copy` by default) |

## Output

Published under `--outdir`, per sample:

- FastQC reports and Trimmomatic-trimmed reads
- Sorted, HISAT2-aligned BAM files, split into unique/non-unique and (if stranded) forward/reverse strand subsets
- HTSeq gene count tables (stranded forward/reverse or unstranded, each for unique and non-unique alignments)
- Genome coverage bedGraph files per strand/uniqueness subset, plus a full-BAM coverage track
- Merged alignment and coverage statistics per sample
- Splice-junction read data derived from the aligned SAM/BAM output
- `pipeline_info/` execution reports (timeline, trace, resource usage, DAG)

## Citations

This pipeline reuses code and infrastructure from the [nf-core](https://nf-co.re) community. See [`CITATIONS.md`](CITATIONS.md) for the full list of tools and references.
