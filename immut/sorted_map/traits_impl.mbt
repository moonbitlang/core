///|
pub impl[K, V] Default for T[K, V] with default() { empty() }

///|
pub impl[K : Eq, V : Eq] Eq for T[K, V] with op_equal(self, other) -> Bool {
  let iter = InorderIterator::new(self)
  let iter1 = InorderIterator::new(other)
  loop iter.next(), iter1.next() {
    None, None => true
    Some(a), Some(b) => {
      guard a == b else { break false }
      continue iter.next(), iter1.next()
    }
    _, _ => false
  }
}

///|
pub impl[K : Compare, V : Compare] Compare for T[K, V] with compare(self, other) -> Int {
  let iter = InorderIterator::new(self)
  let iter1 = InorderIterator::new(other)
  loop iter.next(), iter1.next() {
    None, None => 0
    Some(a), Some(b) => {
      let cmp = a.compare(b)
      guard cmp == 0 else { break cmp }
      continue iter.next(), iter1.next()
    }
    Some(_), None => 1
    None, Some(_) => -1
  }
}

///|
pub impl[K : @quickcheck.Arbitrary + Compare, V : @quickcheck.Arbitrary] @quickcheck.Arbitrary for T[
  K,
  V,
] with arbitrary(size, rs) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> from_array
}

///|
pub impl[K : Hash, V : Hash] Hash for T[K, V] with hash_combine(self, hasher) {
  for e in self {
    hasher..combine(e.0).combine(e.1)
  }
}

///|
pub impl[K : Show, V : Show] Show for T[K, V] with output(self, logger) {
  logger.write_iter(self.iter(), prefix="@immut/sorted_map.of([", suffix="])")
}

///|
pub impl[K : Show, V : ToJson] ToJson for T[K, V] with to_json(self) {
  let capacity = self.size()
  guard capacity != 0 else { return Object(Map::new()) }
  let jsons = Map::new(capacity~)
  self.each(fn(k, v) { jsons[k.to_string()] = v.to_json() })
  Object(jsons)
}

///|
pub impl[V : @json.FromJson] @json.FromJson for T[String, V] with from_json(
  json,
  path
) {
  match json {
    Object(obj) => {
      let mut map = T::empty()
      for k, v in obj {
        map = map.add(k, V::from_json!(v, path))
      }
      map
    }
    _ =>
      raise @json.JsonDecodeError(
        (path, "@immut/sorted_map.from_json: expected object"),
      )
  }
}
