process SN_FILTER {
    tag '$bam'
    label 'process_single'

    container 'docker.io/perl:bookworm'

    input:
    tuple val(meta), path(input)

    output:
    tuple val(meta), path("*filtered.stats"), emit: stats
    tuple val(meta), env(TOTAL_READS), emit: total_reads
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    // NOTE: we only care about the following 
    def total = 'raw total sequences'
    def reads = 'reads mapped'
    def length = 'average length'
    def paired = 'reads properly paired'

    """
    grep '^SN' $input  | perl -e 'while(<>){chomp; my (\$h, \$a, \$v) = split(/\\t/, \$_); \$a =~ s/\\:\$//; print "\$a\\t\$v\\n" if (\$a eq "$total" || \$a eq "$reads" || \$a eq "$length"|| \$a eq "$paired");}' >${input}_filtered.stats

    TOTAL_READS=\$(grep 'total' ${input}_filtered.stats |cut -f 2)

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        echo 1
    END_VERSIONS
    """

    stub:
    """
    echo 1 >mappinStats.txt
    echo 1 >unique.bed
    echo 1 >nu.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        echo 1
    END_VERSIONS
    """
}
