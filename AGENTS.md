This is the standard library for [MoonBit](docs.moonbitlang.com).

# Refactoring tips

- MoonBit code is organized in block style, each block is separated by `///|`,
the order of each block is irrelevant. In some refactorings, you can process
block by block independently.

- Try to keep deprecated blocks in file called `deprecated.mbt`  in each directory.

- You should run `moon fmt` to check your code is formatted correctly.

- You should run `moon info` to update the generated interface of interface file, each package
has a generated interface file `.mbti` file, it is a breif formal description of the package, it is 
nothing changes, this means your change does not bring the visible changes to the external package users.

- Youd should run `moon test` to check the test is passed. MoonBit supports snapshot testing, so in some cases,
your changes indeed change the behavior of the code, you should run `moon test --update` to update the snapshot.

- You can run `moon check` to check the code is linted correctly.

- MoonBit packages are organized per directory, for each directory, there is a `package.json` file listing its dependencies.
Each package has its files and blackbox test files (common, ending in `_test.mbt`) and whitebox test files (ending in `_wbtest.mbt`).

- In the toplevel directory, this is a `moon.mod.json` file listing about the module and some meta information.


