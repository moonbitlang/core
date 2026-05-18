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
test "ReadOnlyArray constructors" {
  // Test from_array - keep this test as it specifically tests from_array
  let arr1 = ReadOnlyArray::from_array([1, 2, 3])
  inspect(arr1[0], content="1")
  inspect(arr1[2], content="3")

  // Test from_iter
  let arr2 = ReadOnlyArray::from_iter([4, 5, 6].iter())
  inspect(arr2[1], content="5")

  // Test makei
  let arr3 = ReadOnlyArray::makei(3, fn(i) { i * 10 })
  inspect(arr3[0], content="0")
  inspect(arr3[2], content="20")
}

///|
test "ReadOnlyArray access methods" {
  let arr : ReadOnlyArray[Int] = [10, 20, 30]

  // Test get
  debug_inspect(arr.get(1), content="Some(20)")
  debug_inspect(arr.get(5), content="None")

  // Test length
  inspect(arr.length(), content="3")

  // Test is_empty
  inspect(arr.is_empty(), content="false")
  let empty : ReadOnlyArray[Int] = []
  inspect(empty.is_empty(), content="true")

  // Test last
  debug_inspect(arr.last(), content="Some(30)")
  debug_inspect(empty.last(), content="None")
}

///|
test "ReadOnlyArray functional methods" {
  let arr : ReadOnlyArray[Int] = [1, 2, 3]

  // Test map
  let doubled = arr.map(x => x * 2)
  inspect(doubled[0], content="2")
  inspect(doubled[2], content="6")

  // Test fold
  let sum = arr.fold(init=0, fn(acc, x) { acc + x })
  inspect(sum, content="6")

  // Test rev
  let reversed = arr.rev()
  inspect(reversed[0], content="3")
  inspect(reversed[2], content="1")
}

///|
test "ReadOnlyArray filter and filter_map" {
  let arr : ReadOnlyArray[Int] = [1, 2, 3, 4, 5]
  let evens = arr.filter(x => x % 2 == 0)
  inspect(evens.length(), content="2")
  inspect(evens[0], content="2")
  inspect(evens[1], content="4")

  // filter_map: keep evens, multiply by 10.
  let mapped = arr.filter_map(x => if x % 2 == 0 { Some(x * 10) } else { None })
  inspect(mapped.length(), content="2")
  inspect(mapped[0], content="20")
  inspect(mapped[1], content="40")

  // Empty input passes through.
  let empty : ReadOnlyArray[Int] = []
  inspect(empty.filter(_ => true).length(), content="0")
  inspect(empty.filter_map(x => Some(x)).length(), content="0")

  // No element passes / all dropped.
  inspect(arr.filter(_ => false).length(), content="0")
  let none_out : ReadOnlyArray[Int] = arr.filter_map(_ => None)
  inspect(none_out.length(), content="0")
}

///|
test "ReadOnlyArray search methods" {
  let arr : ReadOnlyArray[Int] = [1, 2, 3, 2, 4]

  // Test search
  debug_inspect(arr.search(2), content="Some(1)")
  debug_inspect(arr.search(5), content="None")

  // Test search_by
  debug_inspect(arr.search_by(x => x > 2), content="Some(2)")
  debug_inspect(arr.search_by(x => x > 99), content="None")

  // Test contains
  inspect(arr.contains(3), content="true")
  inspect(arr.contains(5), content="false")

  // Test all/any
  let even_arr : ReadOnlyArray[Int] = [2, 4, 6]
  inspect(even_arr.all(x => x % 2 == 0), content="true")
  inspect(arr.any(x => x % 2 == 0), content="true")
}

///|
test "ReadOnlyArray trait implementations" {
  // Test Default
  let empty : ReadOnlyArray[Int] = ReadOnlyArray::default()
  inspect(empty.length(), content="0")

  // Test Debug
  let arr : ReadOnlyArray[Int] = [1, 2, 3]
  debug_inspect(
    arr,
    content=(
      #|<ReadOnlyArray: [1, 2, 3]>
    ),
  )

  // Test join for strings
  let str_arr : ReadOnlyArray[String] = ["a", "b", "c"]
  inspect(str_arr.join(","), content="a,b,c")

  // Test join for any ToStringView element (here: StringView).
  let view_arr : ReadOnlyArray[StringView] = ["a"[:], "b"[:], "c"[:]]
  inspect(view_arr.join("-"), content="a-b-c")
}

///|
test "ReadOnlyArray equal" {
  // Test equal arrays
  let arr1 : ReadOnlyArray[Int] = [1, 2, 3]
  let arr2 : ReadOnlyArray[Int] = [1, 2, 3]
  inspect(arr1 == arr2, content="true")

  // Test unequal arrays with different values
  let arr3 : ReadOnlyArray[Int] = [1, 3, 3]
  inspect(arr1 == arr3, content="false")

  // Test arrays of different lengths
  let arr4 : ReadOnlyArray[Int] = [1, 2]
  inspect(arr1 == arr4, content="false")

  // Test empty arrays
  let empty1 : ReadOnlyArray[Int] = []
  let empty2 : ReadOnlyArray[Int] = []
  inspect(empty1 == empty2, content="true")

  // Test empty vs non-empty
  inspect(empty1 == arr1, content="false")
}

///|
test "ReadOnlyArray compare" {
  let arr1 : ReadOnlyArray[Int] = [1, 2, 3]
  let arr2 : ReadOnlyArray[Int] = [1, 2, 4]
  let arr3 : ReadOnlyArray[Int] = [1, 2]

  // Test lexicographic comparison
  inspect(arr1.compare(arr2), content="-1") // arr1 < arr2
  inspect(arr2.compare(arr1), content="1") // arr2 > arr1

  // Test length comparison when prefixes are equal
  inspect(arr1.compare(arr3), content="1") // arr1 > arr3 (longer)
  inspect(arr3.compare(arr1), content="-1") // arr3 < arr1 (shorter)

  // Test equal arrays
  inspect(arr1.compare(arr1), content="0") // arr1 = arr1

  // Test empty arrays
  let empty1 : ReadOnlyArray[Int] = []
  let empty2 : ReadOnlyArray[Int] = []
  inspect(empty1.compare(empty2), content="0") // empty = empty
  inspect(empty1.compare(arr1), content="-1") // empty < non-empty
  inspect(arr1.compare(empty1), content="1") // non-empty > empty
}

///|
test "ReadOnlyArray chunks and windows" {
  let arr : ReadOnlyArray[Int] = [1, 2, 3, 4, 5, 6, 7]
  debug_inspect(
    arr.chunks(3),
    content=(
      #|[<ArrayView: [1, 2, 3]>, <ArrayView: [4, 5, 6]>, <ArrayView: [7]>]
    ),
  )
  // Exact multiple: no trailing short chunk.
  debug_inspect(
    arr.chunks(7),
    content=(
      #|[<ArrayView: [1, 2, 3, 4, 5, 6, 7]>]
    ),
  )
  // Empty input gives no chunks.
  let empty : ReadOnlyArray[Int] = []
  debug_inspect(empty.chunks(3), content="[]")

  // Windows: length - size + 1 entries.
  let small : ReadOnlyArray[Int] = [1, 2, 3, 4]
  debug_inspect(
    small.windows(2),
    content=(
      #|[<ArrayView: [1, 2]>, <ArrayView: [2, 3]>, <ArrayView: [3, 4]>]
    ),
  )
  debug_inspect(
    small.windows(4),
    content=(
      #|[<ArrayView: [1, 2, 3, 4]>]
    ),
  )
  // size > length yields empty.
  debug_inspect(small.windows(5), content="[]")
}

///|
test "ReadOnlyArray chunk_by and suffixes" {
  let arr : ReadOnlyArray[Int] = [1, 1, 2, 2, 2, 3, 1]
  debug_inspect(
    arr.chunk_by((a, b) => a == b),
    content=(
      #|[
      #|  <ArrayView: [1, 1]>,
      #|  <ArrayView: [2, 2, 2]>,
      #|  <ArrayView: [3]>,
      #|  <ArrayView: [1]>,
      #|]
    ),
  )

  // Empty input.
  let empty : ReadOnlyArray[Int] = []
  debug_inspect(empty.chunk_by((a, b) => a == b), content="[]")

  // Singleton: one chunk.
  let single : ReadOnlyArray[Int] = [42]
  debug_inspect(
    single.chunk_by((a, b) => a == b),
    content=(
      #|[<ArrayView: [42]>]
    ),
  )

  // suffixes.
  let pair : ReadOnlyArray[Int] = [1, 2]
  debug_inspect(
    pair.suffixes().collect(),
    content=(
      #|[<ArrayView: [1, 2]>, <ArrayView: [2]>]
    ),
  )
  debug_inspect(
    pair.suffixes(include_empty=true).collect(),
    content=(
      #|[<ArrayView: [1, 2]>, <ArrayView: [2]>, <ArrayView: []>]
    ),
  )

  // Suffixes on empty input: nothing unless include_empty.
  debug_inspect(empty.suffixes().collect(), content="[]")
  debug_inspect(
    empty.suffixes(include_empty=true).collect(),
    content=(
      #|[<ArrayView: []>]
    ),
  )
}

///|
test "ReadOnlyArray strip_prefix and strip_suffix" {
  let arr : ReadOnlyArray[Int] = [1, 2, 3, 4, 5]
  debug_inspect(
    arr.strip_prefix([1, 2][:]),
    content=(
      #|Some(<ArrayView: [3, 4, 5]>)
    ),
  )
  debug_inspect(arr.strip_prefix([2, 3][:]), content="None")
  debug_inspect(
    arr.strip_suffix([4, 5][:]),
    content=(
      #|Some(<ArrayView: [1, 2, 3]>)
    ),
  )
  debug_inspect(arr.strip_suffix([3, 4][:]), content="None")

  // Empty prefix / suffix returns the full / empty trailing view.
  debug_inspect(
    arr.strip_prefix([][:]),
    content=(
      #|Some(<ArrayView: [1, 2, 3, 4, 5]>)
    ),
  )
}

///|
test "ReadOnlyArray iter and sub" {
  let arr : ReadOnlyArray[Int] = [1, 2, 3]
  debug_inspect(arr.iter().to_array(), content="[1, 2, 3]")
  debug_inspect(arr.rev_iter().to_array(), content="[3, 2, 1]")
  let empty : ReadOnlyArray[Int] = []
  debug_inspect(empty.rev_iter().to_array(), content="[]")
  debug_inspect(
    arr[1:],
    content=(
      #|<ArrayView: [2, 3]>
    ),
  )
}

///|
test "ReadOnlyArray json and hash" {
  let arr : ReadOnlyArray[Int] = [1, 2, 3]
  @json.json_inspect(arr, content=[1, 2, 3])
  let hasher = Hasher::new(seed=0)
  hasher.combine(arr)
  inspect(hasher.finalize() != 0, content="true")
}
