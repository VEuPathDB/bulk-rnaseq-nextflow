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

    def uniqueOrNu = "samtools view -h $input | grep -E '$regex'"

    if (params.isStranded && meta.single_end && "$strand" == "firststrand") {
        """
        # https://www.biostars.org/p/14378/ unmapped reads are ignored
        $uniqueOrNu | samtools view -b -F 20 -o ${prefix}.bam -
        """
    }
    else if (params.isStranded && meta.single_end && "$strand" == "secondstrand") {
        """
        $uniqueOrNu | samtools view -b -f 16 -o ${prefix}.bam -
        """
    }
    else if (params.isStranded && !meta.single_end && "$strand" == "firststrand") {
        // https://www.biostars.org/p/92935/ : second in pair on forward strand (163), first in pair on reverse strand (83)
        """
        $uniqueOrNu | samtools view -b -e '(flag & 163) == 163 || (flag & 83) == 83' -o ${prefix}.bam -
        samtools index ${prefix}.bam
        """
    }
    else if (params.isStranded && !meta.single_end && "$strand" == "secondstrand") {
        // second in pair on reverse strand (147), first in pair on forward strand (99)
        """
        $uniqueOrNu | samtools view -b -e '(flag & 147) == 147 || (flag & 99) == 99' -o ${prefix}.bam -
        samtools index ${prefix}.bam
        """
    }
    else {
        """
        $uniqueOrNu | samtools view -h -b -o ${prefix}.bam
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
