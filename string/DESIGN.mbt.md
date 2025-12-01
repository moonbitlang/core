# `String`

## Overview

* **UTF-16 Encoding**: MoonBit strings use UTF-16 encoding, which means
  characters outside the Basic Multilingual Plane (such as emojis) are
  represented using surrogate pairs - two 16-bit code units.

* **Char vs Charcode**: MoonBit distinguishes between:
  - `Charcode`: A UTF-16 code unit (type `Int`)
  - `Char`: A Unicode character (type `Char`)

* **Indexing**: There are two ways to count or index elements in a string:
  - **Offset** or **Charcode Index**: UTF-16 index (counts code units)
  - **Character Index**: Counts actual Unicode characters

  Because of the complexity of UTF-16 indexing, unlike `Array` or `Bytes`, we
  have specific guidelines for string indexing:
  - The `s[i]` syntax is available but should be used with caution. It accesses
    the i-th UTF-16 code unit (charcode) for efficiency and consistency with
    other APIs. The return type of `s[i]` is `Int`, which reminds you that it
    returns the charcode.
  - The slice operator `s[i:j]` is intentionally disallowed to prevent
    accidental creation of invalid strings. Instead, use `s.charcodes(start = i,
    end = j)` to get a view of the String. The API reminds you that it creates
    a view based on charcode indices, not characters.

* **Performance and Unicode Safety**:
  - Most APIs in this package operate on UTF-16 offsets rather than Unicode
    characters for efficiency. Offset-based operations have O(1) complexity
    while character-based operations typically require O(n) scanning. However,
    direct offset manipulation is not unicode-safe as it may split surrogate
    pairs. For example,
    * `char_at(i)` and `charcode_at(i)` reads the data at the i-th offset and
      returns the corresponding character and charcode respectively. Both APIs
      take O(1) time complexity.
    * `find` and `rev_find` will return the charcode index if the target is
      found. The index can be used to create a view of the string.
  - For unicode-safe operations, it's recommended to use:
    - Iterators: `str.iter()` yields proper Unicode characters
    - Pattern matching: Handles surrogate pairs correctly
  - Example of safe vs unsafe operations:
```mbt check
///|
test "unsafe vs safe" {
  // Unsafe: May split surrogate pairs
  let emoji = "🎉"
  let _ = emoji.get_char(1) // Gets second half of surrogate pair
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

* **View**: A `View` represents a view of a String that maintains proper Unicode
  character boundaries while providing efficient access to substrings. Views are
  designed to be more performant than creating new String instances when working
  with substrings.

  - **Performance**: Views are more performant than creating new String instances
    when working with substrings. They avoid string copying and memory allocation
    by maintaining references to the original string with start and end offsets,
    making substring operations O(1) rather than O(n). Multiple views of the same
    string share the underlying memory, which is particularly beneficial when
    processing large texts or creating many substring operations.

  - **Implicit Conversion**: String can be implicitly converted to View when
    the context is clear. This allows seamless interoperability between String
    and View in function calls where the expected type is unambiguous.

  - **API Parameter Design**: In string APIs, we use View as parameter types
    because when calling functions, the context (expected type) for arguments
    is mostly clear. This design allows both String and View to be passed to
    functions expecting View parameters, leveraging implicit conversion.

```mbt check
///|
test "view conversion" {
  fn process_text(text : StringView) -> Int {
    text.length()
  }

  let str = "Hello World"
  let view = str.view(start_offset=0, end_offset=5)

  // Both work due to implicit conversion
  let _ = process_text(str) // String implicitly converts to View
  let _ = process_text(view)
  // Direct View usage
}
```

  - **Return Type Strategy**: The return type depends on the nature of the
    operation and the input type:

    * **Substring Operations** (like `trim`, `split`): Always return `View` or
      `Iter[View]` because these operations create subparts of the original
      String. Using `View` is more efficient as it avoids copying.

    * **Transformation Operations** (like `replace`, `to_upper`): Return type
      matches the input type. If called on `View`, returns `View`; if called on
      `String`, returns `String`. This preserves type consistency and user
      intent.

  - **Unicode Safety and Validity**: Views maintain the same Unicode safety
    guarantees as Strings, properly handling surrogate pairs and UTF-16 encoding
    boundaries when iterating or accessing characters. When creating views, it
    is required to provide valid String with valid offsets. Violating this will
    result in the replacement character � being displayed when inspecting the
    view.
