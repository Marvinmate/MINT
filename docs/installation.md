# Installation

MINT requires **Nextflow 26.04.6 or later**. Java 21 is a compatible choice for running Nextflow. Choose Docker for a workstation or Apptainer on a Linux cluster. Both container profiles use the published Linux AMD64 image.

## Windows 10 and 11

Run the following in **PowerShell as Administrator** on a Windows release supported by WSL and Docker Desktop. Restart when prompted, open Ubuntu to create your Linux user, and verify that the distribution runs under WSL 2.

```powershell
wsl --install -d Ubuntu
wsl --list --verbose
```

If Ubuntu is listed as version 1, run `wsl --set-version Ubuntu 2` from PowerShell. Use the distribution name shown in the list if it differs. [Microsoft WSL installation guide](https://learn.microsoft.com/en-us/windows/wsl/install)

Install [Docker Desktop for Windows](https://docs.docker.com/desktop/setup/install/windows-install/) and start it. In **Settings → General**, select the WSL 2 engine if the choice is visible. Under **Settings → Resources → WSL Integration**, enable your Ubuntu distribution and apply the changes. Use Linux containers. [Docker WSL integration guide](https://docs.docker.com/desktop/features/wsl/)

Open the **Ubuntu terminal** and install Java and the command-line prerequisites. Run Nextflow and keep the MINT checkout and input files in the Ubuntu filesystem, such as under your Linux home directory.

```bash
sudo apt update
sudo apt install openjdk-17-jdk curl git
docker --version
docker info
java -version
```

Java 17 is supported by Nextflow 26.04.6. Follow the [Nextflow installation](#install-nextflow-and-get-mint) steps from this Ubuntu terminal.

## macOS

Install and start [Docker Desktop for Mac](https://docs.docker.com/desktop/setup/install/mac-install/), choosing the download for your processor. On Apple Silicon, Docker runs MINT's AMD64 image through emulation. Install a [Temurin JDK 21](https://adoptium.net/temurin/releases/?version=21) for your processor and check both tools from Terminal.

```bash
docker --version
docker info
java -version
git --version
```

If macOS prompts for command-line developer tools when you run Git, complete that installation before cloning. Continue to [Nextflow installation](#install-nextflow-and-get-mint).

## Linux workstation

Install a supported JDK, Git, and curl through your distribution's package manager. For Ubuntu 24.04, for example:

```bash
sudo apt update
sudo apt install openjdk-21-jdk curl git
java -version
```

For Docker, follow the [Docker Engine installation guide](https://docs.docker.com/engine/install/) for your distribution and its instructions for access from your user account. Verify `docker --version` and `docker info`. For Apptainer, follow the [Apptainer installation guide](https://apptainer.org/docs/admin/latest/installation.html) and verify `apptainer --version`. Then [install Nextflow](#install-nextflow-and-get-mint).

## HPC with Apptainer and Slurm

Use the cluster's software modules or administrator-provided installations. Module names and account assignments vary by site. On the cluster, check that your shell can find the tools and that Slurm can list the available partitions.

```bash
java -version
nextflow -version
apptainer --version
sbatch --version
sinfo
```

Use the cluster's Nextflow installation if it meets the minimum. If your site permits a user installation, use the following steps with the site-provided Java runtime. Confirm which filesystem is shared by the submission and compute nodes, which partition and account to use, and where the cluster permits you to run the Nextflow driver. See [Run on Slurm](running-mint.md#run-on-slurm) for the work directory and image cache.

## Install Nextflow and get MINT

From a Bash-compatible shell with Java available, install Nextflow in your user account. The example installs the minimum supported release. Add the `export PATH` line to your shell startup file to keep the command available in new terminals. [Nextflow installation guide](https://docs.seqera.io/nextflow/install)

```bash
curl -fsSL https://get.nextflow.io -o nextflow-installer.sh
NXF_VER=26.04.6 bash < nextflow-installer.sh
mkdir -p "$HOME/.local/bin"
install -m 755 nextflow "$HOME/.local/bin/nextflow"
export PATH="$HOME/.local/bin:$PATH"
nextflow -version
```

From the directory where you want to keep the checkout:

```bash
git clone https://github.com/Marvinmate/MINT.git
cd MINT
nextflow run MINT.nf --help
```

Skip the clone if you already have a checkout and open that directory instead. The first containerized run requires registry access unless the image is already available locally.

## Building these docs

From the repository root, use Python 3.12 to build and preview the site locally.

```bash
python3.12 -m venv .venv-docs
source .venv-docs/bin/activate
python -m pip install -r docs/requirements.txt
mkdocs build --strict
mkdocs serve
```

Read the Docs uses the root configuration file and the same dependency list. After the repository is connected in the Read the Docs dashboard, the GitHub integration triggers builds on updates to enabled versions. The documentation build uses only the source pages and example figures. [Read the Docs setup guide for MkDocs](https://docs.readthedocs.com/platform/stable/intro/mkdocs.html)
