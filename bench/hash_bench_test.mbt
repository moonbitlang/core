///|
test "bench Hash for Bytes (small)" (it : @bench.T) {
  let data = Bytes::make(16, 0xAB)
  it.bench(fn() { it.keep(Hash::hash(data)) })
}

///|
test "bench Hash for Bytes (medium)" (it : @bench.T) {
  let data = Bytes::make(256, 0xAB)
  it.bench(fn() { it.keep(Hash::hash(data)) })
}

///|
test "bench Hash for Bytes (large)" (it : @bench.T) {
  let data = Bytes::make(4096, 0xAB)
  it.bench(fn() { it.keep(Hash::hash(data)) })
}

///|
test "bench Hash for BytesView (small)" (it : @bench.T) {
  let data = Bytes::make(16, 0xAB)
  let view = data.view()
  it.bench(fn() { it.keep(Hash::hash(view)) })
}

///|
test "bench Hash for BytesView (medium)" (it : @bench.T) {
  let data = Bytes::make(256, 0xAB)
  let view = data.view()
  it.bench(fn() { it.keep(Hash::hash(view)) })
}

///|
test "bench Hash for BytesView (large)" (it : @bench.T) {
  let data = Bytes::make(4096, 0xAB)
  let view = data.view()
  it.bench(fn() { it.keep(Hash::hash(view)) })
}
