process SPLICE_CROSS_READS {

    container 'docker.io/perl:bookworm'

    input:
    tuple val(meta), path(sam)


    output:
    path("junctions.tab")


    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    gsnapSam2Junctions.pl --is_bam \
                      --input_file ${sam} \
                      --output_file junctions.tab

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