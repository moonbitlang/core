# `json`

The `json` package provides comprehensive JSON handling capabilities, including
parsing, stringifying, and type-safe conversion between JSON and other MoonBit
data types.

## Basic JSON Operations

### Parsing and Validating JSON

```mbt check
///|
test "parse and validate jsons" {
  // Check if a string is valid JSON
  assert_true(@json.valid("{\"key\": 42}"))
  assert_true(@json.valid("[1, 2, 3]"))
  assert_true(@json.valid("null"))
  assert_true(@json.valid("false"))

  // Parse JSON string into Json value
  let json = @json.parse("{\"key\": 42}") catch {
    (_ : @json.ParseError) => panic()
    // _ => panic() // redundant, the type checker won't refine further

  }

  // Pretty print with indentation
  inspect(
    json.stringify(indent=2),
    content={
      let output =
        #|{
        #|  "key": 42
        #|}
      output
    },
  )
}
```

### Object Navigation

```mbt check
///|
test "json object navigation" {
  let json = @json.parse(
    "{\"string\":\"hello\",\"number\":42,\"array\":[1,2,3]}",
  )

  // Access string
  let string_opt = if json is { "string": String(str), .. } {
    Some(str)
  } else {
    None
  }
  inspect(
    string_opt,
    content=(
      #|Some("hello")
    ),
  )

  // Access number
  let number_opt = if json is { "number": Number(num, ..), .. } {
    Some(num)
  } else {
    None
  }
  inspect(number_opt, content="Some(42)")

  // Access array
  let array_opt = if json is { "array": Array(arr), .. } {
    Some(arr)
  } else {
    None
  }
  inspect(array_opt, content="Some([Number(1), Number(2), Number(3)])")

  // Handle missing keys gracefully
  guard json is { "value"? : value, .. }
  inspect(value, content="None")
}
```

### Array Navigation

```mbt check
///|
test "json array navigation" {
  let array = @json.parse("[1, 2, 3, 4, 5]")

  // Access by index
  let first = if array is Array([f, ..]) { Some(f) } else { None }
  inspect(first, content="Some(Number(1))")

  // Access out of bounds
  let missing = if array is Array(arr) { arr.get(10) } else { None }
  inspect(missing, content="None")

  // Iterate through array
  guard array is Array(values)
  inspect(
    values.iter(),
    content="[Number(1), Number(2), Number(3), Number(4), Number(5)]",
  )
}
```

## Type-Safe JSON Conversion

### From JSON to Native Types

```mbt check
///|
test "json decode" {
  // Decode basic types
  let json_number = (42 : Json)
  let number : Int = @json.from_json(json_number)
  inspect(number, content="42")

  // Decode arrays
  let json_array = ([1, 2, 3] : Json)
  let array : Array[Int] = @json.from_json(json_array)
  inspect(array, content="[1, 2, 3]")

  // Decode maps
  let json_map = ({ "a": 1, "b": 2 } : Json)
  let map : Map[String, Int] = @json.from_json(json_map)
  inspect(
    map,
    content=(
      #|{"a": 1, "b": 2}
    ),
  )
}
```

### Error Handling with JSON Path

```mbt check
///|
test "json path" {
  // Handle decode errors
  try {
    let _arr : Array[Int] = @json.from_json(([42, "not a number", 49] : Json))
    panic()
  } catch {
    @json.JsonDecodeError((path, msg)) => {
      inspect(path, content="/1")
      inspect(msg, content="Int::from_json: expected number")
    }
  }
}
```

## Stringify Options

`stringify` accepts optional parameters: `indent` for pretty-printing, `escape_slash` to escape `/` characters, and `replacer` to transform or filter keys.

```mbt check
///|
test "stringify options" {
  let json : Json = { "name": "Alice", "age": 30, "secret": "hidden" }
  // compact (default)
  inspect(
    json.stringify(),
    content="{\"name\":\"Alice\",\"age\":30,\"secret\":\"hidden\"}",
  )
  // pretty-printed
  inspect(
    json.stringify(indent=2),
    content={
      let output =
        #|{
        #|  "name": "Alice",
        #|  "age": 30,
        #|  "secret": "hidden"
        #|}
      output
    },
  )
}
```

## Replacer

`Replacer` controls which keys appear in `stringify` output or transforms values during `Json::transform`.

```mbt check
///|
test "replacer keep and exclude" {
  let json : Json = { "name": "Alice", "age": 30, "secret": "hidden" }
  // keep only specified keys
  let kept = json.stringify(replacer=@json.Replacer::keep(["name", "age"]))
  inspect(kept, content="{\"name\":\"Alice\",\"age\":30}")
  // exclude specified keys
  let excluded = json.stringify(replacer=@json.Replacer::exclude(["secret"]))
  inspect(excluded, content="{\"name\":\"Alice\",\"age\":30}")
}
```

Custom replacer with a function:

```mbt check
///|
test "replacer custom" {
  let json : Json = { "x": 1.0, "y": 2.0 }
  // double all number values
  let replaced = json.transform(
    @json.Replacer::new(fn(_key, value) {
      match value {
        Number(n, ..) => Some(Json::number(n * 2))
        other => Some(other)
      }
    }),
  )
  inspect(replaced.stringify(), content="{\"x\":2,\"y\":4}")
}
```

## Parse Errors

`parse()` raises `ParseError` with specific variants indicating what went wrong:

```mbt check
///|
test "parse errors" {
  // InvalidChar
  try {
    let _ = @json.parse("{invalid")
    panic()
  } catch {
    @json.InvalidChar(pos, _ch) =>
      inspect((pos.line, pos.column), content="(1, 1)")
    _ => panic()
  }
  // InvalidEof
  try {
    let _ = @json.parse("{\"a\":")
    panic()
  } catch {
    @json.InvalidEof => ()
    _ => panic()
  }
}
```

## The FromJson Trait

Types that implement `FromJson` can be decoded from JSON via `@json.from_json()`. Built-in support includes: `Bool`, `Int`, `Int64`, `UInt`, `UInt64`, `Float`, `Double`, `String`, `Char`, `Array[T]`, `Map[String, V]`, `Option[T]`, `Result[Ok, Err]`, tuples up to 16 elements, `Bytes`, and `Json` itself.

```mbt check
///|
test "from_json" {
  // decode a tuple
  let json : Json = [1, "hello"]
  let tuple : (Int, String) = @json.from_json(json)
  inspect(tuple, content="(1, \"hello\")")
  // decode an optional
  let opt : Int? = @json.from_json(null)
  inspect(opt, content="None")
  // decode a Result
  let json3 : Json = { "Ok": 42 }
  let result : Result[Int, String] = @json.from_json(json3)
  inspect(result, content="Ok(42)")
}
```

## JSON-based Snapshot Testing

`@json.json_inspect()` can be used as an alternative to `inspect()` when a value's
`ToJson` implementation is considered a better debugging representation than its
`Show` implementation. This is particularly true for deeply-nested data
structures.

```mbt check
///|
test "json inspection" {
  let null = null

  // Simple json values
  let json_value : Json = { "key": "value", "numbers": [1, 2, 3] }
  @json.json_inspect(json_value, content={
    "key": "value",
    "numbers": [1, 2, 3],
  })

  // Null and boolean values
  let json_special = { "null": null, "bool": true }
  @json.json_inspect(json_special, content={ "null": null, "bool": true })
}
```
