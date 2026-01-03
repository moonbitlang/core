// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
fn println_mono(s : String) -> Unit = "%println"

///|
fn[T] any_to_string(any : T) -> String = "%any.to_string"

///|
/// Prints any value that implements the `Show` trait to the standard output,
/// followed by a newline.
///
/// Parameters:
///
/// * `value` : The value to be printed. Must implement the `Show` trait.
///
/// Example:
///
/// ```mbt check
/// test {
///   if false {
///     println(42)
///     println("Hello, World!")
///     println([1, 2, 3])
///   }
/// }
/// ```
pub fn[T : Show] println(input : T) -> Unit {
  println_mono(input.to_string())
}

///|
/// Represents an error type used by the `inspect` function to indicate failures
/// in value inspection. Contains a string message describing the nature of the
/// inspection failure.
///
/// Returns a type constructor that creates an error type from a string message.
///
/// Example:
///
/// ```mbt check
/// test {
///   let x : Int = 42
///   inspect(x, content="42") // Raises InspectError with detailed failure message
/// }
/// ```
pub(all) suberror InspectError String

///|
fn base64_encode(data : FixedArray[Byte]) -> String {
  let base64 = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  let buf = StringBuilder::new()
  let len = data.length()
  let rem = len % 3
  for i = 0; i < len - rem; i = i + 3 {
    let b0 = data[i].to_int()
    let b1 = data[i + 1].to_int()
    let b2 = data[i + 2].to_int()
    let x0 = base64[(b0 & 0xFC) >> 2]
    let x1 = base64[((b0 & 0x03) << 4) | ((b1 & 0xF0) >> 4)]
    let x2 = base64[((b1 & 0x0F) << 2) | ((b2 & 0xC0) >> 6)]
    let x3 = base64[b2 & 0x3F]
    buf.write_char(x0.to_char())
    buf.write_char(x1.to_char())
    buf.write_char(x2.to_char())
    buf.write_char(x3.to_char())
  }
  if rem == 1 {
    let b0 = data[len - 1].to_int()
    let x0 = base64[(b0 & 0xFC) >> 2]
    let x1 = base64[(b0 & 0x03) << 4]
    buf.write_char(x0.to_char())
    buf.write_char(x1.to_char())
    buf.write_char('=')
    buf.write_char('=')
  } else if rem == 2 {
    let b0 = data[len - 2].to_int()
    let b1 = data[len - 1].to_int()
    let x0 = base64[(b0 & 0xFC) >> 2]
    let x1 = base64[((b0 & 0x03) << 4) | ((b1 & 0xF0) >> 4)]
    let x2 = base64[(b1 & 0x0F) << 2]
    buf.write_char(x0.to_char())
    buf.write_char(x1.to_char())
    buf.write_char(x2.to_char())
    buf.write_char('=')
  }
  buf.to_string()
}

///|
fn base64_encode_string_codepoint(s : String) -> String {
  // the input string is expected to be valid utf-16 string
  let codepoint_length = s.char_length()
  let data : FixedArray[Byte] = FixedArray::make(codepoint_length * 4, 0)
  for i = 0, utf16_index = 0
      i < codepoint_length
      i = i + 1, utf16_index = utf16_index + 1 {
    let c = s.unsafe_char_at(utf16_index).to_int()
    if c > 0xFFFF {
      data[i * 4] = (c & 0xFF).to_byte()
      data[i * 4 + 1] = ((c >> 8) & 0xFF).to_byte()
      data[i * 4 + 2] = ((c >> 16) & 0xFF).to_byte()
      data[i * 4 + 3] = ((c >> 24) & 0xFF).to_byte()
      continue i + 1, utf16_index + 2
    } else {
      data[i * 4] = (c & 0xFF).to_byte()
      data[i * 4 + 1] = ((c >> 8) & 0xFF).to_byte()
      data[i * 4 + 2] = 0
      data[i * 4 + 3] = 0
    }
  }
  base64_encode(data)
}

///|
test {
  inspect(base64_encode_string_codepoint(""))
  inspect(base64_encode_string_codepoint("a"), content="YQAAAA==")
  inspect(base64_encode_string_codepoint("ab"), content="YQAAAGIAAAA=")
  inspect(base64_encode_string_codepoint("abc"), content="YQAAAGIAAABjAAAA")
  inspect(
    base64_encode_string_codepoint("abcd"),
    content="YQAAAGIAAABjAAAAZAAAAA==",
  )
  inspect(
    base64_encode_string_codepoint("abcde"),
    content="YQAAAGIAAABjAAAAZAAAAGUAAAA=",
  )
  inspect(base64_encode_string_codepoint("a中"), content="YQAAAC1OAAA=")
  inspect(
    base64_encode_string_codepoint("a中🤣"),
    content="YQAAAC1OAAAj+QEA",
  )
  inspect(
    base64_encode_string_codepoint("a中🤣a"),
    content="YQAAAC1OAAAj+QEAYQAAAA==",
  )
  inspect(
    base64_encode_string_codepoint("a中🤣中"),
    content="YQAAAC1OAAAj+QEALU4AAA==",
  )
}

///|
/// Tests if the string representation of an object matches the expected content.
/// Used primarily in test cases to verify the correctness of `Show`
/// implementations and program outputs.
///
/// Parameters:
///
/// * `object` : The object to be inspected. Must implement the `Show` trait.
/// * `content` : The expected string representation of the object. Defaults to
/// an empty string.
/// * `location` : Source code location information for error reporting.
/// Automatically provided by the compiler.
/// * `arguments_location` : Location information for function arguments in
/// source code. Automatically provided by the compiler.
///
/// Throws an `InspectError` if the actual string representation of the object
/// does not match the expected content. The error message includes detailed
/// information about the mismatch, including source location and both expected
/// and actual values.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(42, content="42")
///   inspect("hello", content="hello")
///   inspect([1, 2, 3], content="[1, 2, 3]")
/// }
/// ```
#callsite(autofill(args_loc, loc))
pub fn inspect(
  obj : &Show,
  content? : String = "",
  loc~ : SourceLoc,
  args_loc~ : ArgsLoc,
) -> Unit raise InspectError {
  let actual = obj.to_string()
  if actual != content {
    let loc = loc.to_json_string()
    let args_loc = args_loc.to_json()
    let expect_escaped = content.escape()
    let actual_escaped = actual.escape()
    let expect_base64 = "\"\{base64_encode_string_codepoint(content)}\""
    let actual_base64 = "\"\{base64_encode_string_codepoint(actual)}\""
    raise InspectError(
      "@EXPECT_FAILED {\"loc\": \{loc}, \"args_loc\": \{args_loc}, \"expect\": \{expect_escaped}, \"actual\": \{actual_escaped}, \"expect_base64\": \{expect_base64}, \"actual_base64\": \{actual_base64}}",
    )
  }
}

///|
/// Represents an error that occurs during snapshot testing. Contains a string
/// message describing the error.
///
/// Used internally by the test driver to handle snapshot-related errors. Not
/// intended for direct use by end users.
///
/// Example:
///
/// ```mbt check
/// test {
///   let err : SnapshotError = SnapshotError("failed to load snapshot")
///   match err {
///     SnapshotError(msg) => assert_eq(msg, "failed to load snapshot")
///   }
/// }
/// ```
pub(all) suberror SnapshotError String

///|
pub(all) suberror BenchError String

///|
test "panic error case of inspect" {
  let x : Int = 42
  inspect(x, content="100")
}
