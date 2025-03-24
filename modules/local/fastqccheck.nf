process FASTQCCHECK {
    tag "$meta.id"
    label 'process_single'

    container 'docker.io/veupathdb/shortreadaligner:v1.0.0'

    input:
    tuple val(meta), path(zip)

    output:
    tuple val(meta), path("phred.txt"), emit: phred
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    unzip '*.zip'
    fastqc_check.pl . phred.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        echo 1
    END_VERSIONS
    """

    stub:
    """
    echo 1 >phred.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        echo 1
    END_VERSIONS
    """
}
