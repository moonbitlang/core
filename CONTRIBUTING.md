# Contributing to moonbitlang/core

## Step 0: Work with a stable toolchain

Contributions to the core should be based on the latest stable channel of the MoonBit toolchains. Using an unknown or unstable version can confuse reviewers and other contributors with new, potentially incompatible changes.

Therefore, we do not encourage users to submit contributions based on bleeding-edge toolchains.
For the latest stable release and installation instructions, contributors can visit https://www.moonbitlang.com/download/.

## Step 1: Clone the repository

Clone the repository into a separate working directory and run the tools from its root:

```bash
git clone https://github.com/moonbitlang/core.git
cd core
moon check
moon test
```

These commands use the core sources in this checkout. There is no need to remove
or replace the standard library installed with your toolchain in `~/.moon/lib/core`.
Package dependencies are declared in `moon.pkg`; module metadata is in `moon.mod`.
Generated build artifacts go under `_build/` by default.

To verify that the core can be bundled for all supported targets, run:

```bash
moon bundle --all
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
  moon bundle --all
  moon info # Regenerate tracked package interfaces (.mbti)
  moon fmt
  ```

Review the `.mbti` diff to confirm that public API changes are intentional. For
changes that depend on backend behavior, also run `moon test --target all` and
the relevant release-mode tests, as CI does.

## Step 4: Submit a pull request and request a review

Simply follow the standard [GitHub flow](https://docs.github.com/en/get-started/using-github/github-flow) to submit your pull request.

After submitting your pull request, request a review from the project maintainers or other contributors.


# What kind of contributions are more likely to be accepted

- Test, documentation and bug fixes 

- Standalone packages with good functionalities, for example, bigint or bigdecimal package

- Fast and efficient abstractions are preferred over *theoretically perfect* abstractions

   MoonBit is a pragmatic language, we care about both compile time and runtime performance. We don't encourage to add traits for non pervasive abstractions.

- Large changes are encouraged to communicate earlier before the implementation

   The core library is coupled with the compiler to some extent, it is better to communicate your ideas first if you 
   plan to make large structural changes.  

- Testing guidelines

  We encourage you to use `inspect` over `assert` in tests, as `inspect` provides more information about the values being tested and can
  be updated easily. For testing in the loop, you may use `assert_eq`/`assert_true` since snapshot testing does not work well in the loop.

- New APIs with real meat

  We encourage you to add new APIs that are useful and have real meat, rather than just adding APIs for the sake of completeness.
  If the new API can be composed with existing APIs without losing efficiency, it is better to use the existing APIs instead of adding new ones, this is due to our current limited bandwidth of the core library.

# Naming conventions

- function names, `snake_case` is preferred.
- type parameters, one character starting from `A` is preferred, e.g, `fn[A,B] Array::map(self : Array[A], f : (A) -> (B)) -> Array[B]`, for some established
  conventions, `Map[K,V]` it is also accepted.
- type names, `CamelCase` is preferred.
