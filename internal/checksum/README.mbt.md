# Internal checksums

CRC-32 and Adler-32 implementations shared by gzip, zlib, and ZIP.
The package `moonbitlang/core/internal/checksum` is available only within
`moonbitlang/core`. It is shared by `compress/gzip`, `compress/zlib`, and
`archive/zip`, and is not a public checksum API.
It depends only on MoonBit core, with no dependency on compression, I/O, or
cancellation callbacks.

CRC-32 uses the reflected IEEE polynomial `0xEDB88320`, an initial state of
`0xFFFFFFFF`, and a final XOR of `0xFFFFFFFF`. Adler-32 uses modulus 65521.

Within core, import the package in `moon.pkg`:

```moon.pkg
import {
  "moonbitlang/core/internal/checksum",
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

The declarations remain `pub` for sharing between core packages; the `internal`
directory restricts which packages can import them.
