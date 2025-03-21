---
moonbit: true
---

# `String`

## Overview

* **UTF-16 Encoding**: MoonBit strings use UTF-16 encoding, which means
  characters outside the Basic Multilingual Plane (such as emojis) are
  represented using surrogate pairs - two 16-bit code units.

* **Char vs Charcode**: MoonBit distinguishes between:
  - `Charcode`: A UTF-16 code unit (type `Int`)
  - `Char`: A Unicode character (type `Char`)

* **Indexing**: There are two ways to count or index elements in a string:
  - **Offset**: UTF-16 index (counts code units)
  - **Character Index**: Counts actual Unicode characters

* **Performance and Unicode Safety**: 
  - Most APIs in this package operate on UTF-16 offsets rather than Unicode
    characters for efficiency. Offset-based operations have O(1) complexity
    while character-based operations typically require O(n) scanning. However,
    direct offset manipulation is not unicode-safe as it may split surrogate
    pairs.
  - For unicode-safe operations, it's recommended to use:
    - Iterators: `str.iter()` yields proper Unicode characters
    - Pattern matching: Handles surrogate pairs correctly
  - Example of safe vs unsafe operations:
```moonbit
test "unsafe vs safe" {
  // Unsafe: May split surrogate pairs
  let emoji = "🎉"
  let _ = emoji.char_at(1) // Gets second half of surrogate pair
  // Safe: Uses iterator
  for c in "Hello 🌍".iter() {
    // Properly handles both ASCII and Unicode chars
    ignore(c)
  }
}
```

* **Validity**: The string APIs assume the validity of strings and that provided
  offsets don't fall between surrogate pairs. The APIs don't perform validity
  checks for efficiency reasons. Creating invalid characters is possible (e.g.,
  `"🍎".char_at(1)` accesses the second half of a surrogate pair). When
  displaying invalid characters, a replacement character � will be shown.


