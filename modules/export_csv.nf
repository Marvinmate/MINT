process EXPORT_CSV {
    tag module
    publishDir { "${params.outdir}/${module}/data" }, mode:'copy', overwrite:true

    input:
    tuple val(module), path(tables)

    output:
    path '*.csv'

    script:
    '''
    for table in *.tsv; do
        awk 'BEGIN { FS = "\\t"; ORS = "\\r\\n"; quote = sprintf("%c", 34) }
             {
                 sub(/\\r$/, "")
                 for (column = 1; column <= NF; column++) {
                     field = $column
                     if (field ~ /[",]/) {
                         gsub(quote, quote quote, field)
                         field = quote field quote
                     }
                     printf "%s%s", (column == 1 ? "" : ","), field
                 }
                 printf "%s", ORS
             }' "$table" > "${table%.tsv}.csv"
    done
    '''
}
