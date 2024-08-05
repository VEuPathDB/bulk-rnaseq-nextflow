process BED_AND_STATS_FROM_SPLIT_BAM {
    tag '$bam'
    label 'process_single'

    container 'docker.io/veupathdb/shortreadaligner:latest'

    input:
    tuple val(meta), path(input)

    output:
    tuple val(meta), path("*.bed"), emit: bam
    tuple val(meta), path("*.txt"), emit: stats
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def strandSpecific = params.isStrandSpecific ? 1 : 0
    def isPairedEnd = meta.single_end ? 0 : 1
    """
    gsnapSplitBam.pl --mainResultDir . \
                --strandSpecific ${strandSpecific} \
                --isPairedEnd ${isPairedEnd} \
                --bamFile ${input}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        echo 1
    END_VERSIONS
    """

    stub:
    """
    echo 1 >mappinStats.txt
    echo 1 >unique.bed
    echo 1 >nu.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        echo 1
    END_VERSIONS
    """
}
