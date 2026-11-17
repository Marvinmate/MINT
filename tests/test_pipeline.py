"""Exercise the distributed pipeline with the pinned Docker image."""
import argparse
import csv
import json
import os
from pathlib import Path
import shutil
import subprocess

from openpyxl import load_workbook
from PIL import Image

PROJECT = Path(__file__).resolve().parents[1]
MODULES = ("mep", "csp", "ihi")


def rows(path, delimiter="\t"):
    with path.open(encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle, delimiter=delimiter))


def traces(output):
    return rows(output / "execution/trace.tsv")


def verify_run(output, rate, slim):
    trace = traces(output)
    assert trace and all(task["status"] in {"COMPLETED", "CACHED"} for task in trace)
    assert all(any(task["name"].startswith(name) for task in trace) for name in
               ("MEP_ANALYSIS", "CSP_ANALYSIS", "IHI_ANALYSIS", "MULTIQC_REPORT"))
    figures = sorted(output.rglob("*.png"))
    assert figures and any(".csp_durations_" in f.name for f in figures)
    assert not list(output.rglob("*.pdf")) and not list(output.rglob("*.svg"))
    for figure in figures:
        with Image.open(figure) as image:
            assert image.format == "PNG"
            assert all(abs(value - 300) < 0.01 for value in image.info["dpi"])
            image.verify()
        if slim:
            assert figure.with_suffix(".csv").is_file()

    if slim:
        rendered_ihi = list((output / "slim/IHI").glob("*.graphics.json"))
        assert len(rendered_ihi) == 1
        details = json.loads(rendered_ihi[0].read_text())
        classes = {details["classes"][trial - 1] for trial in details["detail_trials"][0]}
        assert classes == {"Unconditioned_MEP", "IHI_10ms", "IHI_40ms"}

    for module in MODULES:
        directory = output / module / "data"
        tables = sorted(directory.glob("*.tsv"))
        assert tables
        for table in tables:
            assert rows(table) == rows(table.with_suffix(".csv"), ","), table
    mep_tables = list((output / "mep/data").glob("*.mep.tsv"))
    assert len(mep_tables) == 4
    for table in mep_tables:
        data = rows(table)
        assert len(data) == 4
        assert all(row["Visit"] == "Dose test" and int(row["Sampling_Rate_Hz"]) == rate
                   and row["Included"] == "1" and row["Prestim_Status"] == "Disabled"
                   for row in data), table

    for table in (output / "ihi/data").glob("*.ihi.tsv"):
        trial_rows = rows(table)
        assert [r["Condition"] for r in trial_rows] == [
            "Unconditioned_MEP", "IHI_10ms", "IHI_40ms", "IHI_40ms"]
        assert all(r["Test_Pulse_Index"] == r["Test_TTL_End"] for r in trial_rows)
        assert trial_rows[0]["Conditioning_Pulse_Index"] == "NA"
    for table in (output / "csp/data").glob("*.csp.tsv"):
        csp_rows = rows(table)
        assert [r["Breakthrough"] for r in csp_rows] == ["0", "1", "0", "1"]
        assert all(r["CSP_Method"] == "breakthrough-aware" for r in csp_rows)

    report = output / "multiqc"
    assert (report / "multiqc_report.html").stat().st_size > 1000
    evidence = json.loads((report / "custom_content/report_evidence.json").read_text())
    assert evidence["sampling_rates_hz"] in (rate, [rate])
    assert evidence["recordings"] == 4 and evidence["trials"] == 16
    return {"tasks": len(trace), "png_300_dpi": len(figures), "recordings": 4, "trials": 16}


def workbook_rows(path):
    workbook = load_workbook(path, read_only=True, data_only=True)
    try:
        return {sheet.title: list(sheet.values) for sheet in workbook}
    finally:
        workbook.close()


def compare_modes(standard, slim):
    count = 0
    for module in MODULES:
        paths = sorted(p.relative_to(standard) for p in (standard / module / "data").iterdir()
                       if p.suffix in {".csv", ".tsv", ".xlsx"})
        assert paths == sorted(p.relative_to(slim) for p in (slim / module / "data").iterdir()
                               if p.suffix in {".csv", ".tsv", ".xlsx"})
        for path in paths:
            a, b = standard / path, slim / path
            if path.suffix == ".xlsx":
                assert workbook_rows(a) == workbook_rows(b), path
            else:
                assert a.read_bytes() == b.read_bytes(), path
            count += 1
    assert count and len(list(standard.rglob("*.xlsx"))) == 2
    ledger = Path("multiqc/custom_content/report_values.tsv")
    assert (standard / ledger).read_bytes() == (slim / ledger).read_bytes()
    return count


def launch(work, rate, slim, resume=False):
    mode = "slim" if slim else "standard"
    run = work / f"{rate}-{mode}"
    run.mkdir(exist_ok=True)
    output = run / "results"
    args = [
        "nextflow", "run", str(PROJECT / "MINT.nf"), "-profile", "docker",
        "--input", str(work / "input" / str(rate)), "--outdir", str(output),
        "--strict_timepoints", "false", "--slim", str(slim).lower(),
        "-work-dir", str(run / "work"), "-ansi-log", "false",
    ]
    if resume:
        args.append("-resume")
    log = run / ("resume.log" if resume else "run.log")
    print(f"{rate} Hz {mode}{' resume' if resume else ''} → {log}", flush=True)
    with log.open("w") as handle:
        subprocess.run(args, cwd=run, check=True, stdout=handle, stderr=subprocess.STDOUT)
    return output


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("work", type=Path, help="new output directory outside the distribution")
    work = parser.parse_args().work.resolve()
    if work.is_relative_to(PROJECT):
        parser.error("choose a test directory outside the distribution")
    work.mkdir(parents=True)
    shutil.copytree(PROJECT / "tests/fixtures", work / "input",
                    ignore=shutil.ignore_patterns("README.md"))

    # Reuse the synthetic signal at a second timepoint to exercise slim selection.
    for fixture in sorted((work / "input").rglob("*_T0.mat")):
        shutil.copyfile(fixture, fixture.with_name(fixture.name.replace("_T0.mat", "_T1.mat")))

    settings = json.loads((PROJECT / "assets/scientific_params.json").read_text())
    assert settings["prestim_qc_enabled"] is False
    report = {}
    for rate in (1000, 4000):
        standard = launch(work, rate, False)
        slim = launch(work, rate, True)
        report[rate] = {"standard": verify_run(standard, rate, False),
                        "slim": verify_run(slim, rate, True),
                        "identical_exports": compare_modes(standard, slim)}
        assert report[rate]["slim"]["png_300_dpi"] < report[rate]["standard"]["png_300_dpi"]

    fixture = next((work / "input/4000/IHI").rglob("*_T0.mat"))
    initial = fixture.stat()
    os.utime(fixture, ns=(initial.st_atime_ns, initial.st_mtime_ns + 60_000_000_000))
    assert fixture.stat().st_mtime_ns != initial.st_mtime_ns
    resumed = launch(work, 4000, False, resume=True)
    cached = [row for row in traces(resumed) if row["status"] == "CACHED"]
    # Downstream tasks may include regenerated metadata. The source analysis is the
    # direct test for an unchanged MAT whose modification time was changed.
    assert sum(row["name"].startswith("MEP_ANALYSIS") for row in cached) == 4
    report["mtime_resume"] = {"profile": "docker", "cached": len(cached),
                              "tasks": len(traces(resumed)), "meps_cached": 4}
    (work / "checks.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
