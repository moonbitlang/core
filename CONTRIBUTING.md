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
  be updated easily. For testing in the loop, you may use `assert_` since snapshot testing does not work well in the loop.

- New APIs with real meat

  We encourage you to add new APIs that are useful and have real meat, rather than just adding APIs for the sake of completeness.
  If the new API can be composed with existing APIs without loosing efficiency, it is better to use the existing APIs instead of adding new ones, this is due to our current limited bandwidth of the core library.

# Naming conventions

- function names, `snake_case` is preferred.
- type parameters, one character starting from `A` is preferred, e.g, `fn[A,B] Array::map(self : Array[A], f : (A) -> (B)) -> Array[B]`, for some established
  conventions, `Map[K,V]` it is also accepted.
- type names, `CamelCase` is preferred.
