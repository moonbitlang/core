# Asynchronous I/O (`@moonbitlang/core/async/io`)

This package defines asynchronous byte and text streams for MoonBit. Binary I/O
uses `BinaryReader` and `BinaryWriter`; text I/O uses `TextReader` and
`TextWriter`. Keeping the two forms separate makes encoding explicit and keeps
binary protocols free of implicit UTF-8 conversions.

The package also provides in-memory pipes, a callback-backed `MemoryReader`,
UTF-8 adapters, and buffered writing.

## Quick start

`pipe()` returns connected binary endpoints. Writes apply backpressure until a
reader accepts the data, and closing the write end makes the reader reach EOF.

```moonbit check
///|
async test "binary pipe quick start" {
  @async.with_task_group() <| root => {
    let (reader, writer) = @io.pipe()
    defer reader.close()
    root.spawn_bg() <| () => {
      defer writer.close()
      writer.write(b"Hello, ")
      writer.write(b"MoonBit!")
    }
    inspect(@utf8.decode(reader.read_all()), content="Hello, MoonBit!")
  }
}
```

## Binary streams

### `BinaryReader`

`BinaryReader` owns a read-ahead buffer. Its methods provide three useful styles
of reading:

- `read_into(dst, offset?, max_len?)` reads into caller-owned storage and
  returns the number of bytes read. A zero return value indicates EOF.
- `read()` returns an owned chunk as soon as data is available, or `None` at EOF.
- `read_at_least(min_len)` returns an owned chunk containing at least `min_len`
  bytes, and may return more.
- `peek()` returns a zero-copy view as soon as data is available, or `None` at
  EOF, without consuming it.
- `peek_at_least(min_len)` returns a zero-copy view containing at least
  `min_len` bytes without consuming it.

If EOF arrives before `min_len` bytes are buffered, `read_at_least` and
`peek_at_least` raise `ReaderClosed`. Any shorter trailing data remains buffered
and can still be obtained by a later operation with a smaller minimum.

```moonbit check
///|
async test "read into caller-owned storage" {
  @async.with_task_group() <| root => {
    let (reader, writer) = @io.pipe()
    defer reader.close()
    root.spawn_bg() <| () => {
      defer writer.close()
      writer.write(b"hello")
    }
    let dst = FixedArray::make(9, b'.')
    let count = reader.read_into(dst, offset=2, max_len=5)
    inspect(count, content="5")
    inspect(
      @utf8.decode(dst.unsafe_reinterpret_as_bytes()[2:7]),
      content="hello",
    )
  }
}
```

```moonbit check
///|
async test "peek then consume an exact frame" {
  @async.with_task_group() <| root => {
    let (reader, writer) = @io.pipe()
    defer reader.close()
    root.spawn_bg() <| () => {
      defer writer.close()
      writer.write(b"HEADbody")
    }
    let preview = reader.peek_exactly(4).to_owned()
    inspect(@utf8.decode(preview), content="HEAD")
    inspect(@utf8.decode(reader.read_exactly(4)), content="HEAD")
    inspect(@utf8.decode(reader.read_all()), content="body")
  }
}
```

The view returned by `peek`, `peek_at_least`, `peek_exactly`, or `peek_until` is
valid only until the next operation on that reader. Call `.to_owned()` if the
bytes must outlive that operation.

Other binary reader operations are:

- `read_exactly(len)` and `peek_exactly(len)` wait for exactly `len` bytes and
  raise `ReaderClosed` if EOF arrives first.
- `drop_exactly(len)` consumes exactly `len` bytes without returning them.
- `read_all()` drains the stream into a `Bytes` value.
- `drop_all()` drains the stream and returns the number of discarded bytes.
- `read_until(pattern, include_delimiter?)` reads through the next delimiter.
- `peek_until(pattern, include_delimiter?)` finds the same segment without
  consuming it.

`read_until` always consumes a delimiter it finds. By default the delimiter is
excluded from the result; set `include_delimiter=true` to retain it. EOF acts as
an implicit delimiter, so a final unterminated segment is returned once, then
the next call returns `None`.

```moonbit check
///|
async test "read delimiter-separated binary records" {
  @async.with_task_group() <| root => {
    let (reader, writer) = @io.pipe()
    defer reader.close()
    root.spawn_bg() <| () => {
      defer writer.close()
      writer.write(b"alpha|beta")
    }
    guard reader.read_until(b"|") is Some(first) else {
      fail("missing first record")
    }
    inspect(@utf8.decode(first), content="alpha")
    guard reader.read_until(b"|") is Some(second) else {
      fail("missing final record")
    }
    inspect(@utf8.decode(second), content="beta")
    assert_eq(reader.read_until(b"|"), None)
  }
}
```

### `BinaryWriter`

`write(data)` accepts a `BytesView` and does not return until the complete view
has been committed to the underlying writer. A slice can therefore be forwarded
without first copying it into a new `Bytes` value.

`write_reader(reader)` copies a binary reader into a writer until EOF.

```moonbit check
///|
async test "write a byte view" {
  @async.with_task_group() <| root => {
    let (reader, writer) = @io.pipe()
    defer reader.close()
    root.spawn_bg() <| () => {
      defer writer.close()
      let packet = b"xxpayloadyy"
      writer.write(packet[2:9])
    }
    inspect(@utf8.decode(reader.read_all()), content="payload")
  }
}
```

`write` guarantees delivery to the underlying writer object, but not a
destination-specific durability property such as an operating-system file
flush.

## Text streams and UTF-8 adapters

Text is opt-in. `Utf8Reader` adapts a `BinaryReader` to `TextReader`, and
`Utf8Writer` adapts a `BinaryWriter` to `TextWriter`.

- `TextReader::read_all()` decodes all remaining bytes as UTF-8.
- `TextReader::read_until(pattern, include_delimiter?)` searches for a text
  delimiter and returns decoded text.
- `TextWriter::write(text)` UTF-8 encodes a `StringView`.
- `TextWriter::write_json(json)` writes the JSON text representation.

```moonbit check
///|
async test "UTF-8 text adapters" {
  @async.with_task_group() <| root => {
    let (reader, writer) = @io.pipe()
    defer reader.close()
    root.spawn_bg() <| () => {
      defer writer.close()
      let text_writer = @io.Utf8Writer(writer)
      text_writer.write("你好|MoonBit")
    }
    let text_reader = @io.Utf8Reader(reader)
    guard text_reader.read_until("|") is Some(first) else {
      fail("missing first text record")
    }
    inspect(first, content="你好")
    inspect(text_reader.read_all(), content="MoonBit")
  }
}
```

Decoding invalid UTF-8 raises an error. Use the binary interfaces when arbitrary
bytes must be preserved.

## `MemoryReader`

`MemoryReader` turns an asynchronous writer callback into a binary reader. The
callback runs in a background coroutine; returning closes the stream, raising an
error propagates it to the reader, and closing the reader cancels the callback.

```moonbit check
///|
async test "callback-backed memory reader" {
  let reader = @io.MemoryReader() <| writer => {
    writer.write(b"generated ")
    @async.sleep(10)
    writer.write(b"content")
  }
  defer reader.close()
  inspect(@utf8.decode(reader.read_all()), content="generated content")
}
```

## Buffered writing

`BufferedWriter::new(writer, size?)` batches small writes in a fixed-size
buffer. Call `flush()` before accessing the underlying destination through
another path or before closing it. The buffer size must be positive.

```moonbit check
///|
async test "buffered writer" {
  @async.with_task_group() <| root => {
    let (reader, writer) = @io.pipe()
    defer reader.close()
    root.spawn_bg() <| () => {
      defer writer.close()
      let buffered = @io.BufferedWriter::new(writer, size=4)
      buffered.write(b"ab")
      buffered.write(b"cd")
      buffered.write(b"ef")
      buffered.flush()
    }
    inspect(@utf8.decode(reader.read_all()), content="abcdef")
  }
}
```

## Implementing an endpoint

Application code normally depends on `BinaryReader` and `BinaryWriter`.
Endpoint implementations use the lower-level traits:

```mbt nocheck
///|
pub(open) trait BinaryReaderImpl {
  fn get_controller(Self) -> BinaryReaderController
  async fn raw_read_impl(
    Self,
    FixedArray[Byte],
    offset~ : Int32,
    max_len~ : Int32,
  ) -> Int32
}

///|
pub(open) trait BinaryWriterImpl {
  fn get_controller(Self) -> BinaryWriterController
  async fn raw_write_impl(Self, Bytes, offset~ : Int32, len~ : Int32) -> Int32
}
```

A binary reader stores one `BinaryReaderController`, returns it from
`get_controller`, implements `raw_read_impl`, and explicitly implements
`BinaryReader` to opt into the default high-level methods. A writer similarly
stores one `BinaryWriterController`, returns it from `get_controller`, implements
`raw_write_impl`, and explicitly implements `BinaryWriter`. Writer controller
internals are intentionally hidden so shared behavior can evolve without
changing endpoint implementations or the high-level writer API.

Raw operations communicate directly with the underlying endpoint. On success
they must make positive progress, may return fewer bytes than requested, and
must not call the high-level methods recursively. For readers, zero means EOF.

## Usage notes

- Run only one operation at a time on a given reader or writer. The interfaces
  do not serialize concurrent calls.
- Use `peek` for parser lookahead, but copy a returned view before another
  reader operation if it must be retained.
- Prefer `read_into` for caller-managed buffers, `read` for streaming chunks,
  and `read_all` only when the remaining input comfortably fits in memory.
- Use `Utf8Reader` and `Utf8Writer` at the text boundary instead of mixing text
  conversion into binary protocol code.
- Flush a `BufferedWriter` at protocol boundaries and before closing its
  underlying writer.
