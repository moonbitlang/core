// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Property sweep against an association array carrying the same ordering rule:
// a fresh key is appended, a key already present is overwritten where it sits.
// That array IS the specification — `agrees_with_model` demands the map expose
// exactly its entries, in exactly its order, through every traversal, and that
// a map rebuilt from that content compares and hashes equal to the map that
// reached it by operations. The interesting pressure is deletion: holes and the
// rebuild that reclaims them are invisible to this model, so any slot that
// survives an operation it should not, or any index left pointing at a stale
// position, shows up as disagreement.

///|
/// Append if new, overwrite in place if present — `VectorMap::add`.
fn model_add(model : Array[(Int, Int)], key : Int, value : Int) -> Unit {
  for i, kv in model {
    if kv.0 == key {
      model[i] = (key, value)
      return
    }
  }
  model.push((key, value))
}

///|
fn model_remove(model : Array[(Int, Int)], key : Int) -> Unit {
  for i, kv in model {
    if kv.0 == key {
      model.remove(i) |> ignore
      return
    }
  }
}

///|
/// The full specification check for one state.
fn agrees_with_model(
  map : @vector_map.VectorMap[Int, Int],
  model : Array[(Int, Int)],
) -> Bool {
  guard map.length() == model.length() else { return false }
  guard map.is_empty() == model.is_empty() else { return false }
  // Order and content, as seen through the array conversion…
  guard map.to_array() == model else { return false }
  // …and independently through each other traversal, since they walk the
  // spine by different routes.
  let via_each = []
  map.each((k, v) => via_each.push((k, v)))
  guard via_each == model else { return false }
  let via_fold = map.fold(init=[], (acc : Array[(Int, Int)], k, v) => {
    acc.push((k, v))
    acc
  })
  guard via_fold == model else { return false }
  guard map.keys().to_array() == model.map(kv => kv.0) else { return false }
  guard map.values().to_array() == model.map(kv => kv.1) else { return false }
  // `eachi` must number the live entries densely, whatever the spine holds.
  let ranks = []
  map.eachi((i, _, _) => ranks.push(i))
  guard ranks == Array::makei(model.length(), i => i) else { return false }
  // Lookups agree across the whole key universe, absences included.
  for key in 0..<32 {
    let expected = for kv in model {
      if kv.0 == key {
        break Some(kv.1)
      }
    } nobreak {
      None
    }
    guard map.get(key) == expected else { return false }
    guard map.contains(key) == (expected is Some(_)) else { return false }
  }
  // Same content reached by any history is the same value: equal, and equally
  // hashed. This is what catches a stale index or an unreclaimed slot.
  let rebuilt = @vector_map.from_iter(model.iter())
  guard map == rebuilt else { return false }
  let h1 = Hasher()
  h1.combine(map)
  let h2 = Hasher()
  h2.combine(rebuilt)
  h1.finalize() == h2.finalize()
}

///|
/// Interpret `ops` as a stream of operations over a 32-key universe, mirroring
/// each on the model and demanding agreement after every single step.
///
/// `remove_bias` skews the operation mix towards deletion AND starts from a map
/// already holding the whole key universe. Both are needed to reach the regime
/// where trimming and compaction run at all: a stream that starts empty and
/// removes more than it adds simply stays empty, and a spine under 32 slots is
/// never rebuilt however holey it gets.
fn ops_agree(ops : Array[Int], remove_bias~ : Bool) -> Bool {
  let model : Array[(Int, Int)] = []
  let mut map : @vector_map.VectorMap[Int, Int] = @vector_map.new()
  if remove_bias {
    for key in 0..<32 {
      map = map.add(key, key)
      model_add(model, key, key)
    }
  }
  for op in ops {
    let n = op & 0x7fffffff
    let key = n / 8 % 32
    let value = n / 256 % 11
    // Two adds against four removes, so the population drains while still
    // being replenished — which is what keeps appending fresh slots past the
    // holes left behind.
    let choice = if remove_bias {
      // Only adds and removes: `filter` and `map` rebuild the spine dense, and
      // mixing them in here would keep resetting the very hole accumulation
      // this variant exists to produce.
      match n % 6 {
        0 | 1 => 0
        _ => 3
      }
    } else {
      n % 8
    }
    match choice {
      0 | 1 | 2 => {
        map = map.add(key, value)
        model_add(model, key, value)
      }
      3 | 4 => {
        map = map.remove(key)
        model_remove(model, key)
      }
      5 => {
        // `update` must equal add-or-remove depending on what it returns.
        map = map.update(key, old => {
          if old is Some(v) && v % 2 == 0 {
            None
          } else {
            Some(value)
          }
        })
        let old = for kv in model {
          if kv.0 == key {
            break Some(kv.1)
          }
        } nobreak {
          None
        }
        if old is Some(v) && v % 2 == 0 {
          model_remove(model, key)
        } else {
          model_add(model, key, value)
        }
      }
      6 => {
        map = map.filter((k, v) => (k + v) % 3 != 0)
        model.retain(kv => (kv.0 + kv.1) % 3 != 0)
      }
      _ => {
        // `map` rewrites values without touching keys or their order.
        map = map.map((k, v) => (v * 2 + k) % 11)
        for i, kv in model {
          model[i] = (kv.0, (kv.1 * 2 + kv.0) % 11)
        }
      }
    }
    guard agrees_with_model(map, model) else { return false }
  }
  true
}

///|
test "quickcheck: operation sequences agree with the ordered model" {
  @quickcheck.check(
    (ops : Array[Int]) => ops_agree(ops, remove_bias=false),
    count=300,
  )
}

///|
test "quickcheck: deletion-heavy sequences agree too" {
  // Same property, but starting from a full universe and draining it, so the
  // spine spends the run accumulating holes and reclaiming them.
  @quickcheck.check(
    (ops : Array[Int]) => ops_agree(ops, remove_bias=true),
    count=300,
  )
}

///|
/// Build a map and its model from raw pairs, applying the ordering rule.
fn build(
  entries : Array[(Int, Int)],
) -> (@vector_map.VectorMap[Int, Int], Array[(Int, Int)]) {
  let model : Array[(Int, Int)] = []
  // Masking rather than `%` keeps keys inside the probed universe for
  // negative inputs too, and cannot overflow on `Int::min_value`.
  let normalised = entries.map(kv => (kv.0 & 31, kv.1 & 7))
  for kv in normalised {
    model_add(model, kv.0, kv.1)
  }
  (VectorMap(normalised), model)
}

///|
test "quickcheck: bulk construction matches repeated add" {
  @quickcheck.check(
    (entries : Array[(Int, Int)]) => {
      let (map, model) = build(entries)
      guard agrees_with_model(map, model) else { return false }
      // The array constructor, the iterator constructor and a fold of `add`
      // must all land on the same value.
      let by_add = entries
        .map(kv => (kv.0 & 31, kv.1 & 7))
        .fold(init=@vector_map.new(), (m, kv) => m.add(kv.0, kv.1))
      guard map == by_add else { return false }
      map ==
      @vector_map.from_iter(entries.iter().map(kv => (kv.0 & 31, kv.1 & 7)))
    },
    count=300,
  )
}

///|
test "quickcheck: persistence — an operation never disturbs its receiver" {
  @quickcheck.check(
    (input : (Array[(Int, Int)], Int, Int)) => {
      let (entries, raw_key, raw_value) = input
      let (map, model) = build(entries)
      let key = raw_key & 31
      let value = raw_value & 7
      // Derive several new versions, then require the original intact.
      let _ = map.add(key, value)
      let _ = map.remove(key)
      let _ = map.filter((k, _) => k % 2 == 0)
      let _ = map.map((_, v) => v + 1)
      let _ = map.update(key, _ => Some(value))
      agrees_with_model(map, model)
    },
    count=200,
  )
}

///|
test "quickcheck: equality is exactly same-entries-same-order" {
  @quickcheck.check(
    (input : (Array[(Int, Int)], Int)) => {
      let (entries, raw_shift) = input
      let (map, model) = build(entries)
      guard map == @vector_map.from_iter(model.iter()) else { return false }
      // A rotation of a map with at least two distinct positions changes the
      // order, so it must compare unequal.
      let n = model.length()
      guard n >= 2 else { return true }
      // `abs` would overflow on `Int::min_value`; masking cannot.
      let shift = (raw_shift & 0x7fffffff) % (n - 1) + 1
      let rotated = Array::makei(n, i => model[(i + shift) % n])
      let rotated_map = @vector_map.from_iter(rotated.iter())
      // Same entries either way…
      guard rotated_map.length() == map.length() else { return false }
      for kv in model {
        guard rotated_map.get(kv.0) == Some(kv.1) else { return false }
      }
      guard map != rotated_map else { return false }
      // Perturbing a single value, leaving keys and order alone, must also be
      // enough to make them unequal.
      let (k0, v0) = model[0]
      guard map != map.add(k0, v0 + 1) else { return false }
      // A proper prefix must compare unequal from BOTH sides — a length check
      // that only caught the short side on the right would leave `Eq`
      // asymmetric, and comparing entry by entry would not notice.
      let prefix = @vector_map.from_iter(model.iter().take(n - 1))
      map != prefix && prefix != map
    },
    count=300,
  )
}

///|
test "quickcheck: json survives a round trip, order included" {
  @quickcheck.check(
    (entries : Array[(Int, Int)]) => {
      let (map, _) = build(entries)
      let decoded : @vector_map.VectorMap[Int, Int]? = Some(
        @json.from_json(@json.to_json(map)),
      ) catch {
        _ => None
      }
      guard decoded is Some(back) else { return false }
      back == map && back.to_array() == map.to_array()
    },
    count=200,
  )
}
