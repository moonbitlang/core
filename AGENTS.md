This is the standard library for [MoonBit](docs.moonbitlang.com).

# Refactoring tips

- MoonBit code is organized in block style, each block is separated by `///|`,
the order of each block is irrelevant. In some refactorings, you can process
block by block independently.

- Try to keep deprecated blocks in file called `deprecated.mbt`  in each directory.

- `moon fmt` is used to format your code properly.

- `moon info` is used to update the generated interface of the package, each package
has a generated interface file `.mbti`, it is a brief formal description of the package. 
If nothing in `.mbti` changes, this means your change does not bring the visible changes to the external package users, 
it is typically a safe refactoring.

- So in the last step, you typically run `moon info && moon fmt` to update the interface and format the code. You also
check the diffs of `.mbti` file to see if the changes are expected.

- You should run `moon test` to check the test is passed. MoonBit supports snapshot testing, so in some cases,
your changes indeed change the behavior of the code, you should run `moon test --update` to update the snapshot.

- You can run `moon check` to check the code is linted correctly.

- MoonBit packages are organized per directory, for each directory, there is a `package.json` file listing its dependencies.
Each package has its files and blackbox test files (common, ending in `_test.mbt`) and whitebox test files (ending in `_wbtest.mbt`).

- In the toplevel directory, this is a `moon.mod.json` file listing about the module and some meta information.


