# moonbitlang/core

[![check](https://github.com/moonbitlang/core/actions/workflows/stable-check.yml/badge.svg)](https://github.com/moonbitlang/core/actions/workflows/stable-check.yml) [![Coverage Status](https://coveralls.io/repos/github/moonbitlang/core/badge.svg?branch=main)](https://coveralls.io/github/moonbitlang/core?branch=main)
[![doc](https://img.shields.io/badge/docs-mooncakes.io-green)](https://mooncakes.io/docs/moonbitlang/core)




moonbitlang/core is the standard library of the [MoonBit language](https://www.moonbitlang.com/). It is released alongside the compiler. You can view the documentation for the latest official release at <https://mooncakes.io/docs/moonbitlang/core/>. This repository serves as the development repository.

## Architecture at a glance

Almost every package in this repository sits on top of `builtin`, which is
available in every MoonBit program without an import (`builtin` itself
bootstraps on the tiny `abort` package). `prelude` is opened automatically
and re-exports the commonly used names from `builtin` plus a few companions
(`Debug`, `BigInt`, `Ref`, `Lazy`, test assertions, …). Everything else is an
ordinary package imported as `moonbitlang/core/<pkg>` and used via `@<pkg>`:

```mermaid
graph BT
  builtin["<b>builtin</b> (implicitly available, no import)<br/>Array · FixedArray · Map · String · Bytes · views<br/>Iter · StringBuilder · Json<br/>traits: Eq · Compare · Hash · Show · ToJson · Default"]
  prelude["<b>prelude</b> — auto-opened re-exports<br/>from builtin, debug, test, bigint, …"] --> builtin
  values["<b>value types</b><br/>bool · byte · char · unit · option · result<br/>error · ref · tuple · cmp · range · lazy"] --> builtin
  numbers["<b>numerics</b><br/>int · uint · int16 · uint16 · int64 · uint64<br/>double · float · bigint · v128 · math"] --> builtin
  text["<b>text & binary</b><br/>string · bytes · buffer · encoding/*<br/>strconv · lexbuf"] --> builtin
  mut["<b>mutable collections</b><br/>array · hashmap · hashset · deque · queue<br/>priority_queue · set · sorted_map · sorted_set"] --> builtin
  imm["<b>immutable collections</b><br/>list · lazy_list · immut/array<br/>immut/hashmap · immut/sorted_map · …"] --> builtin
  tools["<b>algorithms & tooling</b><br/>json · diff · random · quickcheck · argparse<br/>bench · test · debug · env"] --> builtin
```

## Current status

It is experimental and under active development. At this early stage, our primary focus is on enhancing the functionality of `moonbitlang/core`.

⚠️**The API is subject to change.**

### Timeline

The core is making large changes in the last few months, we are expected to reach beta-preview status in mid-August.

## Contributing

We are actively developing moonbitlang/core and appreciate your help!

To contribute, please read the contribution guidelines at [CONTRIBUTING.md](./CONTRIBUTING.md).

### Being a collaborator

Note we regularly evaluate external contributions and invite active contributors to join us as collaborators, thank you!
To keep the contributors manageable, we will revoke commit rights if external collaborators are not active for over 6 months.
