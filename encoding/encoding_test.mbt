// Copyright 2024 International Digital Economy Academy
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

test "decoding String (UTF16LE) to String" {
  let src = "你好👀"
  let buf = @buffer.T::from_bytes(src.to_bytes())
  inspect!(
    buf.to_bytes(),
    content=
      #|b"\x60\x4f\x7d\x59\x3d\xd8\x40\xdc"
    ,
  )
  let stream = @encoding.decode_lossy(encoding=UTF16LE, buf)
  inspect!(String::from_iter(stream.iter()), content=src)
}

test "decoding UTF16LE to String" {
  let src = "你好👀"
  let buf = @buffer.T::new(size_hint=10)
  buf.write_bytes(b"\x60\x4f")
  buf.write_bytes(b"\x7d\x59")
  buf.write_bytes(b"\x3d\xd8\x40\xdc")
  inspect!(
    buf.to_bytes(),
    content=
      #|b"\x60\x4f\x7d\x59\x3d\xd8\x40\xdc"
    ,
  )
  let stream = @encoding.decode_lossy(encoding=UTF16LE, buf)
  inspect!(String::from_iter(stream.iter()), content=src)
}

test "decoding UTF8 to String" {
  let buf = @buffer.T::new(size_hint=10)
  buf.write_bytes(b"\xe4\xbd\xa0")
  buf.write_bytes(b"\xe5\xa5\xbd")
  buf.write_bytes(b"\xf0\x9f\x91\x80")
  inspect!(
    buf.to_bytes(),
    content=
      #|b"\xe4\xbd\xa0\xe5\xa5\xbd\xf0\x9f\x91\x80"
    ,
  )
  let stream = @encoding.decode_lossy(encoding=UTF8, buf)
  inspect!(String::from_iter(stream.iter()), content="你好👀")
}

test "decoding encoded String (UTF16LE) to String" {
  let src = "👋再见"
  let buf = @buffer.T::new(size_hint=10)
  for s in src {
    buf.write_char(s)
  }
  inspect!(
    buf.to_bytes(),
    content=
      #|b"\x3d\xd8\x4b\xdc\x8d\x51\xc1\x89"
    ,
  )
  let stream = @encoding.decode_lossy(encoding=UTF16LE, buf)
  inspect!(String::from_iter(stream.iter()), content=src)
}

test "decoding encoded UTF8 to String" {
  let src = "👋再见"
  let buf = @buffer.T::new(size_hint=10)
  for s in src {
    buf.write_utf8_char(s)
  }
  inspect!(
    buf.to_bytes(),
    content=
      #|b"\xf0\x9f\x91\x8b\xe5\x86\x8d\xe8\xa7\x81"
    ,
  )
  let stream = @encoding.decode_lossy(buf) // defaults to UTF8
  inspect!(String::from_iter(stream.iter()), content=src)
}

test "decoding encoded UTF8" {
  let src = "👋再见"
  let buf = @buffer.T::new(size_hint=10)
  for s in src {
    buf.write_utf8_char(s)
  }
  inspect!(
    buf.to_bytes(),
    content=
      #|b"\xf0\x9f\x91\x8b\xe5\x86\x8d\xe8\xa7\x81"
    ,
  )
  let stream = @encoding.decode_lossy(buf) // defaults to UTF8
  inspect!(stream.iter().collect(), content="['👋', '再', '见']")
}
