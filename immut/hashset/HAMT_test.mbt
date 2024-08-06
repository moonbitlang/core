// Copyright 2024 International Digital Economy Academy
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

test "Set" {
  let map = loop 0, @hashset.new() {
    100, map => map
    i, map => continue i + 1, map.add(i)
  }
  for i = 0; i < 100; i = i + 1 {
    @test.eq!((i, map.contains(i)), (i, true))
  }
  inspect!((100, map.contains(100)), content="(100, false)")
  let map = map.add(100)
  inspect!((100, map.contains(100)), content="(100, true)")
}

test "@hashset.size" {
  for i = 0, set = @hashset.new(); i < 20; i = i + 1, set = set.add(i) {
    @test.eq!(set.size(), i)
  } else {
    @test.eq!(set.add(0).size(), 20)
  }
}

test "@hashset.remove" {
  let map = loop 0, @hashset.new() {
    100, map => map
    i, map => continue i + 1, map.add(i)
  }
  for i = 0; i < 100; i = i + 1 {
    @test.eq!((i, map.contains(i)), (i, true))
  }
  let map = loop 0, map {
    100, map => map.remove(100) // test for removing non-existing element
    i, map => continue i + 2, map.remove(i)
  }
  for i = 0; i < 100; i = i + 2 {
    @test.eq!(map.contains(i), false)
    @test.eq!(map.contains(i + 1), true)
  }
}

test "@hashset.iter" {
  let data = @hashset.of(["a", "b", "d", "e", "f"])
  let mut s = ""
  data.iter().each(fn { k => s += " \{k}" })
  inspect!(s, content=" e f b a d")
}

test "@hashset.to_string" {
  let set = @hashset.new().add(1).add(3).add(0x0f_ff_ff_ff).add(42)
  inspect!(set, content="@immut/hashset.of([3, 42, 1, 268435455])")
}

test "@hashset.from_array" {
  let set = @hashset.of(["1", "2", "42"])
  inspect!(set.contains("1"), content="true")
  inspect!(set.contains("2"), content="true")
  inspect!(set.contains("42"), content="true")
  inspect!(set.contains("43"), content="false")
}

test "@hashset.is_empty" {
  let set = @hashset.new()
  inspect!(set.is_empty(), content="true")
  let set = set.add(1)
  inspect!(set.is_empty(), content="false")
}

test "@hashset.size" {
  let set = @hashset.new()
  @test.eq!(set.size(), 0)
  let set = set.add(1)
  @test.eq!(set.size(), 1)
  let set = set.add(2)
  @test.eq!(set.size(), 2)
  let set = set.remove(1)
  @test.eq!(set.size(), 1)
}

test "@hashset.is_empty" {
  let set = @hashset.new()
  @test.eq!(set.is_empty(), true)
  let set = set.add(1)
  @test.eq!(set.is_empty(), false)
  let set = set.remove(1)
  @test.eq!(set.is_empty(), true)
}

test "@hashset.iter" {
  let set = @hashset.new().add(1).add(2).add(3)
  let result = []
  set.each(fn { x => result.push(x) })
  result.sort()
  @test.eq!(result, [1, 2, 3])
}

test "@hashset.iter" {
  let set = @hashset.new().add(1).add(2).add(3)
  let result = []
  set.iter().each(fn { x => result.push(x) })
  result.sort()
  @test.eq!(result, [1, 2, 3])
}

test "from_iter multiple elements iter" {
  inspect!(
    @hashset.T::from_iter([1, 2, 3].iter()),
    content="@immut/hashset.of([3, 2, 1])",
  )
}

test "from_iter single element iter" {
  inspect!(@hashset.T::from_iter([1].iter()), content="@immut/hashset.of([1])")
}

test "from_iter empty iter" {
  let pq : @hashset.T[Int] = @hashset.T::from_iter(Iter::empty())
  inspect!(pq, content="@immut/hashset.of([])")
}
