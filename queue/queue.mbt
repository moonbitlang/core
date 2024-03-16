struct Cell[T] {
  content : T
  mut next : Option[Cell[T]]
}

pub fn op_equal[T : Eq](self : Cell[T], other : Cell[T]) -> Bool {
  self.content == other.content
}

pub struct Queue[T] {
  mut length : Int
  mut tail : Option[Cell[T]]
}

/// Creates a new empty queue.
/// 
/// # Example
/// ```
/// let queue : Queue[Int] = Queue::create()
/// ```
pub fn Queue::create[T]() -> Queue[T] {
  { length: 0, tail: None }
}

test "create" {
  let queue : Queue[Int] = create()
  @assertion.assert_eq(queue.length, 0)?
  @assertion.assert_true(queue.tail == None)?
}

/// Creates a new queue from an array.
/// 
/// # Example
/// ```
/// let queue : Queue[Int] = Queue::[1, 2, 3, 4]
/// ```
pub fn Queue::from_array[T](array : Array[T]) -> Queue[T] {
  let queue : Queue[T] = create()
  for i = 0; i < array.length(); i = i + 1 {
    queue.add(array[i])
  }
  queue
}

test "from_array" {
  let queue : Queue[Int] = Queue::[1, 2, 3, 4]
  @assertion.assert_eq(queue.length, 4)?
  @assertion.assert_eq(queue.take(), 1)?
  @assertion.assert_eq(queue.take(), 2)?
  @assertion.assert_eq(queue.take(), 3)?
  @assertion.assert_eq(queue.take(), 4)?
  @assertion.assert_eq(queue.length, 0)?
}

/// Creates a new queue from a list.
/// 
/// # Example
/// ```
/// let queue : Queue[Int] = Queue::from_list(Cons(1, Cons(2, Cons(3, Cons(4, Nil))))
/// ```
pub fn Queue::from_list[T](list : List[T]) -> Queue[T] {
  let queue : Queue[T] = create()
  loop list {
    l =>
      match l {
        Cons(head, tail) => {
          queue.add(head)
          continue tail
        }
        Nil => break
      }
  }
  queue
}

test "from_list" {
  let queue : Queue[Int] = Queue::from_list(
    Cons(1, Cons(2, Cons(3, Cons(4, Nil)))),
  )
  @assertion.assert_eq(queue.length, 4)?
  @assertion.assert_eq(queue.take(), 1)?
  @assertion.assert_eq(queue.take(), 2)?
  @assertion.assert_eq(queue.take(), 3)?
  @assertion.assert_eq(queue.take(), 4)?
  @assertion.assert_eq(queue.length, 0)?
}

/// Clears the queue.
/// 
/// # Example
/// ```
/// let queue : Queue[Int] = Queue::[1, 2, 3, 4]
/// queue.clear()
/// ```
pub fn clear[T](self : Queue[T]) {
  self.length = 0
  self.tail = None
}

test "clear" {
  let queue : Queue[Int] = Queue::[1, 2, 3, 4]
  queue.clear()
  @assertion.assert_eq(queue.length, 0)?
  @assertion.assert_true(queue.tail == None)?
}

/// Adds a value to the queue.
/// 
/// # Example
/// ```
/// let queue : Queue[Int] = Queue::create()
/// queue.add(1)
/// ```
pub fn add[T](self : Queue[T], value : T) {
  if self.length == 0 {
    let cell : Cell[T] = { content: value, next: None }
    cell.next = Some(cell)
    self.length = 1
    self.tail = Some(cell)
  } else {
    let tail = self.tail.unwrap()
    let head = tail.next
    let cell = { content: value, next: head }
    self.length = self.length + 1
    tail.next = Some(cell)
    self.tail = Some(cell)
  }
}

test "add" {
  let queue : Queue[Int] = create()
  queue.add(1)
  queue.add(2)
  queue.add(3)
  queue.add(4)
  @assertion.assert_eq(queue.length, 4)?
  @assertion.assert_eq(queue.take(), 1)?
  @assertion.assert_eq(queue.take(), 2)?
  @assertion.assert_eq(queue.take(), 3)?
  @assertion.assert_eq(queue.take(), 4)?
  @assertion.assert_eq(queue.length, 0)?
}

/// Peeks at the first value in the queue.
/// 
/// # Example
/// ```
/// let queue : Queue[Int] = Queue::[1, 2, 3, 4]
/// let first = queue.peek()
/// ```
pub fn peek[T](self : Queue[T]) -> Option[T] {
  let tail = self.tail
  match tail {
    Some(tail) => {
      let head = tail.next
      match head {
        Some(head) => Some(head.content)
        None => None
      }
    }
    None => None
  }
}

test "peek" {
  let queue : Queue[Int] = create()
  @assertion.assert_eq(queue.peek(), None)?
  queue.add(1)
  queue.add(2)
  queue.add(3)
  queue.add(4)
  @assertion.assert_eq(queue.peek(), Some(1))?
  @assertion.assert_eq(queue.take(), 1)?
  @assertion.assert_eq(queue.peek(), Some(2))?
  @assertion.assert_eq(queue.take(), 2)?
  @assertion.assert_eq(queue.peek(), Some(3))?
  @assertion.assert_eq(queue.take(), 3)?
  @assertion.assert_eq(queue.peek(), Some(4))?
  @assertion.assert_eq(queue.take(), 4)?
  @assertion.assert_eq(queue.peek(), None)?
}

/// Returns the length of the queue.
/// 
/// # Example
/// ```
/// let queue : Queue[Int] = Queue::[1, 2, 3, 4]
/// let length = queue.length()
/// ```
pub fn length[T](self : Queue[T]) -> Int {
  self.length
}

test "length" {
  let queue : Queue[Int] = create()
  @assertion.assert_eq(queue.length(), 0)?
  queue.add(1)
  queue.add(2)
  queue.add(3)
  queue.add(4)
  @assertion.assert_eq(queue.length(), 4)?
}

/// Checks if the queue is empty.
/// 
/// # Example
/// ```
/// let queue : Queue[Int] = Queue::create()
/// let is_empty = queue.is_empty()
/// ```
pub fn is_empty[T](self : Queue[T]) -> Bool {
  self.length == 0
}

test "is_empty" {
  let queue : Queue[Int] = create()
  @assertion.assert_true(queue.is_empty())?
  queue.add(1)
  queue.add(2)
  queue.add(3)
  queue.add(4)
  @assertion.assert_false(queue.is_empty())?
}

/// Takes the first value from the queue.
/// 
/// # Example
/// ```
/// let queue : Queue[Int] = Queue::[1, 2, 3, 4]
/// let first = queue.take()
/// ```
pub fn take[T : Eq](self : Queue[T]) -> T {
  if self.length == 0 {
    abort("Queue is empty")
  }
  self.length = self.length - 1
  let tail = self.tail.unwrap()
  let head = tail.next.unwrap()
  if head == tail {
    self.tail = None
  } else {
    tail.next = head.next
  }
  head.content
}

test "take" {
  let queue : Queue[Int] = Queue::[1, 2, 3, 4]
  @assertion.assert_eq(queue.take(), 1)?
  @assertion.assert_eq(queue.take(), 2)?
  @assertion.assert_eq(queue.take(), 3)?
  @assertion.assert_eq(queue.take(), 4)?
  @assertion.assert_eq(queue.length(), 0)?
}

/// Takes the first value from the queue, or returns `None` if the queue is empty.
/// 
/// # Example
/// ```
/// let queue : Queue[Int] = Queue::[1, 2, 3, 4]
/// let first = queue.take_option()
/// ```
pub fn take_option[T : Eq](self : Queue[T]) -> Option[T] {
  if self.length == 0 {
    None
  } else {
    Some(self.take())
  }
}

test "take_option" {
  let queue : Queue[Int] = Queue::[1, 2, 3, 4]
  @assertion.assert_eq(queue.take_option(), Some(1))?
  @assertion.assert_eq(queue.take_option(), Some(2))?
  @assertion.assert_eq(queue.take_option(), Some(3))?
  @assertion.assert_eq(queue.take_option(), Some(4))?
  @assertion.assert_eq(queue.take_option(), None)?
}

/// Iterates over the queue.
/// 
/// # Example
/// ```
/// let queue : Queue[Int] = Queue::[1, 2, 3, 4]
/// queue.iter(fn(x) { print(x) })
/// ```
pub fn iter[T : Eq](self : Queue[T], f : (T) -> Unit) {
  if self.length > 0 {
    let tail = self.tail.unwrap()
    loop tail.next.unwrap() {
      cell => {
        f(cell.content)
        if (cell == tail).not() {
          continue cell.next.unwrap()
        }
      }
    }
  }
}

test "iter" {
  let queue : Queue[Int] = create()
  let mut sum = 0
  queue.iter(fn(x) { sum = sum + x })
  @assertion.assert_eq(sum, 0)?
  queue.add(1)
  queue.add(2)
  queue.add(3)
  queue.add(4)
  sum = 0
  queue.iter(fn(x) { sum = sum + x })
  @assertion.assert_eq(sum, 10)?
}

/// Folds over the queue.
/// 
/// # Example
/// ```
/// let queue : Queue[Int] = Queue::[1, 2, 3, 4]
/// let sum = queue.fold(0, fn(acc, x) { acc + x })
/// ```
pub fn fold[T : Eq](self : Queue[T], init : T, f : (T, T) -> T) -> T {
  if self.length == 0 {
    init
  } else {
    let tail = self.tail.unwrap()
    loop tail.next.unwrap(), init {
      cell, acc => {
        let new_acc = f(acc, cell.content)
        if cell == tail {
          new_acc
        } else {
          continue cell.next.unwrap(),
            new_acc
        }
      }
    }
  }
}

test "fold" {
  let queue : Queue[Int] = create()
  let sum = queue.fold(0, fn(acc, x) { acc + x })
  @assertion.assert_eq(sum, 0)?
  queue.add(1)
  queue.add(2)
  queue.add(3)
  queue.add(4)
  let sum = queue.fold(0, fn(acc, x) { acc + x })
  @assertion.assert_eq(sum, 10)?
}
