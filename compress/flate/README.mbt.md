# flate

Pure-MoonBit **DEFLATE** (RFC 1951) — a runtime-agnostic, suspendable, io-free
compression engine in `moonbitlang/core/compress/flate`. The sibling
`compress/gzip` (RFC 1952) and `compress/zlib` (RFC 1950) packages provide
compressed formats; `archive/zip` (APPNOTE.TXT) provides ZIP archives.

gzip, zlib, and zip share CRC-32 and Adler-32 implementations in the internal
`moonbitlang/core/internal/checksum` package. This package is an
implementation detail and cannot be imported from outside `moonbitlang/core`.

## Import

Add the packages you use to `moon.pkg`:

```moon.pkg
import {
  "moonbitlang/core/compress/flate",
  "moonbitlang/core/compress/gzip",
  "moonbitlang/core/compress/zlib",
  "moonbitlang/core/archive/zip",
}
```

## Quick start

The one-shot API is useful when the complete payload is already in memory.
Read-only codec inputs accept `BytesView`, so a slice of a larger buffer needs
no ownership conversion at the call site:

```mbt check
///|
test "README raw DEFLATE round-trip" {
  let source = b"runtime-agnostic streaming compression"
  let compressed = @flate.deflate_all(source)
  @test.assert_eq(@flate.inflate(compressed, mode=Prefix).data, source)
}
```

The direct-buffer APIs accept `MutArrayView[Byte]`, including slices of arrays.
Pass the same strategy to `deflate_bound` and compression; the bound panics
for a negative input length or an unrepresentable result.
Compression returns `None` if its encoded output does not fit, while decompression
raises `OutputLimitExceeded(limit~, observed~)` if its decoded output does not fit. Reuse
`Compressor` and `Decompressor` across streams to retain their workspace.

```mbt check
///|
test "README caller-buffer DEFLATE" {
  let source = b"direct input and caller-owned output"
  let compressor = @flate.Compressor(strategy=Standard(level=6))
  let compressed_buffer = FixedArray::make(
    @flate.deflate_bound(source.length()),
    b'\x00',
  )
  guard compressor.compress_into(source, compressed_buffer.mut_view())
    is Some(compressed_len) else {
    @test.fail("deflate_bound was too small")
  }
  let compressed = Bytes::from_array(compressed_buffer[:compressed_len])
  let decompressor = @flate.Decompressor()
  let output = FixedArray::make(source.length(), b'\x00')
  let decoded = decompressor.decompress_into(compressed, output.mut_view())
  @test.assert_eq(decoded.consumed, compressed.length())
  @test.assert_eq(Bytes::from_array(output[:decoded.produced]), source)
}
```

Use `Compressor(...).compress_into(input, output)` or
`Decompressor(...).decompress_into(input, output)` for a single call, and retain
the object to reuse workspace across calls.
`Decompressor::decompress_into` returns `DecompressResult` with
`consumed` and `produced`. The default `mode=Exact` rejects trailing bytes;
use `mode=Prefix` to leave them unread, with `consumed` locating their start.
Use the streaming APIs when input or output must suspend.

`Compressor::compress(input)` returns independent `Bytes` and reuses its
workspace across calls, without requiring a caller-owned output buffer.
`Decompressor::decompress(input)` is its counterpart: the output grows as in
`inflate`, returning `Decompressed` with owned `data` and the input `consumed`.
Pass `mode=Prefix` to read a stream of unknown length from the front of a
buffer and go on behind it:

```mbt check
///|
test "README prefix decode" {
  // A record: a raw DEFLATE stream, then whatever follows it.
  let payload = b"the stream ends with its final block"
  let record = @flate.deflate_all(payload) + b"what follows"
  let decompressor = @flate.Decompressor()
  let result = decompressor.decompress(record, mode=Prefix)
  @test.assert_eq(result.data, payload)
  let rest = record[result.consumed:]
  @test.assert_eq(rest.to_owned(), b"what follows")
}
```

The streaming API is a pure push state machine. It owns no I/O object, so both
synchronous and asynchronous callers can supply input and drain output:

```mbt check
///|
test "README streaming IncrementalEncoder" {
  let source = b"small buffers exercise suspension and resume"
  let encoder = @flate.IncrementalEncoder()
  let chunk = FixedArray::make(3, b'\x00')
  let compressed = @buffer.Buffer()
  let mut first = true
  for ;; {
    let input = if first { source[:] } else { b"" }
    let result = encoder.step(
      input,
      chunk.mut_view(),
      action=if first { Finish } else { Continue },
    )
    let consumed = result.consumed
    let produced = result.produced
    @test.assert_eq(consumed, if first { source.length() } else { 0 })
    first = false
    for i in 0..<produced {
      compressed.write_byte(chunk[i])
    }
    if result.status is Done {
      break
    }
  }
  @test.assert_eq(
    @flate.inflate(compressed.to_bytes(), mode=Prefix).data,
    source,
  )
}
```

### State-machine contract

- `step` and `finish` return a `#valtype`
  `StepResult` containing `status`, `consumed`, and `produced`. The counts
  describe exactly the prefixes accepted and written by that call. Drop only
  `input[:result.consumed]`; large input views may be partially consumed when
  output is backpressured, keeping internal memory bounded. Later calls and
  resets do not change an earlier result. A failing call returns no result,
  and its output buffer may already contain partial output.
- `NeedMoreOutput` preserves all pending work. Resume with another non-empty
  output view; one byte is sufficient.
- `IncrementalDecoder` owns the bounded tail of an incomplete atomic unit. On
  `NeedMoreInput`, feed the next non-overlapping chunk; no growing replay window
  is required.
- Encoders take one `DeflateAction`: `Continue`, `SyncFlush`, or `Finish`.
  Pass the requested action with the final input of that batch. If
  `consumed < input.length()`, re-present that suffix with the same action. Once
  the complete view is accepted, the request remains latched across output
  backpressure.
- Decoder `step(input, output)` methods accept a mutable output view,
  including slices of fixed arrays or arrays. The engine chooses its copy
  strategy internally and releases caller buffers after each call. gzip and
  zlib checksum the produced range and drain pending body input before
  accepting more, so output can be produced while `result.consumed` is zero.
  Re-present the unaccepted input on the next call.
- Raw `IncrementalDecoder` callers own input completion: `NeedMoreInput` after the
  input source is exhausted means the stream is truncated. On `NeedMoreOutput`,
  keep calling `step` with the unconsumed suffix and fresh output space, even
  if the suffix is empty; stop at `Done`.
- gzip/zlib decoders accept the final input chunk through `finish`; repeat
  with any unconsumed suffix and fresh output space until `Done`. They report
  truncation themselves. After a raw decoder error, discard or reset it;
  container decoder instances stably rethrow the same error.
- Once `Done` is returned, new input is not consumed; reset the raw engine or
  gzip/zlib encoder before reuse, or create a new decoder wrapper. A reset
  encoder produces the same bytes as a fresh one with the same options and
  driving schedule, while reusing its workspace.
- Configure a raw preset dictionary through `IncrementalEncoder(...)`/`IncrementalDecoder(...)`, or
  while starting a fresh stream through `reset(dictionary=...)`; dictionary
  selection cannot be mutated after a stream begins.
- gzip/zlib decoders may accept transport read-ahead beyond their trailer;
  after `Done`, recover that suffix with `unused_input()` before parsing the
  next protocol frame. For an exact one-member gzip boundary, construct the
  decoder with `multistream=false`.
- Raw failures expose a stable `InflateErrorKind` (`Truncated`, `Corrupt`,
  `TrailingData`, `OutputLimitExceeded`, `Cancelled`, or `InvalidArgument`)
  alongside diagnostic text; gzip/zlib similarly expose `GzipErrorKind`/`ZlibErrorKind`.

### Exact and bounded one-shot decoding

`inflate` and the reusable `Decompressor` methods default to `mode=Exact`,
which rejects trailing bytes with `TrailingData`. Set `mode=Prefix` to stop at
the first final block and use the returned `consumed` count to find the suffix.
The whole-buffer signatures are:

```text
inflate(input, mode?=Exact, dictionary?, max_output?, cancelled?, two_pass?=false) -> Decompressed
Decompressor::decompress(self, input, mode?=Exact, max_output?, cancelled?) -> Decompressed
Decompressor::decompress_into(self, input, output, mode?=Exact, cancelled?) -> DecompressResult
```

`Decompressed` contains owned `data` and `consumed`; `DecompressResult` contains
`consumed` and `produced`. All three calls raise `InflateError` on failure.
Construct `Decompressor(dictionary=...)` to own the dictionary's final 32 KiB
and reuse it independently for each stream. Dictionary history is not part of
returned data, output limits, or produced counts. Raw DEFLATE has no dictionary
checksum; a wrong dictionary is not guaranteed to be detected.
`inflate`, `Decompressor::decompress`, and gzip/zlib `decompress` accept
`max_output` and `cancelled`. gzip counts output across all members; zlib
accepts `dictionary` on both `compress` and `decompress`. The compressor uses
the last 32 KiB as history and records the full dictionary checksum.

```mbt check
///|
test "README exact and limited inflate" {
  let source = b"bounded convenience API"
  let compressed = @flate.deflate_all(source)
  @test.assert_eq(
    @flate.inflate(compressed, max_output=source.length()).data,
    source,
  )
}
```

Omitting `max_output` permits output up to the capacity of `Bytes`; negative
limits raise `InvalidArgument`. `OutputLimitExceeded(limit~, observed~)` carries
`UInt64` counts. `observed` includes the rejected chunk or match, not necessarily
the complete decoded size or bytes written. For `*_into`, the limit is the
output buffer's capacity. These calls are not transactional: an error, including
`TrailingData`, may leave bytes written inside the supplied output view.

A `cancelled` callback returning true raises `Cancelled`. It is polled regularly
during decoding and, for gzip/zlib, checksum verification; gzip also polls while
scanning headers and joining members. A failed `Decompressor` remains reusable
and returned results remain independent of later calls.

`inflate(two_pass=true)` counts and validates first, then decodes into
one exactly sized allocation. It trades a second decode pass for lower peak
memory; the default grows the output in one pass.

## ZIP container

The `@zip` package provides metadata-only range reads, in-memory archives, and
incremental writing over the same compression engine.

Use `DirectoryReader` to browse a ZIP without loading the complete file or
decoding its payloads. It supports classic ZIP beyond 2 GiB and ZIP64, with
`UInt64` archive sizes, file offsets, and declared entry sizes. The caller owns
file or HTTP range I/O; the reader requests only a bounded tail, necessary ZIP64
records, and directory chunks:

```moonbit nocheck
///|
fn browse_zip(
  size : UInt64,
  read_range : (UInt64, Int32) -> Bytes raise,
) -> @zip.Directory raise {
  let reader = @zip.DirectoryReader(
    size,
    limits=DirectoryLimits(max_directory_bytes=16777216UL, max_entries=100000UL),
  )
  let mut input : Bytes = b""
  for ;; {
    match reader.advance(input) {
      NeedRead(range) => input = read_range(range.offset(), range.length())
      Done(directory) => return directory
    }
  }
}
```

Start with empty input, then supply the exact bytes from each requested range.
Accumulate short transport reads before submitting them. All ranges must come
from the same immutable archive. Requests are at most 65,557 bytes; directory
chunks are at most 64 KiB, and records crossing chunks are retained in a bounded
buffer. Memory grows with directory metadata, rather than compressed or decoded
payload sizes. `DirectoryLimits` caps encoded directory bytes and entry count;
the in-memory listing can hold at most 2^31 - 1 entries. No declared payload size
causes a payload allocation or counts against these directory limits.

`Directory::entries()` preserves directory order and duplicate names.
`DirectoryEntry` exposes the UTF-8 name, compressed/uncompressed `UInt64` sizes,
raw compression method number, declared CRC-32, directory/encryption indicators,
creator system, external attributes, and packed DOS modification date/time
(without a timezone). Unknown compression methods and encrypted payloads remain
listable when the directory itself is readable. Multi-disk archives and encrypted
central directories are unsupported. Listing validates directory structure and
referenced bounds; it does not read local headers, inflate files, or verify CRCs.
An optional trailing directory digital-signature record is accepted after
checking its signature marker and length; its cryptographic contents are not
verified.
`InvalidRead` identifies incorrect response lengths or input outside an active
request. Errors remain latched; repeated empty calls after `Done` return the
same listing. Callers can cancel by stopping between requests.

Open a listed entry with `Directory::open_entry(index)` to create an
`EntryReader`. Indices distinguish duplicate names. It extracts Store and Deflate
entries from bounded ranges, including ZIP64 and entries with more than 2 GiB
of decoded data. `EntryReadLimits(max_output_bytes=...)` sets a `UInt64` output
ceiling; oversized declarations are rejected before I/O, and actual decoded
output is checked before reporting bytes to the caller.

```moonbit nocheck
///|
fn extract_entry(
  directory : @zip.Directory,
  index : Int32,
  read_range : (UInt64, Int32) -> Bytes raise,
  emit : (BytesView) -> Unit raise,
) -> Unit raise {
  let reader = directory.open_entry(index)
  let output = FixedArray::make(65536, b'\x00')
  let mut input : Bytes = b""
  for ;; {
    let status = reader.step(input, output.mut_view())
    let produced = reader.last_produced()
    if produced > 0 {
      emit(Bytes::from_array(output[:produced]))
    }
    match status {
      NeedRead(range) => input = read_range(range.offset(), range.length())
      NeedMoreOutput => input = b""
      Done => return
    }
  }
}
```

Start with empty input. A `NeedRead` response requires exactly the requested
bytes; after `NeedMoreOutput`, submit empty input with another output buffer.
The reader retains unconsumed compressed bytes, so callers never replay an
accepted range. Input and output arrays are released before each return.
Read `last_produced()` after **every successful step**, including those returning
`NeedRead` or `Done`. `total_consumed()` and `total_produced()` report `UInt64`
compressed-payload and decoded byte counts. Memory is bounded by one compressed
chunk, local metadata, the codec workspace, and the caller's output buffer.

`Done` verifies the local header against the directory, exact compressed and
decoded sizes, CRC-32, and any classic or ZIP64 data descriptor. Output produced
earlier remains unverified; discard partial output on failure.
Like `read_all`, zero-length Deflate entries with zero compressed bytes are accepted;
CRC-32 and any data descriptor are still checked.
Unsupported methods and encrypted entries remain listable but cannot be opened.
`InvalidEntryIndex` identifies an invalid index, `SizeMismatch` an inconsistent
decoded size, and `InvalidRead` a range-response protocol error. A failed reader
stably rethrows its error with `last_produced()` zero; repeated empty steps after
completion return `Done`. Cancel by stopping between calls.

Use `Archive` for in-memory editing and serialization. `read(BytesView)` still
decodes and verifies every entry, and `write(Archive)` returns one complete
`Bytes`; these convenience paths retain their Int32 buffer limits. Use
`DirectoryReader` / `EntryReader` for reading large archives and chunked `Writer`
input/output for creating them:

```mbt check
///|
test "README zip round-trip" {
  let archive = @zip.Archive()
  archive.add("hello.txt", b"hello, zip")
  let bytes = @zip.write(archive)
  let parsed = @zip.read_all(bytes)
  @test.assert_eq(parsed.get("hello.txt"), Some(b"hello, zip"))
}
```

Supported features include STORED and DEFLATE entries, ZIP64, data descriptors,
UTF-8 names, and archive comments. `read_all` accepts `ReadLimits` to bound archive
size (including the complete retained source), entry count, and decompressed sizes, plus a
`cancelled` callback. Exceeding a limit raises
`ZipError(LimitExceeded(kind~, limit~, observed=actual), message)`; limit and actual values
are `UInt64` on both memory and directory paths.

`read_all` verifies each entry's CRC-32, raising `ChecksumMismatch` for a damaged
payload. Cancellation remains `Cancelled` throughout parsing, decoding and
checksum verification.

`Entry` exposes `dos_date`, `dos_time`, `creator_system`, and `external_attributes`.
These fields survive `replace` and are written back in both write modes.
`read_all` retains a copy of the archive plus all decoded payloads in memory.

`write(archive, preserve=true)` reuses unchanged source records; an unmodified
archive round-trips byte-for-byte, including prefixes, gaps and directory order.
After an edit, local records and directory entries keep their respective order;
bytes outside records, such as prefixes and gaps, are omitted.
`max_package_bytes` covers the full retained source, including these bytes.
Supply `max_output_bytes` to bound the serialized size before allocating it.
`write` returns the complete ZIP as `Bytes`.

For incremental output, use `Writer` with a synchronous sink. `add` accepts a
complete file; `begin_entry` / `write` / `end_entry` accept chunks. Supply `size`
when known; unknown sizes use ZIP64.

```mbt check
///|
test "README incremental ZIP writer" {
  // A real folder adapter passes a buffered file-write callback here.
  let output = @buffer.Buffer()
  let writer = @zip.Writer(chunk => output.write_bytes(chunk))
  writer.add("small.txt", b"small file")
  writer.begin_entry("chunked.txt", size=6UL)
  writer.write(b"abc")
  writer.write(b"def")
  writer.end_entry()
  writer.finish()
  let archive = @zip.read_all(output.to_bytes())
  @test.assert_eq(archive.get("chunked.txt"), Some(b"abcdef"))
}
```

Call `finish` to write the central directory. The sink must consume each chunk
before returning. If it raises an error, the writer becomes unusable and the
partial output must be discarded; the sink's error reaches the caller unchanged.
The writer's own failures are `ZipError`s: `InvalidState` for a call out of
order (no open entry, an entry already open, a reentrant sink call, or use after
`finish` or a sink failure) and `SizeMismatch` when an entry's input exceeds or
falls short of its declared `size`. A size error leaves the entry open, so the
caller can supply the missing bytes and call `end_entry` again.

Large individual entries use `begin_entry` / repeated `write` / `end_entry`;
their declared size and cumulative positions are `UInt64`. The writer selects
ZIP64 and data descriptors internally. `add(BytesView)` remains convenient for
a complete in-memory entry. Directory metadata is retained until `finish`.

`Writer` retains directory metadata, current-entry metadata and codec buffers.
`add` processes a complete file during the call; `write` feeds chunks through
the codec or directly to the sink. Folder traversal and file I/O belong to
the caller.

## Architecture

The raw engine shares Huffman construction, block writing and format validation
across its encoding and decoding paths:

| Path | Implementation |
| --- | --- |
| Whole-buffer compression | `deflate_all.mbt`, `lz77.mbt` |
| Streaming compression | `deflate.mbt`, `block_planner.mbt`, `lz77.mbt` |
| Content-driven block splitting | `split_plan.mbt` |
| Iterated optimal parsing and splitting | `optimal_parse.mbt`, `optimal_plan.mbt` |
| Block encoding and bit output | `block_writer.mbt`, `huffman_build.mbt`, `bitwriter.mbt` |
| Whole-buffer decompression | `inflate_all.mbt` |
| Streaming decompression | `inflate.mbt` |
| Shared decoding tables and validation | `huffman_table.mbt`, `tables.mbt`, `decode_rules.mbt` |

One-pass `inflate` uses the direct `MemDecoder` path for every combination of
mode, dictionary, output limit, and cancellation callback. `inflate(two_pass=true)`
drives `IncrementalDecoder` to count and validate, then decode into one exactly
sized allocation.
`Decompressor::decompress_into` uses the direct decoder with caller-owned
output, `Decompressor::decompress` with an output that grows.
Differential tests compare one-shot and streaming decoding across randomized
chunk/output schedules, truncations and bit flips.

The gzip and zlib packages add framing, checksums and streaming wrappers.
ZIP provides in-memory archives and a synchronous incremental writer.
The internal checksum package supplies CRC-32 and Adler-32 independently of the codecs.

## Optional fast stored blocks

`fast_store=true` opts into a heuristic speed/ratio trade-off. It samples byte
variety, frequency skew and local repetition; small inputs also get a periodicity
check. Inputs below 1 KiB skip the classifier. A candidate judged unlikely to compress is emitted as DEFLATE stored
blocks without match search or Huffman construction. The default is `false`:
existing calls retain their normal compression behavior.

```moonbit nocheck
///|
let codec = @flate.Compressor(strategy=Standard(level=6), fast_store=true)

///|
let raw = @flate.deflate_all(input, fast_store=true)

///|
let stream = @flate.IncrementalEncoder(level=6, fast_store=true)

///|
let archive_bytes = @zip.write(archive, fast_store=true)
```

The option is also available on all `deflate_all` strategies, `Compressor`,
gzip/zlib compression functions and streaming encoders, all ZIP serialization
functions, and `zip.Writer`. Whole-buffer APIs classify the entire input;
streaming encoders decide per block and retain stored bytes as match history.
ZIP entries declared `Deflate` remain method 8; this option selects stored blocks
inside DEFLATE, rather than changing the entry to ZIP method 0. Preserved ZIP
payloads are reused; record offsets may be patched.

This is **not a proof of incompressibility**. Long repeated patterns or useful
dictionary matches can be missed, potentially making output much larger. Enable
it only when that compression-ratio trade-off is acceptable. Decoding remains
lossless, and the normal output bounds and output limits still apply.

## Effort tiers

`deflate_all`, `Compressor`, and gzip/zlib `compress` share
`strategy`, defaulting to `Standard(level=6)`:

- `Standard(level=...)`: fixed-cadence blocks with zlib-derived level tuning.
- `Split(level=...)`: tokenize once, then choose content-driven block cuts.
- `Optimal(iterations=...)`: iterated optimal parsing and content-driven splitting.

Levels are clamped to 0-9; iterations to at least 1. All strategies produce
standard DEFLATE. Output size depends on the input and chosen strategy.
`IncrementalEncoder` retains its `level` parameter and bounded 16 KiB input blocks.
All raw whole-buffer compression entry points accept `dictionary`; `Compressor`
owns its last 32 KiB and reuses it for each stream. The output bound is unchanged.

gzip/zlib re-export `Strategy`, `Status`, `StepResult`, and `DeflateAction`.
Their streaming encoders take `level` 0-9 and support `reset`.

## API conventions

Read-only inputs accept `BytesView`; existing `Bytes` values convert at the
call site without copying. `Compressor::compress` and `compress_into` reuse
workspace for repeated streams.

ZIP writing uses `write(archive, preserve=true, max_output_bytes=n)` for
byte-preserving, bounded output. The options are independent. Construct read
bounds with `ReadLimits(max_entries=..., max_package_bytes=...,
max_entry_uncompressed_bytes=..., max_total_uncompressed_bytes=...)`.
`max_package_bytes` also bounds the source retained for byte-preserving writes.
Metadata-only reads use separate `DirectoryLimits`, without decoded-size limits.

ZIP layout controls are internal: `Archive::add` no longer takes
`data_descriptor`, and `Entry` no longer exposes `data_descriptor()`.
The former `max_preserved_source_bytes` limit and `PreservedSourceBytes` error
kind are replaced by the existing package-size limit. Limit errors now carry
64-bit ceilings and actual values.

Internal format and tuning constants are private. Use `deflate_bound` to size
compression output. Filename-based compression selection belongs to the caller;
the CLI supplies its own policy.

ZIP payload CRC and gzip FHCRC are verified. A damaged checksum raises
`ChecksumMismatch`; malformed ZIP DEFLATE data raises `InvalidDeflate`, and
cancellation during ZIP decompression remains `Cancelled`.
`deflate_bound` rejects negative or unrepresentable capacities.

Use `!=` for inequality and `@debug.Repr(value)` for debugging.
