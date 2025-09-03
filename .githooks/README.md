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

- ✅ **moon check** - Validates code syntax, types, and formatting
- ❌ **Blocks commit** if any issues are found
- 💡 **Suggests fixes** like running `moon fmt`

### Usage

The hooks run automatically when you commit:

```bash
git commit -m "your message"
# → Runs moon check automatically
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

### Hook fails due to type errors

Fix the reported type errors and try committing again. The hook output will show specific error locations.

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
