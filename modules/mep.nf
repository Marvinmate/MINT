process MEP_ANALYSIS {
    tag "${meta.key}"
    publishDir "${params.outdir}/mep/data", mode:'copy', overwrite:true, pattern:'*.tsv'
    publishDir "${params.outdir}/provenance", mode:'copy', overwrite:true, pattern:'*.provenance.json'
    input:
    tuple val(meta), path(recording)
    path settings
    tuple val(code_hash), path(library)
    output:
    tuple val(meta), path("${meta.key}.mep.mat"), emit:features
    path "${meta.key}.mep.tsv", emit:measurements
    path "${meta.key}.provenance.json"
    script:
    def metadata=groovy.json.JsonOutput.toJson(meta)
    """
    cat > recording_metadata.json <<'MINT_METADATA'
    ${metadata}
    MINT_METADATA
    cat > run_analysis.m <<'MINT_ANALYSIS'
    addpath('${library}');
    m=jsondecode(fileread('recording_metadata.json'));
    tms_mep('${recording}',m.id,m.condition,m.time,m.protocol,m.key,'${settings}');
    MINT_ANALYSIS
    ${params.octave} --no-gui --quiet run_analysis.m
    """
}

process MEP_PLOT {
    tag "${meta.key}"
    label 'plot'
    publishDir { params.slim.toString().toLowerCase() == 'true' ? "${params.outdir}/slim/MEP" : "${params.outdir}/mep/plots" }, mode:'copy', overwrite:true
    input:
    tuple val(meta), path(features)
    path settings
    tuple val(code_hash), path(library)
    path render_settings
    val slim
    tuple val(render_hash), path(render_library)
    output:
    path '*.png', emit:png, optional:true
    path '*.csv', emit:csv, optional:true
    path '*.graphics.json', emit:audit
    script:
    def code="addpath('${library}'); addpath('${render_library}'); tms_mep_render('${features}','${render_settings}',${slim ? 'true' : 'false'});"
    "${params.octave} --no-gui --quiet --eval \"${code}\""
}
