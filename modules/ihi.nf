process IHI_ANALYSIS {
    tag "${meta.key}"
    publishDir "${params.outdir}/ihi/data", mode:'copy', overwrite:true, pattern:'*.tsv'
    input:
    tuple val(meta), path(features)
    path settings
    tuple val(code_hash), path(library)
    output:
    tuple val(meta), path("${meta.key}.ihi.mat"), emit:results
    path '*.tsv', emit:measurements
    script:
    def code="addpath('${library}'); tms_ihi('${features}','${settings}');"
    "${params.octave} --no-gui --quiet --eval \"${code}\""
}
process IHI_PLOT {
    tag "${meta.key}"
    label 'plot'
    publishDir { params.slim.toString().toLowerCase() == 'true' ? "${params.outdir}/slim/IHI" : "${params.outdir}/ihi/plots" }, mode:'copy', overwrite:true
    input:
    tuple val(meta), path(record)
    path settings
    tuple val(code_hash), path(library)
    path render_settings
    val slim
    tuple val(render_hash), path(render_library)
    output:
    path '*.png', emit:png, optional:true
    path '*.svg', emit:svg, optional:true
    path '*.pdf', emit:pdf, optional:true
    path '*.csv', emit:csv, optional:true
    path '*.graphics.json', emit:audit
    script:
    def code="addpath('${library}'); addpath('${render_library}'); tms_ihi_render('${record}','${render_settings}',${slim ? 'true' : 'false'});"
    "${params.octave} --no-gui --quiet --eval \"${code}\""
}
process IHI_EXPORT {
    tag id
    publishDir "${params.outdir}/ihi/data", mode:'copy', overwrite:true
    input:
    tuple val(id), path(records)
    path settings
    tuple val(code_hash), path(library)
    output:
    path '*.xlsx'
    path '*_IHI_Results.tsv', emit:table
    script:
    def files=records.collect { "'${it}'" }.join(',')
    def code="addpath('${library}'); tms_ihi_export({${files}},'${settings}');"
    "${params.octave} --no-gui --quiet --eval \"${code}\""
}
