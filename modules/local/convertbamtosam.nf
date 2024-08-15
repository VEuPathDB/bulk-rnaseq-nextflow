process CONVERT_SAM_TO_BAM {

    tag "$meta.id"
    label 'process_high'
    
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.20--h50ea8bc_0' :
        'biocontainers/samtools:1.20--h50ea8bc_0' }"

    input:
    tuple val(meta), path(bam)


    output:
    tuple val(meta), path("*.sam")                   , emit: sam


    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    samtools view -h -o ${prefix}.sam  ${bam}

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