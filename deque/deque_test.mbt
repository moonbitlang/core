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

test "search" {
  let dv = @deque.of([3, 4, 5])
  assert_eq!(dv.search(3), Some(0))
  assert_eq!(dv.search(4), Some(1))
  assert_eq!(dv.search(5), Some(2))
  assert_eq!(dv.search(6), None)
}

test "contains" {
  let dv = @deque.of([3, 4, 5])
  assert_true!(dv.contains(3))
  assert_true!(dv.contains(4))
  assert_true!(dv.contains(5))
  assert_false!(dv.contains(6))
}

test "reserve_capacity" {
  let dv = @deque.of([1, 2, 3, 4, 5])
  dv.pop_front() |> ignore() // 2, 3, 4, 5
  dv.push_back(1) // 2, 3, 4, 5, 1
  dv.pop_front() |> ignore() // 3, 4, 5, 1
  dv.pop_front() |> ignore() // 4, 5, 1
  dv.reserve_capacity(10)
  assert_true!(dv.capacity() == 10)
  assert_eq!(dv[0], 4)
  assert_eq!(dv[1], 5)
  assert_eq!(dv[2], 1)
}

test "reserve_capacity_2" {
  let dv = @deque.of([1, 2, 3, 4, 5])
  dv.reserve_capacity(3)
  assert_true!(dv.capacity() == 5)
}

test "shrink_to_fit" {
  let dv = @deque.of([1, 2, 3, 4, 5])
  dv.pop_front() |> ignore()
  dv.push_back(1)
  dv.pop_front() |> ignore()
  dv.pop_front() |> ignore()
  assert_true!(dv.capacity() == 5)
  dv.shrink_to_fit()
  assert_true!(dv.capacity() == 3)
  assert_eq!(dv[0], 4)
  assert_eq!(dv[1], 5)
  assert_eq!(dv[2], 1)
}

test "shrink_to_fit_2" {
  let dv = @deque.of([1, 2, 3])
  assert_true!(dv.capacity() == 3)
  dv.shrink_to_fit()
  assert_true!(dv.capacity() == 3)
}

test "iter" {
  let dv = @deque.of([1, 2, 3, 4, 5])
  let iter = dv.iter()
  let buf = StringBuilder::new(size_hint=0)
  let mut i = 0
  iter.each(fn(x) {
    buf.write_string(x.to_string())
    buf.write_char('\n')
    i = i + 1
  })
  assert_eq!(i, dv.length())
  inspect!(
    buf,
    content=
      #|1
      #|2
      #|3
      #|4
      #|5
      #|
    ,
  )
  inspect!(
    iter.take(4).filter(fn(x) { x % 2 == 0 }).fold(fn(a, x) { a + x }, init=0),
    content="6",
  )
}

test "reserve and push" {
  // capacity > 0, len = 0
  let a = @deque.new(capacity=2)
  a.push_back(Option::Some(1))
  inspect!(a.front(), content="Some(Some(1))")
  inspect!(a.back(), content="Some(Some(1))")
  // capacity = 0, len = 0
  let b = @deque.new(capacity=0)
  b.push_back(Option::Some(1))
  inspect!(b.front(), content="Some(Some(1))")
  inspect!(b.back(), content="Some(Some(1))")
  // capacity > 0, len = 0
  let c = @deque.new(capacity=2)
  c.push_front(Option::Some(1))
  inspect!(c.front(), content="Some(Some(1))")
  inspect!(c.back(), content="Some(Some(1))")
  // capacity = 0, len = 0
  let d = @deque.new(capacity=0)
  d.push_front(Option::Some(1))
  inspect!(d.front(), content="Some(Some(1))")
  inspect!(d.back(), content="Some(Some(1))")
}

test "mapi" {
  let dv = @deque.of([3, 4, 5])
  let dvp = dv.mapi(fn(i, x) { x + i })
  inspect!(dvp[0], content="3")
  inspect!(dvp[1], content="5")
  inspect!(dvp[2], content="7")
  let dve = @deque.of(([] : FixedArray[Int]))
  inspect!(dve.mapi(fn(_idx, x) { x }), content="@deque.of([])")
}

test "iter_rev" {
  let mut i = 6
  let mut failed = false
  @deque.of([1, 2, 3, 4, 5]).rev_each(fn(elem) {
    if elem != i - 1 {
      failed = true
    }
    i = i - 1
  })
  assert_false!(failed)
}

test "iter_revi" {
  let mut i = 6
  let mut j = 0
  let mut failed = false
  @deque.of([1, 2, 3, 4, 5]).rev_eachi(fn(index, elem) {
    if index != j || elem != i - 1 {
      failed = true
    }
    i = i - 1
    j = j + 1
  })
  assert_false!(failed)
}

test "iteri" {
  let mut i = 0
  let mut failed = false
  @deque.of([1, 2, 3, 4, 5]).eachi(fn(index, elem) {
    if index != i || elem != i + 1 {
      failed = true
    }
    i = i + 1
  })
  assert_false!(failed)
}

test "iter" {
  let mut i = 0
  let mut failed = false
  @deque.of([1, 2, 3, 4, 5]).each(fn(elem) {
    if elem != i + 1 {
      failed = true
    }
    i = i + 1
  })
  assert_false!(failed)
}

test "iter2" {
  let v = @deque.of([1, 2, 3, 4, 5])
  v.unsafe_pop_front()
  v.unsafe_pop_back()
  let mut sum = 0
  v.each(fn { x => sum += x })
  inspect!(sum, content="9")
}

test "op_get" {
  let dv = @deque.of([1, 2, 3, 4, 5])
  inspect!(dv, content="@deque.of([1, 2, 3, 4, 5])")
  dv.pop_front() |> ignore
  dv.push_back(1)
  inspect!(dv[4], content="1")
  dv.push_front(2)
  inspect!(dv[0], content="2")
}

test "from_array" {
  inspect!(@deque.from_array(([] : Array[Int])), content="@deque.of([])")
  inspect!(@deque.of([1, 2, 3]), content="@deque.of([1, 2, 3])")
}

test "copy" {
  inspect!((@deque.new() : @deque.T[Int]).copy(), content="@deque.of([])")
  let deq = @deque.of([1, 2, 3])
  let deq1 = deq.copy()
  deq1[0] = 111
  inspect!(deq, content="@deque.of([1, 2, 3])")
  inspect!(deq1, content="@deque.of([111, 2, 3])")
}

test "op_set" {
  let dv = @deque.of([1, 2, 3, 4, 5])
  dv[1] = 3
  assert_eq!(dv[1], 3)
}

test "op_equal" {
  let dv1 = @deque.of([1, 2, 3])
  let dv2 = @deque.of([1, 2, 3])
  assert_true!(dv1 == dv2)
  let dv1 = @deque.of([1, 2, 3])
  let dv2 = @deque.of([1, 2, 3])
  dv2[0] = 2
  assert_false!(dv1 == dv2)
  let dv1 = @deque.of([1, 2, 3])
  let dv2 = @deque.of([1, 2, 3])
  dv2.push_front(1)
  assert_false!(dv1 == dv2)
}

test "clear" {
  let dv = @deque.of([3, 4, 5])
  dv.clear()
  assert_eq!(dv.length(), 0)
  assert_eq!(dv.capacity(), 3)
}

test "map" {
  let dv = @deque.of([3, 4, 5])
  let dvp = dv.map(fn(x) { x + 1 })
  assert_eq!(dvp[0], 4)
  assert_eq!(dvp[1], 5)
  assert_eq!(dvp[2], 6)
  let dve = @deque.of(([] : FixedArray[Int]))
  inspect!(dve.map(fn(x) { x }), content="@deque.of([])")
}

test "push_and_pop" {
  let dv = @deque.of([1, 2, 3, 4, 5])
  assert_eq!(dv.pop_back(), Some(5))
  assert_eq!(dv.length(), 4)
  assert_eq!(dv.back(), Some(4))
  assert_eq!(dv.pop_front(), Some(1))
  assert_eq!(dv.length(), 3)
  assert_eq!(dv.front(), Some(2))
  dv.push_front(5)
  dv.push_front(6)
  dv.push_back(7)
  dv.push_back(8)
  assert_eq!(dv.length(), 7)
  assert_eq!(dv.pop_front(), Some(6))
  assert_eq!(dv.front(), Some(5))
  assert_eq!(dv.length(), 6)
  assert_eq!(dv.pop_back(), Some(8))
  assert_eq!(dv.back(), Some(7))
  let dv = @deque.of([1])
  assert_eq!(dv.pop_front(), Some(1))
  assert_eq!(dv.pop_front(), None)
  assert_eq!(dv.pop_back(), None)
}

test "is_empty" {
  let dv = @deque.new()
  assert_true!(dv.is_empty())
  dv.push_back(3)
  assert_false!(dv.is_empty())
}

test "of" {
  let d = @deque.of([1, 2, 3])
  assert_eq!(d[0], 1)
  assert_eq!(d[1], 2)
  assert_eq!(d[2], 3)
}

test "front_and_back" {
  let dv = @deque.of([1, 2, 3, 4, 5])
  assert_eq!(dv.back(), Some(5))
  assert_eq!(dv.front(), Some(1))
  let dv : @deque.T[Int] = @deque.new()
  assert_eq!(dv.back(), None)
  assert_eq!(dv.front(), None)
}

test "new_with_capacity" {
  let d : @deque.T[Int] = @deque.new(capacity=0)
  assert_eq!(d.capacity(), 0)
}

test "new_with_capacity_non_zero" {
  let d : @deque.T[Int] = @deque.new(capacity=10)
  assert_eq!(d.capacity(), 10)
}

test "realloc" {
  let dv = @deque.of([1, 2, 3, 4, 5])
  assert_eq!(dv.pop_front(), Some(1))
  assert_eq!(dv.pop_front(), Some(2))
  assert_eq!(dv.pop_front(), Some(3))
  dv.push_back(6)
  dv.push_back(7)
  dv.push_back(8)
  dv.push_back(9)
  dv.push_back(10)
  let result = Array::make(7, 0)
  let mut i = 0
  dv.each(fn(x) {
    result[i] = x
    i += 1
  })
  assert_eq!(result, [4, 5, 6, 7, 8, 9, 10])
}

test "push_realloc" {
  let dv = @deque.new()
  dv.push_front(1)
  assert_eq!(dv.pop_front(), Some(1))
  assert_true!(dv.capacity() > 0)
  let dv = @deque.new()
  dv.push_back(1)
  assert_eq!(dv.pop_back(), Some(1))
  assert_true!(dv.capacity() > 0)
}

test "reserve_and_push" {
  // capacity > 0, len = 0
  let a = @deque.new(capacity=2)
  a.push_back(Some(1))
  inspect!(a.front(), content="Some(Some(1))")
  inspect!(a.back(), content="Some(Some(1))")
  // capacity = 0, len = 0
  let b = @deque.new(capacity=0)
  b.push_back(Some(1))
  inspect!(b.front(), content="Some(Some(1))")
  inspect!(b.back(), content="Some(Some(1))")
  // capacity > 0, len = 0
  let c = @deque.new(capacity=2)
  c.push_front(Some(1))
  inspect!(c.front(), content="Some(Some(1))")
  inspect!(c.back(), content="Some(Some(1))")
  // capacity = 0, len = 0
  let d = @deque.new(capacity=0)
  d.push_front(Some(1))
  inspect!(d.front(), content="Some(Some(1))")
  inspect!(d.back(), content="Some(Some(1))")
}

test "from_iter multiple elements iter" {
  inspect!(
    @deque.T::from_iter([1, 2, 3].iter()),
    content="@deque.of([1, 2, 3])",
  )
}

test "from_iter single element iter" {
  inspect!(@deque.T::from_iter([1].iter()), content="@deque.of([1])")
}

test "from_iter empty iter" {
  let dq : @deque.T[Int] = @deque.T::from_iter(Iter::empty())
  inspect!(dq, content="@deque.of([])")
}

test "from_array with single element" {
  let arr = [42]
  let deque = @deque.T::from_array(arr)
  assert_eq!(deque.length(), 1)
  assert_eq!(deque.front(), Some(42))
  assert_eq!(deque.back(), Some(42))
}

test "unsafe_pop_front after many push_front" {
  let dq = @deque.new()
  // First fill some elements to create a buffer with some capacity
  for i = 0; i < 10; i = i + 1 {
    dq.push_front(i)
  }
  // Pop all elements except one
  for i = 0; i < 9; i = i + 1 {
    dq.unsafe_pop_front()
  }
  // Now head should be at the end of buffer
  // When we pop again, head should wrap around to 0
  inspect!(dq.front(), content="Some(0)")
  dq.unsafe_pop_front()
  inspect!(dq.is_empty(), content="true")
}

test "unsafe_pop_back when tail needs to wrap around" {
  let dq = @deque.new(capacity=2)
  dq.push_back(1) // tail = 0
  dq.push_back(2) // tail = 1
  dq.unsafe_pop_front() // head = 1
  dq.push_back(3) // tail = 0 (wraps around)
  dq.unsafe_pop_back()
  inspect!(dq.back(), content="Some(2)")
}

test "deque op_set wrapping case" {
  let dq = @deque.new(capacity=4)
  // Add elements until the deque wraps around
  dq.push_back(1) // head=0, tail=0
  dq.push_back(2) // head=0, tail=1
  dq.push_back(3) // head=0, tail=2
  dq.push_back(4) // head=0, tail=3
  dq.push_front(0) // head=3, tail=3

  // Now the deque is [0,1,2,3,4] with head=3, tail=3
  // Setting dq[2] should trigger the uncovered branch
  dq[2] = 10

  // Verify the change
  inspect!(dq, content="@deque.of([0, 10, 2, 3, 4])")
}

test "iter when tail needs to wrap around" {
  let dq = @deque.new(capacity=2)
  dq.push_back(1) // tail = 0
  dq.push_back(2) // tail = 1
  dq.unsafe_pop_front() // head = 1
  dq.push_back(3) // tail = 0 (wraps around)
  inspect!(dq.iter().to_array(), content="[2, 3]")
  inspect!(dq.iter().filter(fn(x) { x % 2 == 0 }).to_array(), content="[2]")
  inspect!(dq.iter().filter(fn(x) { x % 2 != 0 }).to_array(), content="[3]")
}

test "iter2 when tail needs to wrap around" {
  let dq = @deque.new(capacity=2)
  dq.push_back(1) // tail = 0
  dq.push_back(2) // tail = 1
  dq.unsafe_pop_front() // head = 1
  dq.push_back(3) // tail = 0 (wraps around)
  inspect!(dq.iter2().to_array(), content="[(0, 2), (1, 3)]")
}

test "deque push_front when empty" {
  let d = @deque.of([0, 1])
  ignore(d.pop_back())
  guard let Some(f) = d.pop_back()
  d.push_front(f)
  inspect!(d, content="@deque.of([0])")
  let d = @deque.of(["a", "b"])
  inspect!(
    d.pop_back(),
    content=
      #|Some("b")
    ,
  )
  inspect!(
    d.pop_back(),
    content=
      #|Some("a")
    ,
  )
  d.push_front("a")
  inspect!(d, content="@deque.of([\"a\"])")
}

test "deque push_back when empty" {
  let d = @deque.of([0, 1])
  ignore(d.pop_front())
  guard let Some(f) = d.pop_front()
  d.push_back(f)
  inspect!(d, content="@deque.of([1])")
  let d = @deque.of(["a", "b"])
  inspect!(
    d.pop_front(),
    content=
      #|Some("a")
    ,
  )
  inspect!(
    d.pop_front(),
    content=
      #|Some("b")
    ,
  )
  d.push_back("b")
  inspect!(d, content="@deque.of([\"b\"])")
}
