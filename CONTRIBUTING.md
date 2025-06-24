# Contributing to moonbitlang/core

## Step 0: Work with a stable toolchain

Contributions to the core should be based on the latest stable channel of the MoonBit toolchains. Using an unknown or unstable version can confuse reviewers and other contributors with new, potentially incompatible changes.

Therefore, we do not encourage users to submit contributions based on bleeding-edge toolchains.
For the latest stable release and installation instructions, contributors can visit https://www.moonbitlang.com/download/.

## Step 1: Clone the repository

- To start working on the project, you need a local copy of the repository. Currently, `moon` looks for moonbitlang/core at `~/.moon/lib/core`. So, remove it if it exists:

  ```bash
  rm -rf ~/.moon/lib/core
  ```

- Then, use the following command to get the latest version of moonbitlang/core:

  ```bash
  git clone https://github.com/moonbitlang/core ~/.moon/lib/core
  ```

- Run the following command to bundle moonbitlang/core:

  ```bash
  moon bundle --source-dir ~/.moon/lib/core
  ```

- If everything goes well, it will generate a bundled core file at `~/.moon/lib/core/target/bundle/core.core`.

- Now, you can create a new project and run it to check if everything is working as expected:

  ```bash
  moon new hello
  cd hello
  echo """fn main {
    println([1, 2, 3].rev())
  }""" > src/main/main.mbt
  moon run src/main
  # Output: [3, 2, 1]
  ```

## Step 2: Make your change

Now it's time to make your changes to the codebase. Whether it's fixing a bug, adding a new feature, or improving documentation, your contributions are welcome. Ensure that your changes are clear and understandable to others who will review your code.

Currently there are some simple restrictions for naming convention and code formatting:

- All function names, method names, and variables should use `snake_case`, while all type names should use `PascalCase`.
- The code formatting should align with the result of `moon fmt`.
- For public functions and types, tests and documentation should be provided. 


## Step 3: Test your change

After making your changes, it's important to test them to ensure they work as expected and do not introduce new issues. Run the following commands to test your changes:

  ```bash
  moon check
  moon test
  moon fmt
  moon bundle
  moon info // Generate mbti files, these files should be tracked by git
  ```

## Testing guidelines

- Prefer `assert_true`, `assert_false` and other `assert_*` helpers over using `inspect` to check results.
- Keep test names concise and descriptive, e.g. `test "push adds an element"`.

## Step 4: Submit a pull request and request a review

Simply follow the standard [GitHub flow](https://docs.github.com/en/get-started/using-github/github-flow) to submit your pull request.

After submitting your pull request, request a review from the project maintainers or other contributors.


# What kind of contributions are more likely to be accepted

- Test, documentation and bug fixes 

- Standalone packages with good functionalities, for example, bigint package

  - Fast and efficient abstractions are preferred over *theoretically perfect* abstractions

    MoonBit is a pragmatic language, we care about both compile time and runtime performance. `+` used to be implemented as a simple
    function for this reason. It is now a trait method, but performance is still a major consideration when designing APIs.

- Large changes are encouraged to communicate earlier before the implementation

   The core library is coupled with the compiler to some extent, it is better to communicate your ideas first if you 
  plan to make large structural changes.

# API design principles

- Use methods when the behavior naturally belongs to a type, otherwise prefer free functions.
- Only include functions in the standard library when they have broad usage or provide significant performance advantages.
- Prefer `for i in 0..<length` or `for x in array` style loops over `for i = 0; i < length; i = i + 1`.
- Use `arr[i]` for bounds-checked access and `arr.unsafe_get(i)` only when the index is known to be valid.

# Naming conventions

- function names, `snake_case` is preferred.
- type parameters use single letters starting from `A` by default. For example `fn[A,B] Array::map(self : Array[A], f : (A) -> (B)) -> Array[B]`.
  Map-like containers continue to use `Map[K,V]` and sets may use `[K]` when the elements are treated as keys.
- type names, `CamelCase` is preferred, if one package is centered around one specific type, short name `T` is preferred, e.g, `@sorted_set.T`.
