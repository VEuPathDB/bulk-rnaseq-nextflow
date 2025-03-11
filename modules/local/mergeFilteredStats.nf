process MERGE_FILTERED_STATS {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container 'docker.io/veupathdb/shortreadaligner:latest'

    publishDir "${params.outdir}/${meta.id}", mode: 'copy', pattern: "*mappingStats.txt*"

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
        if [ -f "*.*" ]; then
            rm *.*
        fi
        mv hold/* .
        for file in ./*.bam; do        
            bedtools genomecov -ibam \$file > \$file.cov
        done
        mergeStrandedStats.pl --nuFirstFile non_unique_results.*.firststrand.stats* --nuFirstCoverage non_unique_results.*.firststrand.bam.cov \
                              --nuSecondFile non_unique_results.*.secondstrand.stats* --nuSecondCoverage non_unique_results.*.secondstrand.bam.cov \
                              --fullFile ${meta.id}.stats* --fullCoverage ${fullBam}.cov \
                              --unFirstFile unique_results.*.firststrand.stats* --unFirstCoverage unique_results.*.firststrand.bam.cov \
                              --unSecondFile unique_results.*.secondstrand.stats* --unSecondCoverage unique_results.*.secondstrand.bam.cov \
                              --totalReads ${totalReads} \
                              --outputFile mappingStats.txt
        """
    }
    else {
        """
        mkdir hold
        mv $fullBam hold
        mv *${meta.id}* hold
        if [ -f "*.*" ]; then
            rm *.*
        fi
        mv hold/* .
        for file in ./*.bam; do        
            bedtools genomecov -ibam \$file > \$file.cov
        done
        mergeStats.pl --nuFile non_unique_results.*.stats* --nuCoverage non_unique_results.*.cov \
                      --fullFile ${meta.id}.stats* --fullCoverage ${fullBam}.cov \
                      --unFile unique_results.*.stats* --unCoverage unique_results.*.cov \
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
