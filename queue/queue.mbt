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

pub fn create[T]() -> Queue[T] {
  { length: 0, tail: None }
}

pub fn clear[T](self : Queue[T]) {
  self.length = 0
  self.tail = None
}

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

pub fn length[T](self : Queue[T]) -> Int {
  self.length
}

pub fn is_empty[T](self : Queue[T]) -> Bool {
  self.length == 0
}

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

pub fn take_option[T : Eq](self : Queue[T]) -> Option[T] {
  if self.length == 0 {
    None
  } else {
    Some(self.take())
  }
}

pub fn iter[T : Eq](self : Queue[T], f : (T) -> Unit) {
  if self.length > 0 {
    let tail = self.tail.unwrap()
    fn helper(cell : Cell[T]) {
      f(cell.content)
      if (cell == tail).not() {
        helper(cell.next.unwrap())
      }
    }

    helper(tail.next.unwrap())
  }
}

pub fn fold[T : Eq](self : Queue[T], init : T, f : (T, T) -> T) -> T {
  if self.length == 0 {
    init
  } else {
    let tail = self.tail.unwrap()
    fn helper(cell : Cell[T], acc : T) -> T {
      let new_acc = f(acc, cell.content)
      if cell == tail {
        new_acc
      } else {
        helper(cell.next.unwrap(), new_acc)
      }
    }
    helper(tail.next.unwrap(), init)
  }
}

