# Contributing to moonbitlang/core

## Step 0: Contributor License Agreement

Before sending your first change to the moonbitlang/core project you must have completed one of the following two CLAs. Which CLA you should sign depends on who owns the copyright to your work.

- Individual contributor license agreement.
- Corporate contributor license agreement.


## Step 1: Clone the repository

To start working on the project, you need to have a local copy of the repository. Currently, `moon` will look up `moonbitlang/core` at `~/.moon/lib/core`, remove it if it exists

```bash
rm -rf ~/.moon/lib/core
```

Then, you can use the following command to get latest version of the `moonbitlang/core`:

```bash
git clone https://github.com/moonbitlang/core ~/.moon/lib/core
```

Run the following command to bundle `moonbitlang/core`

```bash
moon bundle --source-dir ~/.moon/lib/core
```

If everything goes well, it will generate a bundled core file `~/.moon/lib/core/target/bundle/core.core`.

Now you can create a new moon project and run it to check if everything is working as expected:

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

Now it's time to make your changes to the codebase. Whether it's fixing a bug, adding a new feature, or improving documentation, your contributions are welcome. Ensure that your changes are clear and understandable to others who will be reviewing your code.

## Step 3: Test your change

After making your changes, it's important to test them to ensure they work as expected and do not introduce new issues. You can run the following commands to test your changes:

```bash
moon check
moon test
moon bundle
```

## Step 4: Submit a pull request and request a review

Simply follow the standard [GitHub flow](https://docs.github.com/en/get-started/using-github/github-flow) to submit your pull request. 

After submitting your pull request, request a review from the project maintainers or other contributors. 
