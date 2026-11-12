process CSP_ANALYSIS {
    tag "${meta.key}"
    publishDir "${params.outdir}/csp/data", mode:'copy', overwrite:true, pattern:'*.tsv'
    input:
    tuple val(meta), path(features)
    path settings
    tuple val(code_hash), path(library)
    output:
    tuple val(meta), path("${meta.key}.csp.mat"), emit:results
    path '*.tsv', emit:measurements
    script:
    def code="addpath('${library}'); tms_csp('${features}','${settings}');"
    "${params.octave} --no-gui --quiet --eval \"${code}\""
}
process CSP_PLOT {
    tag id
    label 'plot'
    publishDir { params.slim.toString().toLowerCase() == 'true' ? "${params.outdir}/slim/CSP" : "${params.outdir}/csp/plots" }, mode:'copy', overwrite:true
    input:
    tuple val(id), path(records)
    path settings
    tuple val(code_hash), path(library)
    path render_settings
    val slim
    tuple val(render_hash), path(render_library)
    output:
    path '*.modern_csp.png', emit:png, optional:true
    path '*.modern_csp.svg', emit:svg, optional:true
    path '*.modern_csp.pdf', emit:pdf, optional:true
    path '*.csv', emit:csv, optional:true
    path '*.render.json', emit:audit
    script:
    def files=records.collect { "'${it}'" }.join(',')
    def code="addpath('${library}'); addpath('${render_library}'); tms_csp_render({${files}},'${settings}','${render_settings}',${slim ? 'true' : 'false'});"
    "${params.octave} --no-gui --quiet --eval \"${code}\""
}
process CSP_EXPORT {
    publishDir "${params.outdir}/csp/data", mode:'copy', overwrite:true
    input:
    path records
    path settings
    tuple val(code_hash), path(library)
    output:
    path '*.xlsx'
    path 'CSP_results.tsv', emit:table
    script:
    def files=records.collect { "'${it}'" }.join(',')
    def code="addpath('${library}'); tms_csp_export({${files}},'${settings}');"
    "${params.octave} --no-gui --quiet --eval \"${code}\""
}
