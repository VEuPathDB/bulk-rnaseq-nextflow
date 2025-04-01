process MERGE_FILTERED_STATS {
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container 'docker.io/veupathdb/shortreadaligner:1.0.0'

    publishDir "${params.outdir}/$sampleId", mode: 'copy', pattern: "*mappingStats.txt*"

    input:
    tuple val(sampleId), path(files)

    output:
    tuple val(sampleId), path("mappingStats.txt"), emit: stats

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    mergeStats.pl --sampleId $sampleId --outputFile mappingStats.txt
    """

    stub:
    """
    touch mappingStats.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
