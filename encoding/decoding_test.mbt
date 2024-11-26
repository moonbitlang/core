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

test "lossy decoding String (UTF16LE encoded) to String" {
  let src = "你好👀"
  let buf = @buffer.T::from_bytes(src.to_bytes())
  inspect!(
    buf.to_bytes(),
    content=
      #|b"\x60\x4f\x7d\x59\x3d\xd8\x40\xdc"
    ,
  )
  let stream = @encoding.decode_lossy(UTF16LE, buf)
  inspect!(String::from_iter(stream.iter()), content=src)
}

test "lossy decoding UTF16LE encoded data to String" {
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
  let stream = @encoding.decode_lossy(UTF16LE, buf)
  inspect!(String::from_iter(stream.iter()), content="你好👀")
}

test "lossy decoding UTF16BE encoded data to String" {
  let buf = @buffer.T::new(size_hint=10)
  buf.write_bytes(b"\xd8\x3d\xdc\x08")
  buf.write_bytes(b"\xd8\x3d\xdc\x31")
  buf.write_bytes(b"\xd8\x3d\xdc\x07")
  buf.write_bytes(b"\xd8\x3d\xdc\x30")
  inspect!(
    buf.to_bytes(),
    content=
      #|b"\xd8\x3d\xdc\x08\xd8\x3d\xdc\x31\xd8\x3d\xdc\x07\xd8\x3d\xdc\x30"
    ,
  )
  let stream = @encoding.decode_lossy(UTF16BE, buf)
  inspect!(String::from_iter(stream.iter()), content="🐈🐱🐇🐰")
}

test "lossy decoding UTF16 (alias of UTF16BE) encoded data to String" {
  let buf = @buffer.T::new(size_hint=24)
  buf.write_bytes(b"\x18\x65")
  buf.write_bytes(b"\x18\x20")
  buf.write_bytes(b"\x18\x73")
  buf.write_bytes(b"\x18\x64")
  buf.write_bytes(b"\x18\x73")
  buf.write_bytes(b"\x18\x36")
  buf.write_bytes(b"\x18\x20")
  inspect!(
    buf.to_bytes(),
    content=
      #|b"\x18\x65\x18\x20\x18\x73\x18\x64\x18\x73\x18\x36\x18\x20"
    ,
  )
  let stream = @encoding.decode_lossy(UTF16, buf)
  inspect!(String::from_iter(stream.iter()), content="ᡥᠠᡳᡤᡳᠶᠠ")
}

test "lossy decoding UTF8 encoded data to String" {
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
  let stream = @encoding.decode_lossy(UTF8, buf)
  inspect!(String::from_iter(stream.iter()), content="你好👀")
}

test "lossy decoding String (UTF16LE encoded) to String" {
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
  let stream = @encoding.decode_lossy(UTF16LE, buf)
  inspect!(String::from_iter(stream.iter()), content=src)
}

test "lossy decoding UTF8 encoded data to String" {
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
  let stream = @encoding.decode_lossy(UTF8, buf)
  inspect!(String::from_iter(stream.iter()), content=src)
}

test "lossy decoding UTF8 encoded data" {
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
  let stream = @encoding.decode_lossy(UTF8, buf)
  inspect!(stream.iter().collect(), content="['👋', '再', '见']")
}

test "lossy decoding UTF8 encoded data with UTF16LE" {
  let src = "跑步🏃游泳🏊"
  let buf = @buffer.T::new(size_hint=10)
  for s in src {
    buf.write_char(s)
  }
  inspect!(
    buf.to_bytes(),
    content=
      #|b"\xd1\x8d\x65\x6b\x3c\xd8\xc3\xdf\x38\x6e\xf3\x6c\x3c\xd8\xca\xdf"
    ,
  )
  let stream = @encoding.decode_lossy(UTF8, buf)
  inspect!(
    stream.iter().collect(),
    content="['э', 'e', 'k', '<', '�', '�', 'n', '�', '�']",
  )
}

test "lossy decoding UTF16LE encoded data with UTF8" {
  let src = "跑步🏃游泳🏊"
  let buf = @buffer.T::new(size_hint=10)
  for s in src {
    buf.write_utf8_char(s)
  }
  inspect!(
    buf.to_bytes(),
    content=
      #|b"\xe8\xb7\x91\xe6\xad\xa5\xf0\x9f\x8f\x83\xe6\xb8\xb8\xe6\xb3\xb3\xf0\x9f\x8f\x8a"
    ,
  )
  let stream = @encoding.decode_lossy(UTF16LE, buf)
  inspect!(
    stream.iter().collect(),
    content="['럨', '', 'ꖭ', '鿰', '莏', '룦', '', '뎳', '鿰', '誏']",
  )
}

test "strictly decoding UTF8 encoded data with UTF16LE" {
  let src = "跑步🏃游泳🏊"
  let buf = @buffer.T::new(size_hint=10)
  for s in src {
    buf.write_char(s)
  }
  inspect!(
    buf.to_bytes(),
    content=
      #|b"\xd1\x8d\x65\x6b\x3c\xd8\xc3\xdf\x38\x6e\xf3\x6c\x3c\xd8\xca\xdf"
    ,
  )
  let stream = @encoding.decode_strict(UTF8, buf)
  inspect!(stream.iter().try_collect?(), content="Err(쏘)")
}

test "strictly decoding UTF16LE encoded data with UTF8" {
  let src = "跑步🏃游泳🏊"
  let buf = @buffer.T::new(size_hint=10)
  for s in src {
    buf.write_utf8_char(s)
  }
  inspect!(
    buf.to_bytes(),
    content=
      #|b"\xe8\xb7\x91\xe6\xad\xa5\xf0\x9f\x8f\x83\xe6\xb8\xb8\xe6\xb3\xb3\xf0\x9f\x8f\x8a"
    ,
  )
  let stream = @encoding.decode_strict(UTF16LE, buf)
  inspect!(
    stream.iter().try_collect?(),
    content="Ok(['럨', '', 'ꖭ', '鿰', '莏', '룦', '', '뎳', '鿰', '誏'])",
  )
}

test "strictly decoding UTF16BE encoded data with UTF8" {
  let src = "跑步🏃游泳🏊"
  let buf = @buffer.T::new(size_hint=10)
  for s in src {
    buf.write_utf8_char(s)
  }
  inspect!(
    buf.to_bytes(),
    content=
      #|b"\xe8\xb7\x91\xe6\xad\xa5\xf0\x9f\x8f\x83\xe6\xb8\xb8\xe6\xb3\xb3\xf0\x9f\x8f\x8a"
    ,
  )
  let stream = @encoding.decode_strict(UTF16BE, buf)
  inspect!(
    stream.iter().try_collect?(),
    content="Ok(['', '釦', '궥', '', '较', '', '룦', '뎳', '', '辊'])",
  )
}
