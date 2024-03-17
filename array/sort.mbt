struct ArraySlice[T] {
  array : Array[T]
  start : Int
  end : Int
}

fn length[T](self : ArraySlice[T]) -> Int {
  self.end - self.start
}

fn op_get[T](self : ArraySlice[T], index : Int) -> T {
  self.array[self.start + index]
}

fn op_set[T](self : ArraySlice[T], index : Int, value : T) {
  self.array[self.start + index] = value
}

fn swap[T](self : ArraySlice[T], a : Int, b : Int) {
  self.array.swap(self.start + a, self.start + b)
}

fn reverse[T](self : ArraySlice[T]) {
  let mid_len = self.length() / 2
  for i = 0; i < mid_len; i = i + 1 {
    let j = self.length() - i - 1
    self.swap(i, j)
  }
}

fn slice[T](self : ArraySlice[T], start : Int, end : Int) -> ArraySlice[T] {
  { array: self.array, start: self.start + start, end: self.start + end }
}

/// Sorts the array in place.
/// 
/// It's an unstable sort. 
/// 
/// # Example
/// 
/// ```
/// let arr = [5, 4, 3, 2, 1]
/// arr.sort()
/// debug(arr) //output: [1, 2, 3, 4, 5]
/// ```
pub fn sort[T : Compare](self : Array[T]) {
  quick_sort({ array: self, start: 0, end: self.length() }, T::compare)
}

/// Sorts the array with a key extraction function.
/// 
/// It's an unstable sort. 
/// 
/// # Example
/// 
/// ```
/// let arr = [5, 3, 2, 4, 1]
/// arr.sort_by_key(fn (x) {-x})
/// debug(arr) //output: [5, 4, 3, 2, 1]
/// ```
pub fn sort_by_key[T, K : Compare](self : Array[T], map : (T) -> K) {
  quick_sort(
    { array: self, start: 0, end: self.length() },
    fn(a, b) { map(a).compare(map(b)) },
  )
}

/// Sorts the array with a custom comparison function.
/// 
/// It's an unstable sort.
/// 
/// # Example
/// 
/// ```
/// let arr = [5, 3, 2, 4, 1]
/// arr.sort_by(fn (a, b) { a - b })
/// debug(arr) //output: [1, 2, 3, 4, 5]
/// ```
pub fn sort_by[T](self : Array[T], cmp : (T, T) -> Int) {
  quick_sort({ array: self, start: 0, end: self.length() }, cmp)
}

fn quick_sort[T](arr : ArraySlice[T], cmp : (T, T) -> Int) {
  let stack : List[ArraySlice[T]] = Cons(arr, Nil)
  loop stack {
    Cons(arr, rest) => {
      if arr.length() <= 1 {
        continue rest
      }
      if arr.length() == 2 {
        if cmp(arr[0], arr[1]) > 0 {
          arr.swap(0, 1)
        }
        continue rest
      }
      let (pivot_index, likely_sorted) = choose_pivot(arr, cmp)
      if likely_sorted {
        if try_bubble_sort(arr, cmp) {
          continue rest
        }
      }
      let pivot = partition(arr, cmp, pivot_index)
      let mut rest = rest
      rest = Cons(arr.slice(0, pivot), rest)
      rest = Cons(arr.slice(pivot + 1, arr.length()), rest)
      continue rest
    }
    Nil => break
  }
}

/// Try to sort the array with bubble sort.
/// 
/// It will only tolerate at most 8 unsorted elements. The time complexity is O(n).
/// 
/// Returns whether the array is sorted.
fn try_bubble_sort[T](arr : ArraySlice[T], cmp : (T, T) -> Int) -> Bool {
  let max_tries = 8
  let mut tries = 0
  for i = 1; i < arr.length(); i = i + 1 {
    let mut j = i
    let mut sorted = true
    while j > 0 && cmp(arr[j - 1], arr[j]) > 0 {
      sorted = false
      arr.swap(j, j - 1)
      j = j - 1
    }
    if not(sorted) {
      tries += 1
      if tries > max_tries {
        return false
      }
    }
  }
  true
}

test "try_bubble_sort" {
  let arr = [8, 7, 6, 5, 4, 3, 2, 1]
  let sorted = try_bubble_sort(
    { array: arr, start: 0, end: 8 },
    fn(a, b) { a - b },
  )
  @assertion.assert_eq(sorted, true)?
  @assertion.assert_eq(arr, [1, 2, 3, 4, 5, 6, 7, 8])?
}

fn partition[T](
  arr : ArraySlice[T],
  cmp : (T, T) -> Int,
  pivot_index : Int
) -> Int {
  arr.swap(pivot_index, arr.length() - 1)
  let pivot = arr[arr.length() - 1]
  let mut i = 0
  for j = 0; j < arr.length() - 1; j = j + 1 {
    if cmp(arr[j], pivot) < 0 {
      arr.swap(i, j)
      i = i + 1
    }
  }
  arr.swap(i, arr.length() - 1)
  i
}

/// Choose a pivot index for quick sort.
/// 
/// It avoids worst case performance by choosing a pivot that is likely to be close to the median.
/// 
/// Returns the pivot index and whether the array is likely sorted.
fn choose_pivot[T](arr : ArraySlice[T], cmp : (T, T) -> Int) -> (Int, Bool) {
  let len = arr.length()
  let use_median_of_medians = 50
  let max_swaps = 4 * 3
  let mut swaps = 0
  let b = len / 4 * 2
  if len >= 8 {
    let a = len / 4 * 1
    let c = len / 4 * 3
    fn sort_2(a : Int, b : Int) {
      if cmp(arr[a], arr[b]) > 0 {
        arr.swap(a, b)
        swaps += 1
      }
    }

    fn sort_3(a : Int, b : Int, c : Int) {
      sort_2(a, b)
      sort_2(b, c)
      sort_2(a, b)
    }

    if len > use_median_of_medians {
      sort_3(a - 1, a, a + 1)
      sort_3(b - 1, b, b + 1)
      sort_3(c - 1, c, c + 1)
    }
    sort_3(a, b, c)
  }
  if swaps == max_swaps {
    arr.reverse()
    (len - b - 1, true)
  } else {
    (b, swaps == 0)
  }
}

test "sort" {
  let arr = [5, 4, 3, 2, 1]
  arr.sort()
  @assertion.assert_eq(arr, [1, 2, 3, 4, 5])?
  let arr = [5, 3, 4, 2, 1]
  arr.sort()
  @assertion.assert_eq(arr, [1, 2, 3, 4, 5])?
}

test "sort_by" {
  let arr = [5, 1, 3, 4, 2]
  arr.sort_by_key(fn(x) { -x })
  @assertion.assert_eq(arr, [5, 4, 3, 2, 1])?
}
