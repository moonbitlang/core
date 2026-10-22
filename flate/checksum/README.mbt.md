# checksum

CRC-32 and Adler-32 checksums with one-shot and incremental APIs.
The package is `moonbitlang/core/flate/checksum` and depends only on MoonBit
core. It has no dependency on compression, I/O, or cancellation callbacks.

CRC-32 uses the reflected IEEE polynomial `0xEDB88320`, an initial state of
`0xFFFFFFFF`, and a final XOR of `0xFFFFFFFF`. Adler-32 uses modulus 65521.

Import the package in `moon.pkg`:

```moon.pkg
import {
  "moonbitlang/core/flate/checksum",
}
```

For a complete byte sequence or a view into one:

```moonbit nocheck
///|
let crc = @checksum.crc32(b"hello")

///|
let adler = @checksum.adler32(b"hello")
```

For incremental input:

```moonbit nocheck
let crc = @checksum.Crc32()
crc.update(b"hel")
crc.update(b"lo")
let result = crc.finish()
```

`Adler32` has the same `update`, `update_byte`, and `finish` operations.
`finish` is non-destructive: subsequent updates continue the same checksum.
Callers can implement cancellation or scheduling between `update` calls.

The package is part of the `moonbitlang/core` module.
