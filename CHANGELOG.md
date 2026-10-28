# veupathdb/bulk-rnaseq-nextflow: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### `Fixed`

- Stranded single-end libraries were split with the opposite convention from paired-end:
  `SAMTOOLS_FILTER` put forward-strand reads in `firststrand`. Single-end `firststrand` now
  takes reverse-strand reads (`-f 16`) and `secondstrand` the forward mapped reads (`-F 20`),
  so for a reverse-stranded library `firststrand` covers + strand genes in both layouts.
  Strand-specific coverage tracks for single-end samples built before this fix are swapped.
  Gene counts (htseq) are unaffected.

### `Added`

- nf-test regression test for the `SAMTOOLS_FILTER` strand split (`nf-test test`), with
  hand-built single-end and paired-end SAM fixtures.

## v1.0dev - [date]

Initial release of veupathdb/bulk-rnaseq-nextflow, created with the [nf-core](https://nf-co.re/) template.

### `Added`

### `Fixed`

### `Dependencies`

### `Deprecated`
