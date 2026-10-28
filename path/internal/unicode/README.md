# Unicode lowercasing for Windows paths

This internal helper implements locale-independent default lowercasing from
[Unicode 17.0.0, section 3.13](https://www.unicode.org/versions/Unicode17.0.0/core-spec/chapter-3/)
for the string comparisons in Windows `relative`. It does not perform Unicode
normalization or case folding, and it does not change `Path` equality.

`lowercase.mbt` supplies simple character mappings. `string_lowercase.mbt` adds
the default rules in `SpecialCasing.txt`: the expansion of U+0130 and contextual
Greek final sigma. Locale-specific rules, such as Turkish casing, do not apply.

The final-sigma context uses `Cased` and `Case_Ignorable` properties from the
same Unicode version. `case_properties.mbt` stores their sorted, inclusive
ranges in flat `ReadOnlyArray[Int32]` tables: `[start, end, start, end, ...]`.
The generated data retains its Unicode copyright and `UNICODE-LICENSE.txt`.

To regenerate the property tables, download the pinned
[DerivedCoreProperties.txt](https://www.unicode.org/Public/17.0.0/ucd/DerivedCoreProperties.txt)
and run:

```sh
moon run --target js path/internal/unicode/generate_case_properties.mbtx INPUT > path/internal/unicode/case_properties.mbt
moon fmt
```

Unicode case mappings and properties can evolve across releases. Upgrades are
explicit: review `UnicodeData.txt`, `SpecialCasing.txt`, and
`DerivedCoreProperties.txt` together, update the pinned version and generated
tables, and rerun the casing and Windows path tests. The existing tables do not
change with the host runtime's Unicode version. JavaScript comparison tests use
established mappings shared by supported runtimes.
