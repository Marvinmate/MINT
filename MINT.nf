#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { MEP_ANALYSIS; MEP_PLOT } from './modules/mep'
include { CSP_ANALYSIS; CSP_PLOT; CSP_EXPORT } from './modules/csp'
include { IHI_ANALYSIS; IHI_PLOT; IHI_EXPORT } from './modules/ihi'
include { MULTIQC_REPORT } from './modules/multiqc'
include { EXPORT_CSV } from './modules/export_csv'
include { discoverRecordings } from './subworkflows/local/input'

def booleanParam(String name, value) {
    def normalized = value.toString().toLowerCase(Locale.ROOT)
    if (!(normalized in ['true','false'])) error "--${name} doit valoir true ou false."
    return normalized == 'true'
}

def trackedLibrary(directory) {
    def digest = java.security.MessageDigest.getInstance('SHA-256')
    directory.toFile().listFiles().findAll { it.isFile() && it.name.endsWith('.m') }.sort { it.name }.each { source ->
        digest.update(source.name.getBytes('UTF-8'))
        digest.update(source.bytes)
    }
    return tuple(digest.digest().encodeHex().toString(), directory)
}

def helpText() {
    return '''
MINT — Motor Interhemispheric Neurophysiology Toolbox
Analyse des exports LabChart pour mesurer les amplitudes MEP, le CSP et l’IHI.

    nextflow run MINT.nf [options]
    nextflow run /chemin/MINT/MINT.nf -profile apptainer,slurm --input /chemin/donnees

    --MEP true       Amplitudes MEP (obligatoire, false provoque un refus).
    --CSP true       Durée et normalisation CSP.
    --IHI true       Mesures et classifications IHI.
    --slim false     true : une image PNG et son CSV par catégorie disponible.
    --input          Dossier d’entrée. Par défaut : input/ à côté de MINT.nf.
    --outdir         Destination. Par défaut : results/ à côté de MINT.nf.
    --multiqc true   Génération du rapport HTML.
    --strict_timepoints true   false : accepter les séries incomplètes.
    --container      Remplacer explicitement l’image Docker ou Apptainer.
    --help           Afficher cette aide.
    -profile         docker (défaut), local (Octave natif), apptainer,slurm.
    -work-dir        Chemin de travail Nextflow. Utiliser un partage sous Slurm.
    -resume          Réutiliser le cache d’une exécution précédente.

input/
├── CSP/
│   └── sub-14/
│       ├── Full/  CSP_T0.mat … CSP_T5.mat
│       ├── Half/  CSP_T0.mat … CSP_T5.mat
│       └── Pbo/   CSP_T0.mat … CSP_T5.mat
└── IHI/
    └── sub-14/
        ├── Full/  IHI_T0.mat … IHI_T5.mat
        ├── Half/  IHI_T0.mat … IHI_T5.mat
        └── Pbo/   IHI_T0.mat … IHI_T5.mat

Les IDs historiques sans sub- sont acceptés. Export MAT LabChart à 4 000 Hz,
1 600 échantillons par essai, en volts. Champs requis : data, datastart,
dataend, samplerate, unittext et titles. CSP : un canal EMG. IHI : EMG droit,
EMG gauche, impulsion test et impulsion conditionnante, dans cet ordre.

    nextflow run MINT.nf --IHI false                # MEP + CSP
    nextflow run MINT.nf --CSP false                # MEP + IHI
    nextflow run MINT.nf --CSP false --IHI false    # MEP seule
    nextflow run MINT.nf --slim true                 # Sorties graphiques légères

Les modules publient leurs tableaux dans results/{mep,csp,ihi}/data.
Les graphiques légers se trouvent dans results/slim. Le rapport HTML se
trouve dans results/multiqc.
'''.stripIndent()
}

workflow {
    if (booleanParam('help', params.help)) {
        log.info helpText()
        return
    }

    def accepted = ['input','outdir','MEP','CSP','IHI','slim','multiqc','strict_timepoints','help','octave','multiqc_bin','container','queue','account']
    def unknown = params.keySet() - accepted
    if (unknown) error "Options inconnues : ${unknown.collect { '--' + it }.sort().join(', ')}. Voir --help."
    if (!booleanParam('MEP', params.MEP)) error 'MEP est obligatoire. --MEP false est incompatible avec MINT.'
    def runCsp = booleanParam('CSP', params.CSP)
    def runIhi = booleanParam('IHI', params.IHI)
    def slim = booleanParam('slim', params.slim)
    def reporting = booleanParam('multiqc', params.multiqc)
    def strictTimes = booleanParam('strict_timepoints', params.strict_timepoints)
    def selected = ['mep']
    if (runCsp) selected << 'csp'
    if (runIhi) selected << 'ihi'

    def base = file(params.input)
    def rows = discoverRecordings(base)
    def protocols = rows.collect { it[0].protocol }.toSet()
    if (runCsp && !protocols.contains('CSP')) error 'CSP demandé sans enregistrement CSP. Fournissez les données ou utilisez --CSP false.'
    if (runIhi && !protocols.contains('IHI')) error 'IHI demandé sans enregistrement IHI. Fournissez les données ou utilisez --IHI false.'
    def missing = []
    rows.groupBy { [it[0].protocol,it[0].id,it[0].condition] }.each { key, group ->
        def times = group.collect { it[0].time }
        (0..5).findAll { !times.contains(it) }.each { missing << "${key.join('/')}/T${it}" }
    }
    if (missing && strictTimes)
        error "Enregistrements manquants : ${missing.take(12).join(', ')} (${missing.size()} au total). Utilisez --strict_timepoints false pour accepter les séries incomplètes."
    if (missing) log.warn "${missing.size()} enregistrements manquants. Voir missing_recordings.tsv."

    def out = file(params.outdir).toFile()
    out.mkdirs()
    def manifest = rows.collect { m,f -> "${m.key}\t${m.protocol}\t${m.id}\t${m.condition}\tT${m.time}\t${f}" }
    new File(out,'input_manifest.tsv').text = (['recording_id\tprotocol\tparticipant\tcondition\ttimepoint\tmat_path'] + manifest).join('\n') + '\n'
    def missingFile = new File(out,'missing_recordings.tsv')
    missingFile.text = (['recording'] + missing).join('\n') + '\n'
    def science = file("${projectDir}/assets/scientific_params.json", checkIfExists:true)
    def rendering = file("${projectDir}/assets/rendering.json", checkIfExists:true)
    def library = trackedLibrary(file("${projectDir}/bin", checkIfExists:true))
    def renderLibrary = trackedLibrary(file("${projectDir}/visualization", checkIfExists:true))
    def runParameters = [mint:workflow.manifest.version, nextflow:nextflow.version.toString(), analyses:selected, slim:slim,
                         multiqc:reporting, strict_timepoints:strictTimes, input:base.toString(), profile:workflow.profile,
                         scientific_params:science.fileName.toString(), rendering:rendering.fileName.toString()]
    new File(out,'run_parameters.json').text = groovy.json.JsonOutput.prettyPrint(groovy.json.JsonOutput.toJson(runParameters)) + '\n'

    MEP_ANALYSIS(Channel.fromList(rows), science, library)
    def mepPlots = MEP_ANALYSIS.out.features
    if (slim) {
        mepPlots = mepPlots.toList().flatMap { features ->
            features.sort { a,b -> a[0].key <=> b[0].key }.unique { it[0].protocol }
        }
    }
    MEP_PLOT(mepPlots, science, library, rendering, slim, renderLibrary)
    def tables = MEP_ANALYSIS.out.measurements.map { f -> tuple('mep',f) }

    if (runCsp) {
        CSP_ANALYSIS(MEP_ANALYSIS.out.features.filter { m,f -> m.protocol == 'CSP' }, science, library)
        def cspPlots = CSP_ANALYSIS.out.results.map { m,f -> tuple(m.id,f) }.groupTuple()
            .map { id,fs -> tuple(id,fs.sort { a,b -> a.name <=> b.name }) }
        // A failed upstream task can close a result channel without any records.
        // Skip empty aggregates so Nextflow reports the original task failure.
        if (slim) {
            cspPlots = CSP_ANALYSIS.out.results.toList().filter { !it.isEmpty() }.map { records ->
                def first = records.sort { a,b -> (a[0].id <=> b[0].id) ?: (a[0].time <=> b[0].time) ?: (a[0].key <=> b[0].key) }.first()[0]
                tuple(first.id, records.findAll { m,f -> m.id == first.id && m.time == first.time }.collect { it[1] })
            }
        }
        CSP_PLOT(cspPlots, science, library, rendering, slim, renderLibrary)
        CSP_EXPORT(CSP_ANALYSIS.out.results.map { m,f -> f }.toList().filter { !it.isEmpty() }.map { fs -> fs.sort { it.name } }, science, library)
        tables = tables.mix(CSP_ANALYSIS.out.measurements.mix(CSP_EXPORT.out.table).map { f -> tuple('csp',f) })
    }

    if (runIhi) {
        IHI_ANALYSIS(MEP_ANALYSIS.out.features.filter { m,f -> m.protocol == 'IHI' }, science, library)
        def ihiPlots = IHI_ANALYSIS.out.results
        if (slim) ihiPlots = ihiPlots.toList().filter { !it.isEmpty() }.map { records -> records.sort { it[0].key }.first() }
        IHI_PLOT(ihiPlots, science, library, rendering, slim, renderLibrary)
        def perParticipant = IHI_ANALYSIS.out.results.map { m,f -> tuple(m.id,f) }.groupTuple()
            .map { id,fs -> tuple(id,fs.sort { it.name }) }
        IHI_EXPORT(perParticipant, science, library)
        tables = tables.mix(IHI_ANALYSIS.out.measurements.mix(IHI_EXPORT.out.table).map { f -> tuple('ihi',f) })
    }

    EXPORT_CSV(tables.groupTuple().map { module,files -> tuple(module,files.sort { it.name }) })
    if (reporting) {
        MULTIQC_REPORT(tables.map { module,f -> f }.toList().filter { !it.isEmpty() }.map { it.sort { f -> f.name } },
                       selected.sort().join(','), file(missingFile), science,
                       [mint:workflow.manifest.version, nextflow:nextflow.version.toString(), profile:workflow.profile],
                       file("${projectDir}/reporting/tms_multiqc_content.m"),
                       file("${projectDir}/reporting/multiqc_config.yaml"))
    }
}
