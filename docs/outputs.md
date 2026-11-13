# Outputs

MINT publishes the results for the enabled modules under `--outdir`. The default is `results/` in the checkout.

| Path relative to the output directory | Contents |
| --- | --- |
| `mep/data/` | Per-recording trial tables with peak-to-peak amplitudes, measurement indices, and status. |
| `csp/data/` | Per-recording durations and breakthrough flags, plus aggregate `CSP_results.tsv`, CSV, and an Excel workbook with raw and T0-normalized values. |
| `ihi/data/` | Per-recording pulse event indices and classes, plus per-participant TSV, CSV, and Excel summaries with a sheet per available condition. |
| `mep/plots/`, `csp/plots/`, `ihi/plots/` | Standard scientific figures in PNG, SVG, and PDF, with JSON rendering metadata. |
| `slim/MEP/`, `slim/CSP/`, `slim/IHI/` | Representative PNGs, plotting CSVs, and rendering JSON in slim mode. |
| `multiqc/multiqc_report.html` | Interactive scientific and quality-control summary when reporting is enabled. |
| `multiqc/multiqc_report_data/`, `multiqc/custom_content/` | Data exported by MultiQC and the tables MINT supplied to the report. |
| `input_manifest.tsv`, `missing_recordings.tsv`, `run_parameters.json` | Input inventory, expected recordings that were absent, and run settings. |
| `provenance/`, `execution/trace.tsv` | Per-recording input and code hashes, software versions and parameters, plus the Nextflow task trace. |

CSV copies of the scientific TSV tables are convenient for import into spreadsheet and statistics software. Blank or `NA` values indicate missing measurements according to the export, so check the relevant trial status before interpreting them. The input manifest lists source file paths and participant IDs. Review it and other outputs before sharing a result directory.

## Example figures

All three examples use synthetic recordings and the illustrative participant label `XX`.

### Motor evoked potentials (MEP)

![Synthetic MEP figure with individual amplitudes and a representative EMG trace](images/example_mep.png)

Individual MEP amplitudes and a representative EMG trace showing the measurement window and markers.

### Cortical silent period (CSP)

![Synthetic CSP figure showing EMG traces and silent period markers](images/example_csp.png)

EMG traces with the MEP and silent-period offset markers used to assess CSP duration.

### Interhemispheric inhibition (IHI)

![Synthetic IHI figure showing right and left EMG in six individual trial panels](images/example_ihi.png)

Six unconditioned, IHI10, and IHI40 trial panels showing right and left EMG, pulse markers, and MEP measurement windows.

## What slim mode keeps

Slim mode keeps the scientific tables, Excel workbooks, provenance, and MultiQC report when enabled. It writes a representative MEP figure for each input protocol, CSP plots for the first participant and earliest available time point across its available conditions, and the IHI overview, amplitude summary, and first detail page for the first selected IHI recording. It retains their PNG and plotting CSV files. Use standard mode for all recordings and vector figures.

## Review the MultiQC report

Open `multiqc/multiqc_report.html` in a browser. Start with the overview and recording counts, then review the sections for the enabled analyses and the flagged measurements. The report reads the scientific tables and provides interactive summaries and source data for inspection. Review the detailed EMG traces in the separate figures.
