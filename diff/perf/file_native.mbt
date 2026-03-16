///|
priv suberror FileReadError {
  FileReadError(String)
} derive(Show)

///|
fn utf8_bytes_to_mbt_string(bytes : Bytes) -> String {
  let res = StringBuilder::new()
  let len = bytes.length()
  let mut i = 0
  while i < len {
    let mut c = bytes[i].to_int()
    if c == 0 {
      break
    } else if c < 0x80 {
      res.write_char(c.unsafe_to_char())
      i += 1
    } else if c < 0xE0 {
      if i + 1 >= len {
        break
      }
      c = ((c & 0x1F) << 6) | (bytes[i + 1].to_int() & 0x3F)
      res.write_char(c.unsafe_to_char())
      i += 2
    } else if c < 0xF0 {
      if i + 2 >= len {
        break
      }
      c = ((c & 0x0F) << 12) |
        ((bytes[i + 1].to_int() & 0x3F) << 6) |
        (bytes[i + 2].to_int() & 0x3F)
      res.write_char(c.unsafe_to_char())
      i += 3
    } else {
      if i + 3 >= len {
        break
      }
      c = ((c & 0x07) << 18) |
        ((bytes[i + 1].to_int() & 0x3F) << 12) |
        ((bytes[i + 2].to_int() & 0x3F) << 6) |
        (bytes[i + 3].to_int() & 0x3F)
      c -= 0x10000
      res.write_char(((c >> 10) + 0xD800).unsafe_to_char())
      res.write_char(((c & 0x3FF) + 0xDC00).unsafe_to_char())
      i += 4
    }
  }
  res.to_string()
}

///|
fn mbt_string_to_utf8_bytes(str : String, append_nul : Bool) -> Bytes {
  let res : Array[Byte] = []
  let len = str.length()
  let mut i = 0
  while i < len {
    let mut c = str.code_unit_at(i).to_int()
    if 0xD800 <= c && c <= 0xDBFF {
      c -= 0xD800
      i = i + 1
      let l = str.code_unit_at(i).to_int() - 0xDC00
      c = (c << 10) + l + 0x10000
    }
    if c < 0x80 {
      res.push(c.to_byte())
    } else if c < 0x800 {
      res.push((0xc0 + (c >> 6)).to_byte())
      res.push((0x80 + (c & 0x3f)).to_byte())
    } else if c < 0x10000 {
      res.push((0xe0 + (c >> 12)).to_byte())
      res.push((0x80 + ((c >> 6) & 0x3f)).to_byte())
      res.push((0x80 + (c & 0x3f)).to_byte())
    } else {
      res.push((0xf0 + (c >> 18)).to_byte())
      res.push((0x80 + ((c >> 12) & 0x3f)).to_byte())
      res.push((0x80 + ((c >> 6) & 0x3f)).to_byte())
      res.push((0x80 + (c & 0x3f)).to_byte())
    }
    i = i + 1
  }
  if append_nul {
    res.push((0).to_byte())
  }
  Bytes::from_array(res)
}

///|
#external
priv type FileHandle

///|
#borrow(path, mode)
extern "C" fn fopen_ffi(path : Bytes, mode : Bytes) -> FileHandle = "moonbitlang_core_diff_perf_fopen_ffi"

///|
extern "C" fn is_null_ffi(ptr : FileHandle) -> Int = "moonbitlang_core_diff_perf_is_null"

///|
#borrow(ptr)
extern "C" fn fread_ffi(
  ptr : Bytes,
  size : Int,
  nitems : Int,
  stream : FileHandle,
) -> Int = "moonbitlang_core_diff_perf_fread_ffi"

///|
extern "C" fn fseek_ffi(file : FileHandle, offset : Int, whence : Int) -> Int = "moonbitlang_core_diff_perf_fseek_ffi"

///|
extern "C" fn ftell_ffi(file : FileHandle) -> Int = "moonbitlang_core_diff_perf_ftell_ffi"

///|
extern "C" fn fclose_ffi(file : FileHandle) -> Int = "moonbitlang_core_diff_perf_fclose_ffi"

///|
extern "C" fn error_message_ffi() -> Bytes = "moonbitlang_core_diff_perf_get_error_message"

///|
fn error_message() -> String {
  utf8_bytes_to_mbt_string(error_message_ffi())
}

///|
fn read_file_to_string(path : String) -> String raise FileReadError {
  let file = fopen_ffi(mbt_string_to_utf8_bytes(path, true), b"rb\x00")
  guard is_null_ffi(file) == 0 else { raise FileReadError(error_message()) }
  guard fseek_ffi(file, 0, 2) == 0 else { raise FileReadError(error_message()) }
  let size = ftell_ffi(file)
  guard size >= 0 else { raise FileReadError(error_message()) }
  guard fseek_ffi(file, 0, 0) == 0 else { raise FileReadError(error_message()) }
  let bytes = Bytes::make(size, 0)
  let bytes_read = fread_ffi(bytes, 1, size, file)
  guard bytes_read == size else { raise FileReadError(error_message()) }
  guard fclose_ffi(file) == 0 else { raise FileReadError(error_message()) }
  utf8_bytes_to_mbt_string(bytes)
}
