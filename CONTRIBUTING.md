# Contributing to moonbitlang/core

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

- Standalone packages with good functionalites, for example, bigint package

- Fast and efficient abstractions are preferred over *theoretically perfect* abstractions

   MoonBit is a pragmatic language, we care about both compile time and runtime performance. Take `+` for example, it is a trait method in Rust,
   it could be the same in MoonBit, but we care about compile time performance so much that we would prefer it as a simple function to make sure 
   both compile time and runtime are fast

- Large changes are encourgaged to communicate earlier before the implementation

   The core library is coupled with the compiler to some extent, it is better to communicate your ideas first if you 
   plan to make large structural changes.  

# Naming conventions

- function names, `snake_case` is preferred.
- type paramaters, one character starting from `A` is preferred, e.g, `fn map[A,B](self : Array[A], f : (A) -> (B)) -> Array[B]`, for some established
  conventions, `Map[K,V]` it is also accepted.
- type names, `CamlCase` is preferred, if one package is centered around one specific type, short name `T` is preferred, e.g, `@sorted_set.T`.
