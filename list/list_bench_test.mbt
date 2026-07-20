///|
let list_bench_size = 100_000

///|
fn make_list_bench_array() -> Array[Int] {
  Array::makei(list_bench_size, i => i)
}

///|
test "bench List::from_array n=100000" (it : @bench.T) {
  let data = make_list_bench_array()
  it.bench(fn() { it.keep(@list.List(data)) })
}

///|
test "bench List::from_iter n=100000" (it : @bench.T) {
  let data = make_list_bench_array()
  it.bench(fn() { it.keep(@list.from_iter(data.iter())) })
}

///|
test "bench List::to_array n=100000" (it : @bench.T) {
  let data = @list.List(make_list_bench_array())
  it.bench(fn() { it.keep(data.to_array()) })
}

///|
test "bench List::each n=100000" (it : @bench.T) {
  let data = @list.List(make_list_bench_array())
  it.bench(fn() {
    let mut sum = 0
    data.each(x => sum += x)
    it.keep(sum)
  })
}

///|
test "bench List::fold n=100000" (it : @bench.T) {
  let data = @list.List(make_list_bench_array())
  it.bench(fn() { it.keep(data.fold(init=0, (sum, x) => sum + x)) })
}

///|
test "bench List::iter fold n=100000" (it : @bench.T) {
  let data = @list.List(make_list_bench_array())
  it.bench(fn() { it.keep(data.iter().fold(init=0, (sum, x) => sum + x)) })
}

///|
test "bench List::map n=100000" (it : @bench.T) {
  let data = @list.List(make_list_bench_array())
  it.bench(fn() { it.keep(data.map(x => x + 1)) })
}

///|
test "bench List::filter half n=100000" (it : @bench.T) {
  let data = @list.List(make_list_bench_array())
  it.bench(fn() { it.keep(data.filter(x => x % 2 == 0)) })
}

///|
test "bench List::concat n=50000+50000" (it : @bench.T) {
  let left = @list.List(Array::makei(list_bench_size / 2, i => i))
  let right = @list.List(Array::makei(list_bench_size / 2, i => i))
  it.bench(fn() { it.keep(left.concat(right)) })
}

///|
test "bench List::flat_map singleton n=100000" (it : @bench.T) {
  let data = @list.List(make_list_bench_array())
  it.bench(fn() { it.keep(data.flat_map(@list.singleton)) })
}

///|
test "bench List::zip n=100000" (it : @bench.T) {
  let data = @list.List(make_list_bench_array())
  it.bench(fn() { it.keep(data.zip(data)) })
}

///|
test "bench List::is_suffix n=100000 suffix=50000" (it : @bench.T) {
  let data = @list.List(make_list_bench_array())
  let suffix = data.drop(list_bench_size / 2)
  it.bench(fn() { it.keep(data.is_suffix(suffix)) })
}
