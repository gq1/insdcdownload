// Modified version of the nf-core module tabix/bgzip that creates the .gzi
// index as well. For simplicity, it's not able to uncompress files anymore.
process TABIX_BGZIP {
    tag "$input"
    label 'process_single'

    conda (params.enable_conda ? 'bioconda::tabix=1.11' : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/tabix:1.11--hdfd78af_0' :
        'quay.io/biocontainers/tabix:1.11--hdfd78af_0' }"

    input:
    tuple val(meta), path(input)

    output:
    tuple val(meta), path("*.gz") , emit: output
    tuple val(meta), path("*.gzi"), emit: index
    path  "versions.yml"          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix   = task.ext.prefix ?: "${meta.id}"
    """
    bgzip \
        -i -I ${prefix}.${input.getExtension()}.gz.gzi \
        $args -@${task.cpus} \
        -c $input > ${prefix}.${input.getExtension()}.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tabix: \$(echo \$(tabix -h 2>&1) | sed 's/^.*Version: //; s/ .*\$//')
    END_VERSIONS
    """
}
