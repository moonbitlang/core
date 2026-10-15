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

///|
fn[T : Compare + Show] check_ordered_collections(
  nan : T,
  zero : T,
  one : T,
) -> Unit raise {
  let keys = [one, nan, zero, nan]
  let map = @sorted_map.SortedMap(keys.mapi((i, k) => (k, i)))
  inspect(map.length(), content="3")
  inspect(
    map.keys().map(Show::to_string).to_array().join(","),
    content="NaN,0,1",
  )
  debug_inspect(map.get(nan), content="Some(3)")
  map.update_or_default(nan, 10, x => x + 1)
  debug_inspect(map.get(nan), content="Some(4)")
  inspect(map.length(), content="3")
  inspect(map.range(nan, zero).iter().count(), content="2")
  inspect(compare(map.first_gt(nan).unwrap().0, zero), content="0")
  inspect(compare(map.last_lt(zero).unwrap().0, nan), content="0")
  map.remove(nan)
  inspect(map.contains(nan), content="false")
  inspect(map.length(), content="2")
  let imap = @imap.SortedMap(keys.mapi((i, k) => (k, i)))
  inspect(imap.length(), content="3")
  inspect(imap.get(nan) is Some(_), content="true")
  debug_inspect(imap.add(nan, 9).get(nan), content="Some(9)")
  inspect(imap.remove(nan).contains(nan), content="false")
  let set = @sorted_set.SortedSet(keys)
  inspect(set.length(), content="3")
  inspect(set.contains(nan), content="true")
  set.remove(nan)
  inspect(set.contains(nan), content="false")
  let iset = @iset.SortedSet(keys)
  inspect(iset.length(), content="3")
  inspect(iset.contains(nan), content="true")
  inspect(iset.add(nan).length(), content="3")
  inspect(iset.remove(nan).contains(nan), content="false")
  let queue = @priority_queue.PriorityQueue(keys)
  queue.push(nan)
  let popped = []
  while queue.pop() is Some(x) {
    popped.push(Show::to_string(x))
  }
  inspect(popped.join(","), content="1,0,NaN,NaN,NaN")
  let iqueue = @ipq.PriorityQueue(keys).push(nan)
  let popped = []
  for queue = iqueue; queue.peek() is Some(x); {
    popped.push(Show::to_string(x))
    continue queue.pop().unwrap()
  }
  inspect(popped.join(","), content="1,0,NaN,NaN,NaN")
  let list = @list.List(keys)
  inspect(compare(list.minimum().unwrap(), nan), content="0")
  inspect(compare(list.maximum().unwrap(), one), content="0")
  inspect(compare(keys.iter().minimum().unwrap(), nan), content="0")
  inspect(compare(keys.iter().maximum().unwrap(), one), content="0")
  inspect(compare(@cmp.minimum(one, nan), nan), content="0")
  inspect(compare(@cmp.maximum(nan, one), one), content="0")
  inspect(compare(@cmp.minimum_by_key(one, nan, x => x), nan), content="0")
  inspect(compare(@cmp.maximum_by_key(nan, one, x => x), one), content="0")
  inspect(compare(@cmp.minmax(one, nan).0, nan), content="0")
  inspect(compare(@cmp.minmax_by_key(one, nan, x => x).0, nan), content="0")
}

///|
test "ordered collections use NaN-first comparison for Double and Float" {
  check_ordered_collections(@double.not_a_number, 0.0, 1.0)
  check_ordered_collections(@float.not_a_number, Float(0), Float(1))
}

///|
test "large immutable collection builders deduplicate NaNs" {
  let nan = @double.not_a_number
  let keys = Array::makei(256, i => {
    if i % 3 == 0 {
      nan
    } else {
      (i % 17).to_double()
    }
  })
  let map = @imap.SortedMap(keys.mapi((i, k) => (k, i)))
  let set = @iset.SortedSet(keys)
  inspect(map.length(), content="18")
  inspect(set.length(), content="18")
  inspect(map.contains(nan), content="true")
  inspect(set.contains(nan), content="true")
  inspect(set.to_array().is_sorted(), content="true")
  inspect(map.remove(nan).length(), content="17")
  inspect(set.remove(nan).length(), content="17")
}
