# Parallel Doc Runner

Runs Codex subagents in parallel to update inline docs per package.

## Usage

```sh
cd tools/parallel_doc_runner
CODEX_WORKDIR=/Users/yezihang/Documents/program/idea/core \
DOC_PARALLELISM=6 \
moon run .
```

Optional environment variables:
- `DOC_RUN_ID` to label target output directories (defaults to a random number).
- `DOC_PARALLELISM` to set concurrency (default: 4).
- `DOC_OFFSET` to start from a specific package index (default: 0).
- `DOC_LIMIT` to cap how many packages run in this batch (default: 0, meaning no limit).
- `DOC_OUTPUT_DIR` to override output directory (default: `target/doc_runner/results/<run_id>`).
- `CODEX_WORKDIR` to point at the repo root (default: `../..`).

Each subagent prompt tells workers to run `moon check` and `moon test` with a
unique `--target-dir target/doc_runner/<run_id>/<random>` to avoid conflicts.

The runner writes `run_manifest.txt` in the output directory so you can track
the package list for a given run ID, including `next_offset`.

It also writes a `_progress/` marker file per package and skips packages whose
output file already exists, so you can safely resume or rerun without guessing.
