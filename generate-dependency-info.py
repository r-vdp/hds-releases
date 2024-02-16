#! /usr/bin/env python3

import argparse
import json
import subprocess

from dataclasses import dataclass


@dataclass(frozen=True)
class BuildInfo:
    drvPath: str
    output: str


def build(attr: str) -> BuildInfo:
    p = subprocess.run(
        ["nix", "build", "--json", attr],
        text=True,
        capture_output=True,
    )
    p.check_returncode()
    buildinfo = json.loads(p.stdout)[0]
    return BuildInfo(buildinfo["drvPath"], buildinfo["outputs"])


def dependency_info(outpath: str) -> list[dict]:
    def getpathinfo(outpath: str) -> dict:
        p = subprocess.run(
            ["nix", "derivation", "show", outpath], text=True, capture_output=True
        )
        p.check_returncode()
        drvInfo = json.loads(p.stdout)
        # We always have only one result since we only pass one
        # outpath to nix derivation show
        drvpath = list(drvInfo.keys())[0]

        p = subprocess.run(
            [
                "jq",
                f"""
                  .[].outputs |
                  to_entries |
                  map(
                    select(.value.path == "{outpath}") |
                    .value |= .path
                  ) |
                  # We always have only one result since only one output can
                  # match our outpath
                  .[0] |
                  {{ drvPath: "{drvpath}", output: .key, outPath: .value }}
                """,
            ],
            text=True,
            capture_output=True,
            input=p.stdout,
        )
        p.check_returncode()
        return json.loads(p.stdout)

    p = subprocess.run(
        ["nix-store", "--query", "--references", outpath],
        text=True,
        capture_output=True,
    )
    p.check_returncode()
    return list(map(getpathinfo, p.stdout.splitlines()))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("attr", type=str)
    args = parser.parse_args()

    buildinfo = build(args.attr)
    print(json.dumps(dependency_info(buildinfo.output["out"]), indent=2))


if __name__ == "__main__":
    main()
