///|
let ascii_bench_size = 100_000

///|
let ascii_bench_bytes : Bytes = Bytes::make(ascii_bench_size, b'A')

///|
let ascii_bench_large_size = 1_000_000

///|
let ascii_bench_large_bytes : Bytes = Bytes::make(ascii_bench_large_size, b'A')

///|
let ascii_bench_bytes_15 : Bytes = Bytes::make(15, b'A')

///|
let ascii_bench_bytes_16 : Bytes = Bytes::make(16, b'A')

///|
let ascii_bench_bytes_32 : Bytes = Bytes::make(32, b'A')

///|
let ascii_bench_bytes_64 : Bytes = Bytes::make(64, b'A')

///|
test "bench ASCII decode n=15" (it : @bench.T) {
  let bytes = ascii_bench_bytes_15
  it.bench(fn() { it.keep((try! @ascii.decode(bytes)).length()) })
}

///|
test "bench ASCII decode n=16" (it : @bench.T) {
  let bytes = ascii_bench_bytes_16
  it.bench(fn() { it.keep((try! @ascii.decode(bytes)).length()) })
}

///|
test "bench ASCII decode n=32" (it : @bench.T) {
  let bytes = ascii_bench_bytes_32
  it.bench(fn() { it.keep((try! @ascii.decode(bytes)).length()) })
}

///|
test "bench ASCII decode n=64" (it : @bench.T) {
  let bytes = ascii_bench_bytes_64
  it.bench(fn() { it.keep((try! @ascii.decode(bytes)).length()) })
}

///|
test "bench ASCII decode n=100000" (it : @bench.T) {
  let bytes = ascii_bench_bytes
  it.bench(fn() { it.keep((try! @ascii.decode(bytes)).length()) })
}

///|
test "bench ASCII decode n=1000000" (it : @bench.T) {
  let bytes = ascii_bench_large_bytes
  it.bench(fn() { it.keep((try! @ascii.decode(bytes)).length()) })
}
