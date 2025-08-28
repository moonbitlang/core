# AI Coding Agent Guidelines for MoonBit Core

Welcome to the MoonBit Core repository! This document provides essential guidelines for AI coding agents to be productive and effective contributors to this codebase.

## Project Overview
MoonBit Core is the standard library for the MoonBit language. It is organized into modular packages, each with its own directory. Key files include:
- `moon.pkg.json`: Defines package dependencies.
- `.mbti` files: Generated interfaces for packages, providing a formal description of their public API.
- `.mbt` files: Core implementation files, organized in block style with `///|` separators.
- `_test.mbt` and `_wbtest.mbt`: Blackbox and whitebox test files, respectively.

The top-level `moon.mod.json` file contains metadata about the entire module.

## Key Workflows
1. **Code Formatting and Interface Updates**:
   - Use `moon fmt` to format code.
   - Run `moon info` to update `.mbti` files. If no changes occur, your modifications are safe for external users.

2. **Testing**:
   - Run `moon test` to execute tests.
   - Use `moon test --update` to update snapshots when behavior changes.
   - Analyze test coverage with `moon coverage analyze > uncovered.log`.

3. **Linting**:
   - Use `moon check` to ensure code adheres to linting rules.

## Project-Specific Conventions
- **Block Style Organization**: Code blocks are separated by `///|`. The order of blocks is irrelevant, allowing independent processing.
- **Deprecated Code**: Place deprecated blocks in `deprecated.mbt` files within the respective directory.
- **Testing Practices**: Prefer `inspect` for snapshot testing. Use `assert_eq` sparingly, such as in loops with variable snapshots.

## Integration Points
- **External Dependencies**: Defined per package in `moon.pkg.json`.
- **Cross-Component Communication**: Interfaces are formalized in `.mbti` files, ensuring clear boundaries between packages.

## Examples
- **Adding a New Function**:
  1. Implement the function in a `.mbt` file, using `///|` to separate blocks.
  2. Update the corresponding `.mbti` file with `moon info`.
  3. Write tests in `_test.mbt` or `_wbtest.mbt`.
  4. Format and lint the code with `moon fmt` and `moon check`.

- **Refactoring**:
  1. Modify code block by block.
  2. Ensure no unexpected changes in `.mbti` files after running `moon info`.
  3. Verify tests pass and update snapshots if needed.

## Additional Notes
- Refer to `AGENTS.md` for more detailed refactoring tips.
- Use `agent-todo.md` for small, AI-friendly tasks.

By following these guidelines, AI agents can contribute effectively to the MoonBit Core project. If any section is unclear or incomplete, please provide feedback for improvement!
