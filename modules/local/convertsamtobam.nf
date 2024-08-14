process SAMTOBAM {
    
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.20--h50ea8bc_0' :
        'biocontainers/samtools:1.20--h50ea8bc_0' }"

    input:
    tuple path(bam)


    output:
    path("*.bam")


    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    samtools view -h -o Sam.bam  ${bam}

     cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        echo 1
    END_VERSIONS

    """

    stub:
    """
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        echo 1
    END_VERSIONS
    """



}