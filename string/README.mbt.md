# String Package Documentation

This package provides comprehensive string manipulation utilities for MoonBit,
including string creation, conversion, searching, and Unicode handling.

## String Creation and Conversion

Create strings from various sources:

```mbt check
///|
test "string creation" {
  // From character array
  let chars = ['H', 'e', 'l', 'l', 'o']
  let str1 = String::from_array(chars)
  inspect(str1, content="Hello")

  // From character iterator
  let str2 = String::from_iter(['W', 'o', 'r', 'l', 'd'].iter())
  inspect(str2, content="World")

  // Default empty string
  let empty = String::default()
  inspect(empty, content="")
}
```

## String Iteration

Iterate over Unicode characters in strings:

```mbt check
///|
test "string iteration" {
  let text = "Hello🌍"

  // Forward iteration
  let chars = text.iter().collect()
  inspect(chars, content="['H', 'e', 'l', 'l', 'o', '🌍']")

  // Reverse iteration
  let reversed = text.rev_iter().collect()
  inspect(reversed, content="['🌍', 'o', 'l', 'l', 'e', 'H']")

  // Iteration with indices - demonstrate iter2 functionality
  let mut count = 0
  let mut first_char = 'a'
  text
  .iter2()
  .each(fn(idx, char) {
    if idx == 0 {
      first_char = char
    }
    count = count + 1
  })
  inspect(first_char, content="H")
  inspect(count, content="6") // 6 Unicode characters
}
```

## String Conversion

Convert strings to other formats:

```mbt check
///|
test "string conversion" {
  let text = "Hello 你好"

  // Convert to character array
  let chars = text.to_array()
  inspect(chars, content="['H', 'e', 'l', 'l', 'o', ' ', '你', '好']")

  // Convert to bytes (UTF-8 encoding)
  let bytes = @utf8.encode(text) // Use UTF-8 encoding
  inspect(bytes.length(), content="12")
  inspect(chars, content="['H', 'e', 'l', 'l', 'o', ' ', '你', '好']")

  // Convert to bytes (UTF-16 LE encoding)
  let bytes = @utf16.encode(text)
  inspect(bytes.length(), content="16") // 5 chars * 2 bytes each
}
```

## Unicode Handling

Work with Unicode characters and surrogate pairs:

```mbt check
///|
test "unicode handling" {
  let emoji_text = "Hello🤣World"

  // Character count vs UTF-16 code unit count
  let char_count = emoji_text.iter().count()
  let code_unit_count = emoji_text.length()
  inspect(char_count, content="11") // Unicode characters
  inspect(code_unit_count, content="12") // UTF-16 code units

  // Find character offset
  let offset = emoji_text.offset_of_nth_char(5) // Position of emoji
  inspect(offset, content="Some(5)")

  // Test character length
  let has_11_chars = emoji_text.char_length_eq(11)
  inspect(has_11_chars, content="true")
}
```

## String Comparison

Strings are ordered using shortlex order by Unicode code points:

```mbt check
///|
test "string comparison" {
  let result1 = "apple".compare("banana")
  inspect(result1, content="-1") // apple < banana
  let result2 = "hello".compare("hello")
  inspect(result2, content="0") // equal
  let result3 = "zebra".compare("apple")
  inspect(result3, content="1") // zebra > apple
}
```

## String Views

String views provide efficient substring operations without copying:

```mbt check
///|
test "string views" {
  let text = "Hello, World!"
  let view = text[:][7:12] // "World" - create view using slice notation

  // Views support similar operations as strings
  let chars = view.iter().collect()
  inspect(chars, content="['W', 'o', 'r', 'l', 'd']")

  // Convert view back to string
  let substring = view.to_string()
  inspect(substring, content="World")
}
```

## Practical Examples

Common string manipulation tasks:

```mbt check
///|
test "practical examples" {
  let text = "The quick brown fox"

  // Split into words (using whitespace) - returns Iter[View]
  let words = text.split(" ").collect()
  inspect(words.length(), content="4")
  inspect(words[0].to_string(), content="The")
  inspect(words[3].to_string(), content="fox")

  // Join words back together - convert views to strings first
  let word_strings = words.map(fn(v) { v.to_string() })
  let mut result = ""
  for i, word in word_strings.iter2() {
    if i > 0 {
      result = result + "-"
    }
    result = result + word
  }
  inspect(result, content="The-quick-brown-fox")

  // Case conversion (works on views)
  let upper = text[:].to_upper().to_string()
  inspect(upper, content="THE QUICK BROWN FOX")
  let lower = text[:].to_lower().to_string()
  inspect(lower, content="the quick brown fox")
}
```

## Regular Expressions

Use `Regex` for string regex matching, replacement, and splitting:

- Syntax follows MoonBit `lexmatch` regex literals.
- Supported constructs include `.`, character classes (`[abc]`, `[^abc]`,
  `[a-z]`, `[[:digit:]]`), quantifiers (`*`, `+`, `?`, `{n}`, `{n,}`,
  `{n,m}` with non-greedy forms), grouping/alternation (`(...)`, `(?:...)`
  for non-capturing groups, `(?<name>...)`, `a|b`), and
  assertions/modifiers (`^`, `$`, `\b`, `\B`, `(?i:...)`).
- Common escapes include `\n`, `\r`, `\t`, `\f`, `\v`; `Regex` also
  supports Unicode escapes `\uXXXX` and `\u{X...}`; `\xHH` is not
  supported in `Regex`.
- `^` and `$` are non-multiline anchors: they match only the start/end of the
  whole input, not per-line boundaries.
- `\d`, `\D`, `\s`, `\S`, `\w`, and `\W` are not supported; use POSIX
  character classes such as `[[:digit:]]`, `[[:space:]]`, `[[:word:]]`.
- See <https://github.com/moonbitlang/lexmatch_spec> for full grammar.

```mbt check
///|
test "string regex basics" {
  let regex = @string.Regex("[[:digit:]]+")

  guard regex.execute("id=42") is Some(m) else { fail("Expected match") }
  inspect(m.content(), content="42")

  let replaced = regex.replace_by("a1b22", _m => "#")
  inspect(replaced, content="a#b#")

  let replaced_limited = regex.replace_by("a1b22c333", _m => "#", limit=2)
  inspect(replaced_limited, content="a#b#c333")
}
```

## Parsing

Parse primitive types from strings. All parsing functions raise on invalid input.

```mbt check
///|
test "parse numbers" {
  // integers (decimal by default)
  inspect(@string.parse_int("42"[:]), content="42")
  inspect(@string.parse_int("-17"[:]), content="-17")
  // explicit base
  inspect(@string.parse_int("ff"[:], base=16), content="255")
  inspect(@string.parse_int("101"[:], base=2), content="5")
  // unsigned
  inspect(@string.parse_uint("42"[:]), content="42")
  // 64-bit
  inspect(@string.parse_int64("9999999999"[:]), content="9999999999")
  inspect(
    @string.parse_uint64("18446744073709551615"[:]),
    content="18446744073709551615",
  )
  // double
  inspect(@string.parse_double("3.14"[:]), content="3.14")
  // bool
  inspect(@string.parse_bool("true"[:]), content="true")
}
```

The `FromStr` trait provides a generic `from_str()` method for `Bool`, `Int`, `Int64`, `UInt`, `UInt64`, and `Double`.

## Regex Match Results

`MatchResult` gives access to the matched text, its context, and capture groups:

```mbt check
///|
test "match result" {
  let re = @string.Regex("([[:alpha:]]+)=([[:digit:]]+)")
  guard re.execute("key=42") is Some(m) else { fail("no match") }
  inspect(m.content(), content="key=42")
  inspect(m.before(), content="")
  inspect(m.after(), content="")
  inspect(m.group(1), content="Some(\"key\")")
  inspect(m.group(2), content="Some(\"42\")")
}
```

Named capture groups via `(?<name>...)`:

```mbt check
///|
test "named groups" {
  let re = @string.Regex("(?<name>[[:alpha:]]+):(?<val>[[:digit:]]+)")
  guard re.execute("age:30") is Some(m) else { fail("no match") }
  inspect(m.named_group("name"), content="Some(\"age\")")
  inspect(m.named_group("val"), content="Some(\"30\")")
}
```

## Regex Find & Split

`find()` returns an iterator over all non-overlapping matches. `split()` splits a string at each match boundary.

```mbt check
///|
test "find and split" {
  let digits = @string.Regex("[[:digit:]]+")
  let matches = digits
    .find("a1b22c333")
    .map(fn(m) { m.content().to_string() })
    .collect()
  inspect(matches, content="[\"1\", \"22\", \"333\"]")
  let parts = digits.split("a1b22c333").map(fn(v) { v.to_string() }).collect()
  inspect(parts, content="[\"a\", \"b\", \"c\", \"\"]")
}
```

## Regex Combinators

Build complex patterns programmatically with `Regex::string()`, `Regex::repeat()`, `Regex::capture()`, `+` (sequence), and `|` (alternation):

```mbt check
///|
test "regex combinators" {
  // match "abc" literally
  let abc = @string.Regex::string("abc"[:])
  inspect(abc.execute("xabcy") is Some(_), content="true")
  // repeat: match 2 to 4 digits
  let digits = @string.Regex("[[:digit:]]").repeat(min=2, max=4)
  guard digits.execute("a12345") is Some(m) else { fail("no match") }
  inspect(m.content(), content="1234") // greedy: takes max
  // alternation with |
  let either = @string.Regex::string("cat"[:]) | @string.Regex::string("dog"[:])
  inspect(either.execute("I have a dog") is Some(_), content="true")
}
```

## Performance Notes

- Use `StringBuilder` or `Buffer` for building strings incrementally rather than
  repeated concatenation
- String views are lightweight and don't copy the underlying data
- Unicode iteration handles surrogate pairs correctly but is slower than UTF-16
  code unit iteration
- Character length operations (`char_length_eq`, `char_length_ge`) have O(n)
  complexity where n is the character count
