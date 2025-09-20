# String Package Documentation

This package provides comprehensive string manipulation utilities for MoonBit, including string creation, conversion, searching, and Unicode handling.

## String Creation and Conversion

Create strings from various sources:

```moonbit
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

```moonbit
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

```moonbit
///|
test "string conversion" {
  let text = "Hello"

  // Convert to character array
  let chars = text.to_array()
  inspect(chars, content="['H', 'e', 'l', 'l', 'o']")

  // Convert to bytes (UTF-16 LE encoding)
  let bytes = text.to_bytes()
  inspect(bytes.length(), content="10") // 5 chars * 2 bytes each
}
```

## Unicode Handling

Work with Unicode characters and surrogate pairs:

```moonbit
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

```moonbit
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

```moonbit
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

```moonbit
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

## Performance Notes

- Use `StringBuilder` or `Buffer` for building strings incrementally rather than repeated concatenation
- String views are lightweight and don't copy the underlying data
- Unicode iteration handles surrogate pairs correctly but is slower than UTF-16 code unit iteration
- Character length operations (`char_length_eq`, `char_length_ge`) have O(n) complexity where n is the character count
