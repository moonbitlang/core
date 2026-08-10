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

// Round-trip property tests for Base64.
//
// Every property starts from arbitrary bytes, encodes them, optionally
// perturbs the text in a way the decoders are documented to tolerate
// (whitespace for `decode(ignore_whitespace=true)`, invalid characters for
// `decode_lossy`), and requires the original bytes back.

///|
/// Whitespace `decode` skips when `ignore_whitespace` is set.
let whitespace_chars : Array[Char] = [' ', '\n', '\r', '\t']

///|
/// Characters that are neither in the Base64 alphabet, nor padding, nor
/// whitespace: `decode` rejects them, `decode_lossy` skips them.
let invalid_chars : Array[Char] = ['$', '*', '-', '_', '#', '!', '?', '@']

///|
/// Maps an arbitrary Int into `0..<modulus` without discarding cases.
fn wrap_index(value : Int, modulus : Int) -> Int {
  let r = value % modulus
  if r < 0 {
    r + modulus
  } else {
    r
  }
}

///|
/// Splices characters drawn from `alphabet` into `text`. Each edit is an
/// arbitrary `(position, choice)` pair wrapped into range, so the generator
/// never has to discard a case and an empty `edits` array leaves `text`
/// untouched.
fn splice(
  text : String,
  edits : Array[(Int, Int)],
  alphabet : Array[Char],
) -> String {
  let chars = text.to_array()
  for edit in edits {
    let (position, choice) = edit
    chars.insert(
      wrap_index(position, chars.length() + 1),
      alphabet[wrap_index(choice, alphabet.length())],
    )
  }
  String::from_array(chars)
}

///|
test "encode then decode is the identity" {
  @quickcheck.check((bytes : Bytes) => {
    @base64.decode(@base64.encode(bytes)) == bytes
  })
}

///|
test "encode then decode is the identity without padding" {
  @quickcheck.check((bytes : Bytes) => {
    @base64.decode(@base64.encode(bytes, padding=false)) == bytes
  })
}

///|
/// Padding is presentational: both encodings must carry the same bytes.
test "padded and unpadded encodings decode alike" {
  @quickcheck.check((bytes : Bytes) => {
    let padded = @base64.encode(bytes)
    let unpadded = @base64.encode(bytes, padding=false)
    @base64.decode(padded) == @base64.decode(unpadded)
  })
}

///|
/// ASCII whitespace may appear anywhere — including between the two padding
/// characters and after them — without changing the decoded bytes.
test "whitespace anywhere survives the round trip" {
  @quickcheck.check((input : (Bytes, Array[(Int, Int)], Bool)) => {
    let (bytes, edits, padding) = input
    let text = splice(@base64.encode(bytes, padding~), edits, whitespace_chars)
    @base64.decode(text, ignore_whitespace=true) == bytes
  })
}

///|
/// `decode_lossy` skips invalid characters, so splicing them into an
/// encoding must not disturb the round trip.
test "decode_lossy round trips through invalid characters" {
  @quickcheck.check((input : (Bytes, Array[(Int, Int)], Bool)) => {
    let (bytes, edits, padding) = input
    let text = splice(@base64.encode(bytes, padding~), edits, invalid_chars)
    @base64.decode_lossy(text) == bytes
  })
}
