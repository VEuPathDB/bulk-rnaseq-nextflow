// NOTE:  this process does filtering by unique/nu and then strand/isPaired and then merges output
// it uses several samtools (view,index,merge)
process SAMTOOLS_FILTER {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.20--h50ea8bc_0' :
        'biocontainers/samtools:1.20--h50ea8bc_0' }"

    input:
    tuple val(meta), path(input), path(index)
    val strand

    output:
    tuple val(meta), path("${prefix}*.bam"), emit: bam

    when:
    task.ext.when == null || task.ext.when

    script:
    def regex = task.ext.regex ?: ''

    // Prefix here is how we uniquely identify a split file
    prefix = task.ext.prefix ? "${task.ext.prefix}.${meta.id}.${strand}" : "${meta.id}.${strand}"

    if ("$input" == "${prefix}.bam") error "Input and output names are the same, use \"task.ext.prefix\" to disambiguate!"

    if (params.isStranded && meta.single_end && "$strand" == "firststrand") {
        """
        samtools view -h  $input  | grep -E '$regex' |samtools view -h -b -o temp.bam
        samtools index temp.bam

        # https://www.biostars.org/p/14378/ unmapped reads are ignored
        samtools view -b -F 20 temp.bam >${prefix}.bam
        """
    }
    else if (params.isStranded && meta.single_end && "$strand" == "secondstrand") {
        """
        samtools view -h  $input  | grep -E '$regex' |samtools view -h -b -o temp.bam
        samtools index temp.bam

        # https://www.biostars.org/p/14378/ unmapped reads are ignored
        samtools view -b -f 16 temp.bam >${prefix}.bam
        """
    }
    else if (params.isStranded && !meta.single_end && "$strand" == "firststrand") {
        """
        samtools view -h  $input  | grep -E '$regex' |samtools view -h -b -o temp.bam
        samtools index temp.bam

        # modified bash script from Istvan Albert to get for.bam and rev.bam
        # https://www.biostars.org/p/92935/

        # 1. alignments of the second in pair if they map to the forward strand
        # 2. alignments of the first in pair if they map to the reverse strand
        samtools view -b -f 163 temp.bam >fwd1.bam
        samtools index fwd1.bam

        samtools view -b -f 83 temp.bam >fwd2.bam
        samtools index fwd2.bam

        samtools merge -f ${prefix}.bam fwd1.bam fwd2.bam
        samtools index ${prefix}.bam
        """
    }
    else if (params.isStranded && !meta.single_end && "$strand" == "secondstrand") {
        """
        samtools view -h  $input  | grep -E '$regex' |samtools view -h -b -o temp.bam
        samtools index temp.bam

        # modified bash script from Istvan Albert to get for.bam and rev.bam
        # https://www.biostars.org/p/92935/

        # 1. alignments of the second in pair if they map to the reverse strand
        # 2. alignments of the first in pair if they map to the forward strand
        samtools view -b -f 147 temp.bam > rev1.bam
        samtools index rev1.bam

        samtools view -b -f 99 temp.bam > rev2.bam
        samtools index rev2.bam

        samtools merge -f ${prefix}.bam rev1.bam rev2.bam
        samtools index ${prefix}.bam
        """
    }
    else {
        """
        samtools view -h  $input  | grep -E '$regex' |samtools view -h -b -o ${prefix}.bam
        samtools index ${prefix}.bam
        """
    }


    stub:
    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
