# Troubleshooting

For a failed run, start with the first failing process and the reported work directory. The process logs `.command.err` and `.command.out` and the launch directory’s `.nextflow.log` can help locate the cause.

## Docker and WSL

**Cannot connect to the Docker daemon.** Start Docker Desktop, wait until its engine is running, and run `docker info` from the same terminal you use for Nextflow. `docker --version` checks the client only. On Linux, check that Docker Engine is running and that your account has access through the installation method documented for your distribution. [Docker Engine installation](https://docs.docker.com/engine/install/)

**Docker works in Windows but fails in Ubuntu.** In PowerShell, check that Ubuntu is using WSL 2 with `wsl --list --verbose`. In Docker Desktop, enable **Settings → Resources → WSL Integration** for that distribution. Reopen Ubuntu and use `docker info` there. If the integration setting is missing, check that Docker Desktop is using Linux containers. [Docker WSL 2 guide](https://docs.docker.com/desktop/features/wsl/)

## Nextflow and Java

Run `java -version` and `nextflow -version` from the launch shell. If either command is missing, check your `PATH` or load the relevant cluster software module. With an incompatible Java runtime, select a supported JDK such as Java 21 and check `JAVA_HOME` if it is set. MINT requires Nextflow 26.04.6 or later. [Installation instructions](installation.md)

## Input files and recordings

- **No recordings or an invalid path.** Point `--input` at the parent of the `CSP` and `IHI` folders. Check the case of the protocol, condition, and file names. With only one protocol, disable the other downstream analysis as in [Select modules](running-mint.md#select-modules).
- **Missing time points.** Add the missing LabChart exports. For an intentionally incomplete series, use `--strict_timepoints false` and review `missing_recordings.tsv`. A missing T0 prevents later CSP values from being normalized for the affected participant and condition.
- **Missing fields, invalid sample rate or trial layout, or missing test pulse.** Review the original LabChart export against [the MAT requirements](input-data.md#labchart-mat-requirements). Re-export when needed. Check the ordering of the IHI channels and confirm that the test pulse channel contains an event that meets the detection rule.

## Paths and permissions

Check that your account can read the input and write to the launch, work, output, and image cache directories. For a containerized run, input and working paths must also be visible inside the container. Choose locations available to Docker Desktop or mounted by Apptainer. Under Slurm, use paths accessible from the compute nodes and check storage quotas. If the cluster controls the permissions or bind mounts, ask its support team about the affected path.

## Container download failures

Read the registry error in the Nextflow log. Check network access to Docker Hub, proxy settings, quotas, and available disk space. The digest in `nextflow.config` identifies the image MINT expects. With a download-restricted cluster, ask the administrator to make the official image available as a shared SIF, then pass its path through `--container`. See [Run on Slurm](running-mint.md#run-on-slurm).

## Slurm and Apptainer

- **Slurm rejects the submission.** Use `sinfo` to inspect partitions. Check your account and partition with the cluster, and pass them as `--account` and `--queue` when required. If a job was accepted, check its status with `squeue -j JOB_ID`, substituting the Slurm job ID.
- **Apptainer cannot access a file, cache, or image.** Use `apptainer --version` in the submission environment and check that the runtime is available to compute jobs. Check your shared `-work-dir` and `NXF_APPTAINER_CACHEDIR`, plus the readability of the checkout and `compat/date`. Consult your cluster’s guidance if a bind is denied.
- **Retry after correcting the cause.** Keep the launch directory and work directory and add `-resume` to reuse successful tasks when Nextflow finds matching cached results.
