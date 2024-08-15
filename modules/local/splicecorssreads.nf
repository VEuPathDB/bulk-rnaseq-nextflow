process SPLICE_CROSS_READS {

    tag "$meta.id"
    label 'process_high'

    container 'docker.io/perl:bookworm'

    input:
    tuple val(meta), path(sam)


    output:
    path("*junctions.tab")


    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    samToJunctions.pl --input_file ${sam} --output_file ${prefix}_junctions.tab

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