process MULTIQC_REPORT {
    tag 'MINT summary'
    publishDir "${params.outdir}/multiqc", mode:'copy', overwrite:true
    memory '4 GB'
    input:
    path tables
    val analyses
    path missing_recordings
    path science
    val run_context
    path adapter
    path config
    output:
    path 'multiqc_report.html', emit:html
    path 'multiqc_report_data'
    path 'custom_content'
    path 'multiqc_versions.txt'
    script:
    def names=tables.collect { "'${it}'" }.join(',')
    def context=groovy.json.JsonOutput.toJson(run_context + [container:task.container?.toString() ?: ''])
    """
    cat > mint_report_run.json <<'MINT_REPORT_CONTEXT'
    ${context}
    MINT_REPORT_CONTEXT
    "${params.multiqc_bin}" --version > multiqc_versions.txt
    "${params.octave}" --version | head -n 1 >> multiqc_versions.txt
    "${params.octave}" --no-gui --no-history --quiet --eval "addpath('.'); tms_multiqc_content({${names}},'${analyses}','${missing_recordings}','custom_content','${science}',fileread('mint_report_run.json'),'multiqc_versions.txt');"
    "${params.multiqc_bin}" custom_content --config '${config}' --module custom_content --interactive --force --filename multiqc_report.html --outdir .
    """
}

