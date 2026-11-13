# Running MINT

Run these examples from the MINT checkout. Replace `input` with the path to your prepared recordings and choose an output directory. Docker is the default profile; the examples name it explicitly.

## Select modules

```bash
# MEP only
nextflow run MINT.nf -profile docker --input input --outdir results/mep-only --CSP false --IHI false

# MEP and CSP
nextflow run MINT.nf -profile docker --input input --outdir results/mep-csp --IHI false

# MEP and IHI
nextflow run MINT.nf -profile docker --input input --outdir results/mep-ihi --CSP false

# MEP, CSP, and IHI
nextflow run MINT.nf -profile docker --input input --outdir results/all
```

MEP always runs on every valid recording under `--input`, including when a downstream module is disabled. Use an input directory containing only the protocol you want if you also want to limit MEP to that protocol. An enabled CSP or IHI module requires recordings for its protocol.

## Standard and slim outputs

Standard mode writes the full figure set. Slim mode writes a representative subset of PNGs and their plotting CSVs. Both modes produce the same scientific tables for the selected analyses. MultiQC is enabled by default.

```bash
# Standard mode
nextflow run MINT.nf -profile docker --input input --outdir results/standard --slim false

# Slim mode
nextflow run MINT.nf -profile docker --input input --outdir results/slim-run --slim true
```

To resume an interrupted run, rerun the same command with `-resume` from the same launch directory and keep its `.nextflow` cache and task work directory.

## Run on Slurm

Run this from a site-approved submission environment. Replace the example project paths, partition, and account with values provided by your cluster. Keep the checkout, inputs, work directory, and Nextflow image cache accessible from the submission host and compute nodes.

```bash
export NXF_APPTAINER_CACHEDIR=/shared/project/mint-cache
mkdir -p "$NXF_APPTAINER_CACHEDIR"

nextflow run MINT.nf -profile apptainer,slurm \
  -work-dir /shared/project/mint-work \
  --input /shared/project/input \
  --outdir /shared/project/mint-results \
  --queue compute --account myproject
```

Omit `--queue` or `--account` when your cluster supplies the corresponding default. With `-profile apptainer` alone, Nextflow runs tasks locally on the Linux host. On a site that requires a pre-staged image, add `--container /shared/project/tms-pipeline_1.0.sif` with the path to an equivalent approved SIF. Keep the bundled `compat/date` executable available in the checkout for the Apptainer profile.

## MINT parameters

Pass Boolean values as `true` or `false`. Parameter names are case-sensitive.

| Parameter | Default | Purpose |
| --- | --- | --- |
| `--input` | `input/` beside `MINT.nf` | Root directory of the LabChart exports. |
| `--outdir` | `results/` beside `MINT.nf` | Destination for published results. |
| `--MEP` | `true` | Required analysis. Setting it to `false` causes an error. |
| `--CSP` | `true` | Run CSP analysis and export. |
| `--IHI` | `true` | Run IHI analysis and export. |
| `--slim` | `false` | Export a representative subset of figures. |
| `--multiqc` | `true` | Generate the HTML quality-control report. |
| `--strict_timepoints` | `true` | Require `T0`–`T5` for each participant, condition, and protocol present. |
| `--container` | Official Docker Hub image pinned by digest | Override the image explicitly. The default is recorded in `nextflow.config`. |
| `--queue` | Unset | Slurm partition. |
| `--account` | Unset | Slurm account. |
| `--octave` | `octave-cli` | Octave executable. Use with a native or custom environment. |
| `--multiqc_bin` | `multiqc` | MultiQC executable. Use with a native or custom environment. |
| `--help` | `false` | Print MINT usage. Use `nextflow run MINT.nf --help`. |

Nextflow options use a single hyphen. `-profile` selects the runtime, `-work-dir` selects intermediate storage, and `-resume` reuses cached tasks. `standard` is the implicit Docker profile. The `local` profile uses host-installed Octave and its packages, plotting tools, and MultiQC when reporting is enabled.
