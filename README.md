# Core

MoonBit's standard library.

⚠️ **The standard library is still in experimental phase**. 

Developers who want to experience the standard library in advance can add the `--std` option after the `moon check`, `moon build`, `moon run` or `moon test` commands. This will link the standard library to the current project.

## Example

1. To create a new project, use the `moon new` command as shown below:

    ```bash
    $ moon new
    Enter the path to create the project (. for current directory): my-project
    Select the create mode: exec
    Enter your username: username
    Enter your project name: hello
    Enter your license: Apache-2.0
    Created my-project
    ```

2. Replace the contents of `my-project/main/main.mbt` with the following code:

    ```rust
    fn init {
      println(@list.reverse(@list.of_array([1, 2, 3])))
    }
    ```

    The code snippet uses `reverse` and `of_array` from the standard library `moonbitlang/core/list`.

3. If everything is configured correctly, the output should be:

    ```bash
    $ moon run main --std
    of_array([3, 2, 1])
    ```