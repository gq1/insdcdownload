// nf-core module to check the validity of a samplesheet (.csv file)
process SAMPLESHEET_CHECK {
    tag "$samplesheet"
    label 'process_single'

    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.8.3' :
        'quay.io/biocontainers/python:3.8.3' }"

    input:
    path samplesheet

    output:
    path '*.csv'       , emit: csv
    path "versions.yml", emit: versions

    script: // This script is bundled with the pipeline, in sanger-tol/insdcdownload/bin/
    """
    check_samplesheet.py \\
        $samplesheet \\
        samplesheet.valid.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        check_samplesheet: \$(md5sum \$(which check_samplesheet.py) | cut -d' ' -f1)
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
