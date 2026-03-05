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
fn print_edits(
  cutoff? : Int,
  old : MutArrayView[String],
  new : MutArrayView[String],
) -> String {
  let mut prev_old_idx = 0
  let mut prev_new_idx = 0
  let result = Array::new(capacity=old.length() + new.length())
  let callback = fn(old_idx, new_idx) {
    for i in prev_old_idx..<old_idx {
      result.push("-  " + old[i])
    }
    for i in prev_new_idx..<new_idx {
      result.push("+  " + new[i])
    }
    result.push("   \{old[old_idx]}")
    prev_old_idx = old_idx + 1
    prev_new_idx = new_idx + 1
  }
  for old_idx, new_idx in iter_matches(cutoff~, old~, new~) {
    callback(old_idx, new_idx)
  }
  for i in prev_old_idx..<old.length() {
    result.push("-  " + old[i])
  }
  for i in prev_new_idx..<new.length() {
    result.push("+  " + new[i])
  }
  return result.join("\n")
}

///|
test {
  let old = ['a', 'b', 'c', 'd', 'e'].map(x => String::make(3, x))
  let new = ['a', 'x', 'c', 'y', 'e', 'z'].map(x => String::make(3, x))
  inspect(
    print_edits(old.mut_view(), new.mut_view()),
    content=(
      #|   aaa
      #|-  bbb
      #|+  xxx
      #|   ccc
      #|-  ddd
      #|+  yyy
      #|   eee
      #|+  zzz
    ),
  )
}

///|
test {
  let old = ['a', 'o', 'b', 'c'].map(x => String::make(3, x))
  let new = ['a', 'e', 'b', 'c'].map(x => String::make(3, x))
  inspect(
    print_edits(old.mut_view(), new.mut_view()),
    content=(
      #|   aaa
      #|-  ooo
      #|+  eee
      #|   bbb
      #|   ccc
    ),
  )
}

///|
test "identical arrays" {
  let old = ['a', 'b', 'c', 'd', 'e'].map(x => String::make(3, x))
  let new = ['a', 'b', 'c', 'd', 'e'].map(x => String::make(3, x))
  inspect(
    print_edits(old.mut_view(), new.mut_view()),
    content=(
      #|   aaa
      #|   bbb
      #|   ccc
      #|   ddd
      #|   eee
    ),
  )
}

///|
test "completely different arrays" {
  let old = ['a', 'b', 'c'].map(x => String::make(3, x))
  let new = ['x', 'y', 'z'].map(x => String::make(3, x))
  inspect(
    print_edits(old.mut_view(), new.mut_view()),
    content=(
      #|-  aaa
      #|-  bbb
      #|-  ccc
      #|+  xxx
      #|+  yyy
      #|+  zzz
    ),
  )
}

///|
test "fully insert" {
  let old : Array[String] = []
  let new = ['a', 'b', 'c'].map(x => String::make(3, x))
  inspect(
    print_edits(old.mut_view(), new.mut_view()),
    content=(
      #|+  aaa
      #|+  bbb
      #|+  ccc
    ),
  )
}

///|
test "fully delete" {
  let old = ['a', 'b', 'c'].map(x => String::make(3, x))
  let new : Array[String] = []
  inspect(
    print_edits(old.mut_view(), new.mut_view()),
    content=(
      #|-  aaa
      #|-  bbb
      #|-  ccc
    ),
  )
}

///|
test "insert at beginning" {
  let old = ['b', 'c', 'd'].map(x => String::make(3, x))
  let new = ['a', 'b', 'c', 'd'].map(x => String::make(3, x))
  inspect(
    print_edits(old.mut_view(), new.mut_view()),
    content=(
      #|+  aaa
      #|   bbb
      #|   ccc
      #|   ddd
    ),
  )
}

///|
test "insert at end" {
  let old = ['a', 'b', 'c'].map(x => String::make(3, x))
  let new = ['a', 'b', 'c', 'd'].map(x => String::make(3, x))
  inspect(
    print_edits(old.mut_view(), new.mut_view()),
    content=(
      #|   aaa
      #|   bbb
      #|   ccc
      #|+  ddd
    ),
  )
}

///|
test "delete at beginning" {
  let old = ['a', 'b', 'c', 'd'].map(x => String::make(3, x))
  let new = ['b', 'c', 'd'].map(x => String::make(3, x))
  inspect(
    print_edits(old.mut_view(), new.mut_view()),
    content=(
      #|-  aaa
      #|   bbb
      #|   ccc
      #|   ddd
    ),
  )
}

///|
test "delete at end" {
  let old = ['a', 'b', 'c', 'd'].map(x => String::make(3, x))
  let new = ['a', 'b', 'c'].map(x => String::make(3, x))
  inspect(
    print_edits(old.mut_view(), new.mut_view()),
    content=(
      #|   aaa
      #|   bbb
      #|   ccc
      #|-  ddd
    ),
  )
}

///|
test "insert multiple in middle" {
  let old = ['a', 'b', 'e', 'f'].map(x => String::make(3, x))
  let new = ['a', 'b', 'c', 'd', 'e', 'f'].map(x => String::make(3, x))
  inspect(
    print_edits(old.mut_view(), new.mut_view()),
    content=(
      #|   aaa
      #|   bbb
      #|+  ccc
      #|+  ddd
      #|   eee
      #|   fff
    ),
  )
}

///|
test "delete multiple in middle" {
  let old = ['a', 'b', 'c', 'd', 'e', 'f'].map(x => String::make(3, x))
  let new = ['a', 'b', 'e', 'f'].map(x => String::make(3, x))
  inspect(
    print_edits(old.mut_view(), new.mut_view()),
    content=(
      #|   aaa
      #|   bbb
      #|-  ccc
      #|-  ddd
      #|   eee
      #|   fff
    ),
  )
}

///|
test "arrays with duplicates" {
  let old = ['a', 'b', 'a', 'c'].map(x => String::make(3, x))
  let new = ['a', 'a', 'b', 'c'].map(x => String::make(3, x))
  inspect(
    print_edits(old.mut_view(), new.mut_view()),
    content=(
      #|   aaa
      #|-  bbb
      #|   aaa
      #|+  bbb
      #|   ccc
    ),
  )
}

///|
test "single element arrays" {
  let old = ['a'].map(x => String::make(3, x))
  let new = ['b'].map(x => String::make(3, x))
  inspect(
    print_edits(old.mut_view(), new.mut_view()),
    content=(
      #|-  aaa
      #|+  bbb
    ),
  )
}

///|
test "long sequence LCS" {
  let old = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'].map(x0 => {
    String::make(3, x0)
  })
  let new = ['a', 'x', 'c', 'y', 'e', 'z', 'g', 'w', 'i', 'v'].map(x0 => {
    String::make(3, x0)
  })
  inspect(
    print_edits(old.mut_view(), new.mut_view()),
    content=(
      #|   aaa
      #|-  bbb
      #|+  xxx
      #|   ccc
      #|-  ddd
      #|+  yyy
      #|   eee
      #|-  fff
      #|+  zzz
      #|   ggg
      #|-  hhh
      #|+  www
      #|   iii
      #|-  jjj
      #|+  vvv
    ),
  )
}

///|
test "reverse order" {
  let old = ['a', 'b', 'c', 'd'].map(x => String::make(3, x))
  let new = ['d', 'c', 'b', 'a'].map(x => String::make(3, x))
  inspect(
    print_edits(old.mut_view(), new.mut_view()),
    content=(
      #|-  aaa
      #|-  bbb
      #|-  ccc
      #|   ddd
      #|+  ccc
      #|+  bbb
      #|+  aaa
    ),
  )
}

///|
test "integer arrays diff" {
  let old = [1, 2, 3, 4, 5].mut_view()
  let new = [1, 3, 5, 6, 7].mut_view()
  let result = Array::new()
  for old_idx, new_idx in iter_matches(old~, new~, cutoff=None) {
    result.push((old_idx, new_idx))
  }

  // Should find matching elements: (0,0)=1, (2,1)=3, (4,2)=5
  inspect(result, content="[(0, 0), (2, 1), (4, 2)]")
}

///|
test "many duplicate elements" {
  let old = ['a', 'a', 'a', 'b', 'a', 'a'].map(x => String::make(3, x))
  let new = ['a', 'a', 'b', 'a', 'a', 'a'].map(x => String::make(3, x))
  inspect(
    print_edits(old.mut_view(), new.mut_view()),
    content=(
      #|   aaa
      #|   aaa
      #|-  aaa
      #|   bbb
      #|+  aaa
      #|   aaa
      #|   aaa
    ),
  )
}

///|
test "alternating pattern" {
  let old = ['a', 'b', 'a', 'b', 'a', 'b'].map(x => String::make(3, x))
  let new = ['b', 'a', 'b', 'a', 'b', 'a'].map(x => String::make(3, x))
  inspect(
    print_edits(old.mut_view(), new.mut_view()),
    content=(
      #|-  aaa
      #|   bbb
      #|   aaa
      #|   bbb
      #|   aaa
      #|   bbb
      #|+  aaa
    ),
  )
}

///|
test "nested insertions and deletions" {
  let old = ['a', 'x', 'b', 'y', 'c', 'z', 'd'].map(x => String::make(3, x))
  let new = ['a', 'b', 'c', 'd', 'e'].map(x => String::make(3, x))
  inspect(
    print_edits(old.mut_view(), new.mut_view()),
    content=(
      #|   aaa
      #|-  xxx
      #|   bbb
      #|-  yyy
      #|   ccc
      #|-  zzz
      #|   ddd
      #|+  eee
    ),
  )
}

///|
test "iter_matches callback verification" {
  let old = ['a', 'b', 'c', 'd'].map(x => String::make(3, x)).mut_view()
  let new = ['a', 'x', 'c', 'y'].map(x => String::make(3, x)).mut_view()
  let matches = Array::new()
  let old_indices = Array::new()
  let new_indices = Array::new()
  for old_idx, new_idx in iter_matches(old~, new~, cutoff=None) {
    matches.push((old_idx, new_idx))
    old_indices.push(old_idx)
    new_indices.push(new_idx)
  }

  // Verify that matched elements are indeed equal
  for i = 0; i < matches.length(); i = i + 1 {
    let (old_idx, new_idx) = matches[i]
    inspect(old[old_idx] == new[new_idx], content="true")
  }

  // Verify that indices are increasing
  for i = 1; i < old_indices.length(); i = i + 1 {
    inspect(old_indices[i] > old_indices[i - 1], content="true")
    inspect(new_indices[i] > new_indices[i - 1], content="true")
  }
}

///|
test "string array edge cases" {
  let old = ["", "a", "", "b", ""].mut_view()
  let new = ["", "b", "", "a", ""].mut_view()
  let result = Array::new()
  for old_idx, new_idx in iter_matches(old~, new~, cutoff=None) {
    result.push((old_idx, new_idx))
  }

  // Should find some matches (empty strings will match)
  inspect(result.length() > 0, content="true")
}

///|
test "large array performance" {
  let size = 50
  let old = Array::make(size, 0)
  let new = Array::make(size, 0)

  // Create regular pattern data
  for i = 0; i < size; i = i + 1 {
    old[i] = i
    new[i] = if i % 2 == 0 { i } else { i + 100 } // Half same, half different
  }
  let match_count = @ref.Ref::new(0)
  for
    _old_idx, _new_idx in iter_matches(
      old=old.mut_view(),
      new=new.mut_view(),
      cutoff=None,
    ) {
    match_count.val = match_count.val + 1
  }

  // Should find approximately half matches
  inspect(match_count.val > 10, content="true")
  inspect(match_count.val < 40, content="true")
}

///|
test "single difference" {
  let old = ['a', 'b', 'c', 'd', 'e'].map(x => String::make(3, x))
  let new = ['a', 'b', 'x', 'd', 'e'].map(x => String::make(3, x))
  inspect(
    print_edits(old.mut_view(), new.mut_view()),
    content=(
      #|   aaa
      #|   bbb
      #|-  ccc
      #|+  xxx
      #|   ddd
      #|   eee
    ),
  )
}

///|
test "very short arrays" {
  let old = ['a'].map(x => String::make(3, x))
  let new : Array[String] = []
  inspect(
    print_edits(old.mut_view(), new.mut_view()),
    content=(
      #|-  aaa
    ),
  )
}

///|
test "partial overlap sequence" {
  let old = ['a', 'b', 'c', 'd'].map(x => String::make(3, x))
  let new = ['c', 'd', 'e', 'f'].map(x => String::make(3, x))
  inspect(
    print_edits(old.mut_view(), new.mut_view()),
    content=(
      #|-  aaa
      #|-  bbb
      #|   ccc
      #|   ddd
      #|+  eee
      #|+  fff
    ),
  )
}

///|
test "iter_matches parameter order" {
  let old = ['a', 'b', 'c'].map(x => String::make(3, x)).mut_view()
  let new = ['a', 'x', 'c'].map(x => String::make(3, x)).mut_view()
  let matches = Array::new()
  let all_equal = @ref.Ref::new(true)
  for old_idx, new_idx in iter_matches(old~, new~, cutoff=None) {
    // Verify parameter order: old_idx should correspond to old array, new_idx to new array
    let old_val = old[old_idx]
    let new_val = new[new_idx]
    if old_val != new_val {
      all_equal.val = false
    }
    matches.push("old[\{old_idx}]=\{old_val}, new[\{new_idx}]=\{new_val}")
  }

  // Verify that all matched elements are indeed equal
  assert_true(all_equal.val)
  // Should have matches for 'a' and 'c'
  inspect(matches.length(), content="2")
}

///|
test "repeated subsequence" {
  let old = ['a', 'b', 'a', 'b', 'c'].map(x => String::make(3, x)).mut_view()
  let new = ['a', 'b', 'c', 'a', 'b'].map(x => String::make(3, x)).mut_view()
  let result = Array::new()
  for old_idx, new_idx in iter_matches(old~, new~, cutoff=None) {
    result.push((old_idx, new_idx))
  }

  // Verify that some matches were found
  inspect(result.length() >= 3, content="true")
}

///|
test "diff symmetry test" {
  let arr1 = ['a', 'b', 'c'].map(x => String::make(3, x)).mut_view()
  let arr2 = ['a', 'x', 'c'].map(x => String::make(3, x)).mut_view()

  // Calculate diff from arr1 -> arr2
  let matches1 = Array::new()
  for old_idx, new_idx in iter_matches(old=arr1, new=arr2, cutoff=None) {
    matches1.push((old_idx, new_idx))
  }

  // Calculate diff from arr2 -> arr1
  let matches2 = Array::new()
  for old_idx, new_idx in iter_matches(old=arr2, new=arr1, cutoff=None) {
    matches2.push((old_idx, new_idx))
  }

  // Both directions should have the same number of matches
  assert_eq(matches1.length(), matches2.length())
}

///|
test "diff sub array" {
  let old = [
    "Apple", "Banana", "Orange", "Grape", "Strawberry", "Watermelon", "Peach", "Pear",
    "Pineapple", "Cherry",
  ]
  let new = [
    "Apple", "Banana", "Orange", "Grape", "Strawberry", "Watermelon", "Peach", "Pear",
    "Pineapple", "Cherry",
  ]
  assert_eq(old, new)
  inspect(
    print_edits(old.mut_view(end=4), new.mut_view(end=5)),
    content=(
      #|   Apple
      #|   Banana
      #|   Orange
      #|   Grape
      #|+  Strawberry
    ),
  )
  inspect(
    print_edits(old.mut_view(start=4), new.mut_view(start=5)),
    content=(
      #|-  Strawberry
      #|   Watermelon
      #|   Peach
      #|   Pear
      #|   Pineapple
      #|   Cherry
    ),
  )
}
