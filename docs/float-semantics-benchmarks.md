# Floating comparison benchmarks

Measured 2026-10-15 on Apple M4 Max (arm64, macOS 15.7.9), Apple clang 16.0.0, Moon/moonrun 0.1.20261012, Node v23.11.1. Both versions use the same locally built compiler based on 89c60fd5e with floating operator resolution and constant-folding changes. Baseline core: 88920358; candidate: this PR.

Each callback processes 4096 values. Values below are microseconds per callback: median of three independent process-run means, each using 10 calibrated batches. Run order is baseline/candidate, candidate/baseline, baseline/candidate, sequentially. Positive delta means slower. The suite includes finite and 1-in-16 NaN inputs, plus finite collection operations and an arithmetic control. Measurements are local microbenchmarks, not a prediction for every application or architecture.

## native

| Workload | Baseline µs | Candidate µs | Delta |
| --- | ---: | ---: | ---: |
| Double eq finite | 1.44 | 1.55 | 7.64% |
| Double lt finite | 1.44 | 1.44 | 0% |
| Double compare finite | 2.09 | 4.15 | 98.56% |
| Double hash finite | 18.56 | 18.51 | -0.27% |
| Double eq nan-1-in-16 | 1.44 | 1.54 | 6.94% |
| Double lt nan-1-in-16 | 1.44 | 1.44 | 0% |
| Double compare nan-1-in-16 | 2.08 | 4.11 | 97.6% |
| Double hash nan-1-in-16 | 18.53 | 18.5 | -0.16% |
| Float eq finite | 1.45 | 1.55 | 6.9% |
| Float lt finite | 1.45 | 1.45 | 0% |
| Float compare finite | 2.08 | 4.12 | 98.08% |
| Float hash finite | 18.55 | 18.58 | 0.16% |
| Float eq nan-1-in-16 | 1.45 | 1.54 | 6.21% |
| Float lt nan-1-in-16 | 1.45 | 1.44 | -0.69% |
| Float compare nan-1-in-16 | 2.09 | 4.11 | 96.65% |
| Float hash nan-1-in-16 | 18.56 | 18.53 | -0.16% |
| Double sort finite | 47.49 | 48.16 | 1.41% |
| Double map lookup finite | 46.86 | 47.49 | 1.34% |
| Double arithmetic control | 2.22 | 2.24 | 0.9% |

Raw output: [baseline 1](float-benchmark-data/float-bench-native-baseline-1.log), [candidate 1](float-benchmark-data/float-bench-native-candidate-1.log).
[baseline 2](float-benchmark-data/float-bench-native-baseline-2.log), [candidate 2](float-benchmark-data/float-bench-native-candidate-2.log).
[baseline 3](float-benchmark-data/float-bench-native-baseline-3.log), [candidate 3](float-benchmark-data/float-bench-native-candidate-3.log).


## wasm-gc

| Workload | Baseline µs | Candidate µs | Delta |
| --- | ---: | ---: | ---: |
| Double eq finite | 4.14 | 5.13 | 23.91% |
| Double lt finite | 4.34 | 5.04 | 16.13% |
| Double compare finite | 4.14 | 6.39 | 54.35% |
| Double hash finite | 16.31 | 16.56 | 1.53% |
| Double eq nan-1-in-16 | 4.08 | 5.11 | 25.25% |
| Double lt nan-1-in-16 | 4.52 | 5.1 | 12.83% |
| Double compare nan-1-in-16 | 4.15 | 6.47 | 55.9% |
| Double hash nan-1-in-16 | 16.29 | 16.67 | 2.33% |
| Float eq finite | 4.18 | 5.1 | 22.01% |
| Float lt finite | 4.32 | 5.04 | 16.67% |
| Float compare finite | 4.17 | 6.37 | 52.76% |
| Float hash finite | 6.14 | 10.89 | 77.36% |
| Float eq nan-1-in-16 | 4.12 | 5.12 | 24.27% |
| Float lt nan-1-in-16 | 4.5 | 5.15 | 14.44% |
| Float compare nan-1-in-16 | 4.14 | 6.47 | 56.28% |
| Float hash nan-1-in-16 | 6.14 | 10.87 | 77.04% |
| Double sort finite | 62.05 | 68.31 | 10.09% |
| Double map lookup finite | 60.62 | 62.3 | 2.77% |
| Double arithmetic control | 2.77 | 2.74 | -1.08% |

Raw output: [baseline 1](float-benchmark-data/float-bench-wasm-gc-baseline-1.log), [candidate 1](float-benchmark-data/float-bench-wasm-gc-candidate-1.log).
[baseline 2](float-benchmark-data/float-bench-wasm-gc-baseline-2.log), [candidate 2](float-benchmark-data/float-bench-wasm-gc-candidate-2.log).
[baseline 3](float-benchmark-data/float-bench-wasm-gc-baseline-3.log), [candidate 3](float-benchmark-data/float-bench-wasm-gc-candidate-3.log).


## js

| Workload | Baseline µs | Candidate µs | Delta |
| --- | ---: | ---: | ---: |
| Double eq finite | 3.33 | 6.05 | 81.68% |
| Double lt finite | 3.94 | 5.15 | 30.71% |
| Double compare finite | 3.17 | 9.95 | 213.88% |
| Double hash finite | 106.16 | 114.78 | 8.12% |
| Double eq nan-1-in-16 | 4.65 | 8.15 | 75.27% |
| Double lt nan-1-in-16 | 4.78 | 7.1 | 48.54% |
| Double compare nan-1-in-16 | 5.01 | 12.09 | 141.32% |
| Double hash nan-1-in-16 | 109.2 | 112.81 | 3.31% |
| Float eq finite | 3.46 | 6.06 | 75.14% |
| Float lt finite | 3.9 | 5.18 | 32.82% |
| Float compare finite | 3.17 | 10.16 | 220.5% |
| Float hash finite | 4.31 | 5.93 | 37.59% |
| Float eq nan-1-in-16 | 4.63 | 8.17 | 76.46% |
| Float lt nan-1-in-16 | 4.75 | 7.01 | 47.58% |
| Float compare nan-1-in-16 | 4.94 | 12.1 | 144.94% |
| Float hash nan-1-in-16 | 4.26 | 6.04 | 41.78% |
| Double sort finite | 66.86 | 92.54 | 38.41% |
| Double map lookup finite | 212.15 | 210.85 | -0.61% |
| Double arithmetic control | 2.68 | 2.65 | -1.12% |

Raw output: [baseline 1](float-benchmark-data/float-bench-js-baseline-1.log), [candidate 1](float-benchmark-data/float-bench-js-candidate-1.log).
[baseline 2](float-benchmark-data/float-bench-js-baseline-2.log), [candidate 2](float-benchmark-data/float-bench-js-candidate-2.log).
[baseline 3](float-benchmark-data/float-bench-js-baseline-3.log), [candidate 3](float-benchmark-data/float-bench-js-candidate-3.log).


The primary timing snapshot preceded follow-up fixes to constant-pattern handling and numerical-helper NaN control flow. Those changes do not alter the timed comparison/hash definitions or occur in these finite collection workloads. Supplemental equality runs below use the final compiler.

## Equality success paths

These additional runs use the final compiler implementation (aa5f69cb), fresh build directories, and the same three interleaved repetitions. Equal-finite pairs contain identical numbers. Paired-NaN pairs contain identical numbers except for an aligned NaN every 16 elements. Mixed pairs alternate matching and nonmatching values, including aligned NaNs. The original equality rows above use reversed arrays and have no successful equality cases; they should be interpreted as unequal-input throughput.

### native

| Workload | Baseline µs | Candidate µs | Delta |
| --- | ---: | ---: | ---: |
| Double eq equal-finite | 1.41 | 1.53 | 8.51% |
| Float eq equal-finite | 1.41 | 1.53 | 8.51% |
| Double eq paired-nan | 1.41 | 1.54 | 9.22% |
| Float eq paired-nan | 1.41 | 1.54 | 9.22% |
| Double eq mixed | 1.41 | 1.54 | 9.22% |
| Float eq mixed | 1.42 | 1.54 | 8.45% |

Raw output: [baseline 1](float-benchmark-data/float-equality-native-baseline-1.log), [candidate 1](float-benchmark-data/float-equality-native-candidate-1.log).
[baseline 2](float-benchmark-data/float-equality-native-baseline-2.log), [candidate 2](float-benchmark-data/float-equality-native-candidate-2.log).
[baseline 3](float-benchmark-data/float-equality-native-baseline-3.log), [candidate 3](float-benchmark-data/float-equality-native-candidate-3.log).

### wasm-gc

| Workload | Baseline µs | Candidate µs | Delta |
| --- | ---: | ---: | ---: |
| Double eq equal-finite | 4.1 | 4.51 | 10% |
| Float eq equal-finite | 4.05 | 4.84 | 19.51% |
| Double eq paired-nan | 4.02 | 4.6 | 14.43% |
| Float eq paired-nan | 4.04 | 4.76 | 17.82% |
| Double eq mixed | 4.03 | 4.74 | 17.62% |
| Float eq mixed | 3.99 | 4.78 | 19.8% |

Raw output: [baseline 1](float-benchmark-data/float-equality-wasm-gc-baseline-1.log), [candidate 1](float-benchmark-data/float-equality-wasm-gc-candidate-1.log).
[baseline 2](float-benchmark-data/float-equality-wasm-gc-baseline-2.log), [candidate 2](float-benchmark-data/float-equality-wasm-gc-candidate-2.log).
[baseline 3](float-benchmark-data/float-equality-wasm-gc-baseline-3.log), [candidate 3](float-benchmark-data/float-equality-wasm-gc-candidate-3.log).

### js

| Workload | Baseline µs | Candidate µs | Delta |
| --- | ---: | ---: | ---: |
| Double eq equal-finite | 3.73 | 3.68 | -1.34% |
| Float eq equal-finite | 3.08 | 2.93 | -4.87% |
| Double eq paired-nan | 4.7 | 5.37 | 14.26% |
| Float eq paired-nan | 4.74 | 5.37 | 13.29% |
| Double eq mixed | 4.47 | 7.28 | 62.86% |
| Float eq mixed | 4.62 | 7.25 | 56.93% |

Raw output: [baseline 1](float-benchmark-data/float-equality-js-baseline-1.log), [candidate 1](float-benchmark-data/float-equality-js-candidate-1.log).
[baseline 2](float-benchmark-data/float-equality-js-baseline-2.log), [candidate 2](float-benchmark-data/float-equality-js-candidate-2.log).
[baseline 3](float-benchmark-data/float-equality-js-baseline-3.log), [candidate 3](float-benchmark-data/float-equality-js-candidate-3.log).
