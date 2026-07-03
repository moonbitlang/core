///|
let bytes_from_array_bench_size : Int = 256 * 1024

///|
let bytes_from_array_bench_source : FixedArray[Byte] = FixedArray::makei(
  bytes_from_array_bench_size + 1,
  fn(i) { (i & 0xff).to_byte() },
)

///|
fn bytes_from_array_bench_makei(arr : ArrayView[Byte]) -> Bytes {
  Bytes::makei(arr.length(), fn(i) { arr[i] })
}

///|
test "bench Bytes::from_array n=262144 full" (it : @bench.T) {
  it.bench(fn() {
    it.keep(
      Bytes::from_array(
        bytes_from_array_bench_source[:bytes_from_array_bench_size],
      ),
    )
  })
}

///|
test "bench Bytes::from_array n=262144 sliced" (it : @bench.T) {
  it.bench(fn() {
    it.keep(Bytes::from_array(bytes_from_array_bench_source[1:]))
  })
}

///|
test "bench Bytes::makei from ArrayView n=262144 full" (it : @bench.T) {
  it.bench(fn() {
    it.keep(
      bytes_from_array_bench_makei(
        bytes_from_array_bench_source[:bytes_from_array_bench_size],
      ),
    )
  })
}

///|
test "bench Bytes::makei from ArrayView n=262144 sliced" (it : @bench.T) {
  it.bench(fn() {
    it.keep(bytes_from_array_bench_makei(bytes_from_array_bench_source[1:]))
  })
}
