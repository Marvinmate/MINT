def discoverRecordings(base) {
    if (!java.nio.file.Files.isDirectory(base)) error "Dossier d’entrée introuvable ou invalide : ${base} (voir --help)."
    def rows = []
    def candidates = java.nio.file.Files.walk(base).withCloseable { paths ->
        paths.filter { java.nio.file.Files.isRegularFile(it) && it.fileName.toString().toLowerCase(Locale.ROOT).endsWith('.mat') }.sorted().toList()
    }
    candidates.each { f ->
        def parts = base.relativize(f).collect { it.toString() }
        def protocol = parts[0]
        // Accept the two explicit wrappers found in the historical LabChart dataset.
        if (parts.size() == 5 && java.text.Normalizer.normalize(parts[1], java.text.Normalizer.Form.NFC) == "Données_${protocol}")
            parts.remove(1)
        if (parts.size() != 4 || !(protocol in ['CSP','IHI']))
            error "Chemin MAT invalide : ${f}. Attendu : {CSP,IHI}/[sub-]ID/{Full,Half,Pbo}/PROTOCOLE_T[0-5].mat."
        def id = parts[1].replaceFirst(/^sub-/, '')
        def condition = parts[2]
        def match = (parts[3] =~ /^(CSP|IHI)_T([0-5])\.mat$/)
        if (!(id ==~ /[A-Za-z0-9_-]+/) || !(condition in ['Full','Half','Pbo']) || !match.matches() || match.group(1) != protocol)
            error "Nom MAT ou métadonnées invalides : ${f}. Voir l’arborescence dans --help."
        int time = match.group(2).toInteger()
        rows << tuple([key:"${protocol}_${id}_${condition}_T${time}".toString(), id:id, condition:condition, time:time, protocol:protocol], f)
    }
    if (!rows) error "Aucun fichier MAT trouvé dans ${base}. Déposez les exports LabChart selon --help."
    def duplicates = rows.groupBy { it[0].key }.findAll { key, group -> group.size() > 1 }.keySet()
    if (duplicates) error "Enregistrements en double après interprétation des chemins : ${duplicates.join(', ')}."
    return rows.sort { a,b -> a[0].key <=> b[0].key }
}
