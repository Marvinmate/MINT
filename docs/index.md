# MINT

MINT (Motor Interhemispheric Neurophysiology Toolbox) analyzes exported LabChart recordings from transcranial magnetic stimulation (TMS) experiments. It measures motor evoked potential (MEP) amplitudes, estimates cortical silent period (CSP) durations, and classifies interhemispheric inhibition (IHI) protocol trials by their stimulation timing.

Nextflow runs the analyses and tracks their inputs. The Docker and Apptainer profiles use the same published container, which includes GNU Octave, the graphics tools, and MultiQC. MINT writes trial-level tables, scientific figures, and an interactive quality-control report.

1. [Install MINT](installation.md) on a workstation or cluster.
2. [Prepare your LabChart exports](input-data.md) and check their channel order and naming.
3. [Select and run the analyses](running-mint.md).
4. [Review the results](outputs.md) alongside the [measurement methods](analysis-modules.md).

For build and deployment instructions for this documentation, see [Building these docs](installation.md#building-these-docs).
