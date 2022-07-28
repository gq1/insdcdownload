process NCBI_DOWNLOAD {
    label 'process_low'

    conda (params.enable_conda ? "bioconda::wget=1.18" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gnu-wget:1.18--h7132678_6' :
        'quay.io/biocontainers/gnu-wget:1.18--h7132678_6' }"

    input:
    val assembly_accession
    val assembly_name

    output:
    tuple val(meta), path(filename_fasta), emit: fasta
    path filename_assembly_report        , emit: assembly_report
    path filename_assembly_stats         , emit: assembly_stats
    path filename_accession              , emit: accession
    path  "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:

    // Turn "GCA_927399515.1" to "927/399/515/GCA_927399515.1_gfLaeSulp1.1
    def ftp_id_1 = assembly_accession.substring(4,  7)
    def ftp_id_2 = assembly_accession.substring(7,  10)
    def ftp_id_3 = assembly_accession.substring(10, 13)
    def ftp_path = params.ftp_root + "/" + ftp_id_1 + "/" + ftp_id_2 + "/" + ftp_id_3 + "/" + assembly_accession + "_" + assembly_name
    def remote_filename_stem = assembly_accession + "_" + assembly_name

    filename_assembly_report = assembly_accession + ".assembly_report.txt"
    filename_assembly_stats = assembly_accession + ".assembly_stats.txt"
    filename_fasta = assembly_accession + ".masked.fasta"
    filename_accession = "ACCESSION"

    meta = [ id : assembly_accession, name : assembly_name ]
    """
    #export https_proxy=http://wwwcache.sanger.ac.uk:3128
    #export http_proxy=http://wwwcache.sanger.ac.uk:3128
    wget ${ftp_path}/${remote_filename_stem}_assembly_report.txt
    wget ${ftp_path}/${remote_filename_stem}_assembly_stats.txt
    wget ${ftp_path}/${remote_filename_stem}_genomic.fna.gz
    wget ${ftp_path}/md5checksums.txt

    grep "\\(_assembly_report\\.txt\$\\|_assembly_stats\\.txt\$\\|_genomic\\.fna\\.gz\$\\)" md5checksums.txt > md5checksums_restricted.txt
    md5sum -c md5checksums_restricted.txt
    mv ${remote_filename_stem}_assembly_report.txt ${filename_assembly_report}
    mv ${remote_filename_stem}_assembly_stats.txt  ${filename_assembly_stats}
    echo "${assembly_accession}"                 > ${filename_accession}
    zcat ${remote_filename_stem}_genomic.fna.gz  > ${filename_fasta}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        wget: \$(wget --version | head -n 1 | cut -d' ' -f3)
        BusyBox: \$(busybox | head -1 | cut -d' ' -f2)
    END_VERSIONS
    """
}