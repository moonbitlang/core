# MoonBit Git Hooks

This directory contains Git hooks to ensure code quality and consistency in the MoonBit core library.

## Setup

To enable the hooks for this repository, run:

```bash
./.githooks/setup.sh
```

Or manually configure:

```bash
git config core.hooksPath .githooks
chmod +x .githooks/*
```

## Available Hooks

### pre-commit

Runs before each commit to ensure code quality:

- ✅ **moon fmt** - Formats the staged MoonBit sources in place
- ❌ **Blocks commit** if formatting changed any file, so the formatted
  version is what gets committed
- 💡 **Suggests the fix** - `git add . && git commit`

> The `moon check` step is present in `pre-commit` but commented out, so
> syntax and type errors are **not** caught at commit time — CI is what
> catches them today.

### Usage

The hooks run automatically when you commit:

```bash
git commit -m "your message"
# → Runs moon fmt automatically, and blocks the commit if it reformatted anything
```

To bypass hooks temporarily (not recommended for production):

```bash
git commit --no-verify -m "your message"
```

## Troubleshooting

### Hook fails with "moon command not found"

Install the MoonBit toolchain:
- Visit: https://www.moonbitlang.com/download/
- Follow the installation instructions for your platform

### Hook fails due to formatting issues

Run the auto-formatter:

```bash
moon fmt
```

### The commit succeeded but CI reports type errors

The hook does not run `moon check` (that step is commented out in
`pre-commit`), so type errors reach CI. Run `moon check` yourself before
pushing.

## Contributing

When adding new hooks:

1. Create the hook file in `.githooks/`
2. Make it executable: `chmod +x .githooks/hook-name`
3. Update this README
4. Test the hook thoroughly

## Philosophy

These hooks enforce quality standards to:
- 🐛 **Catch errors early** before they reach CI/CD
- 🎨 **Maintain consistent formatting** across the codebase  
- ⚡ **Speed up development** by providing immediate feedback
- 🤝 **Help contributors** follow project conventions
