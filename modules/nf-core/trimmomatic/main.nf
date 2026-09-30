process TRIMMOMATIC {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/trimmomatic:0.39--hdfd78af_2':
        'biocontainers/trimmomatic:0.39--hdfd78af_2' }"

    input:
    tuple val(meta), path(reads), path(phred)

    output:
    tuple val(meta), path("*.paired.trim*.fastq.gz")   , emit: trimmed_reads
    tuple val(meta), path("*_out.log")                 , emit: out_log
    tuple val(meta), path("*.summary")                 , emit: summary
    path "versions.yml"                                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def trimmed = meta.single_end ? "SE" : "PE"
    def assetsDir = projectDir + "/assets"
    def output = meta.single_end ?
        "${prefix}.SE.paired.trim.fastq.gz" // HACK to avoid unpaired and paired in the trimmed_reads output
        : "${prefix}.paired.trim_1.fastq.gz /dev/null ${prefix}.paired.trim_2.fastq.gz /dev/null"
    def qual_trim = meta.single_end ?
        "ILLUMINACLIP:${assetsDir}/All_adaptors-SE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:20" :
        "ILLUMINACLIP:${assetsDir}/All_adaptors-PE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:20"

    """
    phredVar=\$(cat $phred)

    first_file=\$(ls *.fastq.gz | head -n 1)
    isFake=0

    if awk 'NR % 4 == 0 && \$0 !~ /^I+\$/ { found = 1; exit } END { exit !found }' <(zcat "\$first_file"); then
        isFake=0
    else
        isFake=1
    fi

    if [[ "\$isFake" -eq 1 ]]; then
        phredVar=phred33
    fi

    trimmomatic \\
        $trimmed \\
        -\$phredVar \\
        -threads $task.cpus \\
        -summary ${prefix}.summary \\
        $reads \\
        $output \\
        $qual_trim \\
        $args 2> >(tee ${prefix}_out.log >&2)

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        trimmomatic: \$(trimmomatic -version)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    if (meta.single_end) {
        output_command = "echo '' | gzip > ${prefix}.SE.paired.trim.fastq.gz"
    } else {
        output_command  = "echo '' | gzip > ${prefix}.paired.trim_1.fastq.gz"
        output_command  = "echo '' | gzip > ${prefix}.paired.trim_2.fastq.gz"
    }

    """
    $output_command
    touch ${prefix}.summary
    touch ${prefix}_out.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        trimmomatic: \$(trimmomatic -version)
    END_VERSIONS
    """

}
