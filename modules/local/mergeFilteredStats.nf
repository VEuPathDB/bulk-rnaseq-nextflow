process MERGE_FILTERED_STATS {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container 'docker.io/veupathdb/shortreadaligner:latest'

    input:
      path(bams)
      tuple val(meta), path(fullStats), val(totalReads), path(fullBam), val(extra)
      path(bamStats)    
    
    output:
      tuple val(meta), path("mappingStats.txt"), emit: stats

    when:
    task.ext.when == null || task.ext.when

    script:

    if (params.isStranded) {
        """
        mkdir hold
        mv $fullBam hold
        mv *${meta.id}* hold
        rm *.*
        mv hold/* .
        for file in ./*.bam; do        
            bedtools genomecov -ibam \$file > \$file.cov
        done
        mergeStrandedStats.pl --nuFirstFile nu.*.firststrand.stats* --nuFirstCoverage nu.*.firststrand.bam.cov \
                              --nuSecondFile nu.*.secondstrand.stats* --nuSecondCoverage nu.*.secondstrand.bam.cov \
                              --fullFile ${meta.id}.stats* --fullCoverage ${fullBam}.cov \
                              --unFirstFile unique.*.firststrand.stats* --unFirstCoverage unique.*.firststrand.bam.cov \
                              --unSecondFile unique.*.secondstrand.stats* --unSecondCoverage unique.*.secondstrand.bam.cov \
                              --totalReads ${totalReads} \
                              --outputFile mappingStats.txt
        """
    }
    else {
        """
        mkdir hold
        mv $fullBam hold
        mv *${meta.id}* hold
        rm *.*
        mv hold/* .
        for file in ./*.bam; do        
            bedtools genomecov -ibam \$file > \$file.cov
        done
        mergeStats.pl --nuFile nu.*.bam.stats* --nuCoverage nu.*.cov \
                      --fullFile ${meta.id}.stats* --fullCoverage ${fullBam}.cov \
                      --unFile unique.*.bam.stats* --unCoverage unique.*.cov \
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
