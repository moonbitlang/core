# moonbitlang/core

[![check](https://github.com/moonbitlang/core/actions/workflows/stable-check.yml/badge.svg)](https://github.com/moonbitlang/core/actions/workflows/stable-check.yml) [![Coverage Status](https://coveralls.io/repos/github/moonbitlang/core/badge.svg?branch=main)](https://coveralls.io/github/moonbitlang/core?branch=main)

moonbitlang/core is the standard library of the [MoonBit language](https://www.moonbitlang.com/). It is released alongside the compiler. You can view the documentation for the latest official release at <https://mooncakes.io/docs/moonbitlang/core/>. This repository serves as the development repository.

## Current status

It is experimental and under active development. At this early stage, our primary focus is on enhancing the functionality of `moonbitlang/core`.

⚠️**The API is subject to change.**

### Timeline

The core is making large changes in the last few months, we are expected to reach beta-preview status in mid-August.

## Contributing

We are actively developing moonbitlang/core and appreciate your help!

To contribute, please read the contribution guidelines at [CONTRIBUTING.md](./CONTRIBUTING.md).

## MBTI Reviewer Tool

The repository includes a tool to review MoonBit interface (MBTI) definitions using OpenAI. This tool:

1. Extracts the interface definitions for specified MoonBit types using `mbti-inspector.exe`
2. Stores these interfaces in a readable format
3. Uses OpenAI to review the interfaces and provide feedback on API design
4. Saves the AI-generated review for further analysis

### How to Use

1. Make sure you have Node.js installed
2. Copy `.env.example` to `.env` and add your OpenAI API key
3. Ensure `mbti-inspector.exe` is available in your PATH
4. Run the tool:

```bash
node index.mjs
```

The tool will:
- Extract and save interfaces to the `mbti_data` directory
- Generate and save reviews to the `mbti_reviews` directory

### Being a collaborator

Note we regularly evaluate external contributions and invite active contributors to join us as collaborators, thank you!
To keep the contributors manageable, we will revoke commit rights if external collaborators are not active for over 6 months.
