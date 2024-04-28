# Contributing to moonbitlang/core

## Step 0: Contributor License Agreement

- Before sending your first change to the moonbitlang/core project, you must have completed one of the following two CLAs, depending on who owns the copyright to your work:
  - To sign the Individual Contributor License Agreement, you can either sign it online by visiting https://moonbitlang.com/cla or download the CLA from [ICLA-IDEA_IDEA Legal_202311.pdf
](https://github.com/moonbitlang/CLA/blob/main/ICLA-IDEA_IDEA%20Legal_202311.pdf), sign it, and send it to us at jichuruanjian@idea.edu.cn.
  - To sign the Corporate Contributor License Agreement, download the CLA from [CCLA-IDEA_IDEA Legal_202311.pdf
](https://github.com/moonbitlang/CLA/blob/main/CCLA-IDEA_IDEA%20Legal_202311.pdf), sign it, and send it to us at jichuruanjian@idea.edu.cn.

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
    println(@list.reverse(@list.from_array([1, 2, 3])))
  }""" > main/main.mbt
  moon run main
  # Output: List::Cons(3,List::Cons(2,List::Cons(1,Nil)))
  ```

## Step 2: Make your change

Now it's time to make your changes to the codebase. Whether it's fixing a bug, adding a new feature, or improving documentation, your contributions are welcome. Ensure that your changes are clear and understandable to others who will review your code.

Currently there are some simple restrictions for naming convention and code formatting:

- All function names, method names, and variables should use `snake_case`, while all type names should use `PascalCase`.
- The code formatting should align with the result of moonfmt as much as possible.
- For public functions and types, tests and documentation should be provided. 


## Step 3: Test your change

After making your changes, it's important to test them to ensure they work as expected and do not introduce new issues. Run the following commands to test your changes:

  ```bash
  moon check
  moon test
  moon bundle
  moon info // Generate mbti files, these files should be tracked by git
  ```

## Step 4: Submit a pull request and request a review

Simply follow the standard [GitHub flow](https://docs.github.com/en/get-started/using-github/github-flow) to submit your pull request.

After submitting your pull request, request a review from the project maintainers or other contributors.


# What kind of contributions are more likely to accepted

- Test, documentation and bug fixes 

- Standalone packages with good functionalites, for example, bigint package

- Fast and efficient abstractions are preferred over *beautiful* abstractions

   MoonBit is a pragmatic language, we care about both compile time and runtime performance. Take `+` for example, it is a trait method in Rust,
   it could be the same in MoonBit, but we care about compile time performance so much that we would prefer it as a simple function to make sure 
   both compile time and runtime are fast

- Large changes are encourgaged to communicate earlier before the implementation

   The core library is coupled with the compiler to some extent, it is better to communicate your ideas first if you 
   plan to make large structural changes.  

  
