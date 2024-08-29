process MERGE_FILTERED_STATS {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container 'docker.io/veupathdb/shortreadaligner:latest'
    
    input:
    tuple val(meta), path(fullBam), path(index)    
    path(bams)
    path(coverages)
    path(fullBamCoverage)
    tuple val(totalReadMeta), val(totalReads)

    output:
    tuple val(meta), path("mappingStats.txt"), emit: stats

    when:
    task.ext.when == null || task.ext.when

    script:

    if (params.isStranded) {
        """
        for file in ./*.bam; do        
            samtools stats \$file | grep ^SN | cut -f 2- > \$file.stats
        done
        mergeStrandedStats.pl --nuFirstFile nu.*.firststrand.bam.stats --nuFirstCoverage nu.*.firststrand.cov \
                              --nuSecondFile nu.*.secondstrand.bam.stats --nuSecondCoverage nu.*.secondstrand.cov \
                              --fullFile ${fullBam}.stats --fullCoverage $fullBamCoverage \
                              --unFirstFile unique.*.firststrand.bam.stats --unFirstCoverage unique.*.firststrand.cov \
                              --unSecondFile unique.*.secondstrand.bam.stats --unSecondCoverage unique.*.secondstrand.cov \
                              --totalReads ${totalReads} \
                              --outputFile mappingStats.txt
        """
    }
    else {
        """
        for file in ./*.bam; do        
            samtools stats \$file | grep ^SN | cut -f 2- > \$file.stats
        done
        mergeStats.pl --nuFile nu.*.bam.stats --nuCoverage nu.*.cov \
                      --fullFile ${fullBam}.stats --fullCoverage $fullBamCoverage \
                      --unFile unique.*.bam.stats --unCoverage unique.*.cov \
                      --totalReads ${totalReads} \
                      --outputFile mappingStats.txt
        """
    }

    stub:
    """
    touch mappingStats.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
