pub fn new[A : Compare]() -> T[A] {
  { root: Nil, size: 0 }
}

pub fn is_empty[A](self : T[A]) -> Bool {
  self.size == 0
}

fn copy_node[A](node : Node[A]) -> Node[A] {
  match node {
    Nil => Nil
    Cons(_) as node => Cons(
      content = node.content,
      left = copy_node(node.left),
      right = copy_node(node.right),
    )
  }
}

pub fn copy[A](self : T[A]) -> T[A] {
  let new_pq : T[A] = { root: copy_node(self.root), size : self.size }
  new_pq
}

pub fn length[A](self : T[A]) -> Int {
  self.size
}

pub fn peek[A : Compare](self : T[A]) -> A? {
  match self.root {
    Nil => abort("Priority queue is empty")
    Cons(_) as node => Some(node.content)
  }
}

fn insert_element[A : Compare](self : Node[A], len : Int, deepth : Int, value : A) -> Node[A] {
  match self {
    Nil => Cons(content = value, left = Nil, right = Nil)
    Cons(_) as node => {
      if deepth == 1 {
        if len == 1 {
          let temp = Cons(content = node.content, left = insert_element(node.left, 0, 0, value), right = Nil)
          if value < node.content {
            return Cons(content = value, left = Cons(content = node.content, left = Nil, right = Nil), right = Nil)
          } else {
            return temp
          }
        }
        if len == 2 {
          let temp = Cons(content = node.content, left = node.left, right = insert_element(node.right, 0, 0, value))
          if value < node.content {
            return Cons(content = value, left = node.left, right = Cons(content = node.content, left = Nil, right = Nil))
          } else {
            return temp
          }
        }
      }
      let left_full = (1 << (deepth - 1)) - 1
      let right_full = (1 << (deepth - 2)) - 1
      if left_full + right_full + 1 <= len {
        let temp= Cons(content = node.content, left = node.left, right = insert_element(node.right, len - left_full - 1, deepth - 1, value))
        if value < node.content {
          return Cons(content = value, left = Cons(content = node.content, left = node.left, right = node.right), right = temp)
        } else {
          return temp
        }
      } else {
        let temp = Cons(content = node.content, left = insert_element(node.left, len - right_full - 1, deepth - 1, value), right = node.right)
        if value < node.content {
          return Cons(content = value, left = Cons(content = node.content, left = node.left, right = node.right), right = temp)
        } else {
          return temp
        }
      }
    }
  }
}

fn deepth(num : Int) -> Int {
  if num == 0 {
    0
  } else {
    deepth(num >> 1) + 1
  }
}

pub fn insert[A : Compare](self : T[A], content : A) -> Unit {
  let len = self.size
  let deep = deepth(len)
  self.root = insert_element(self.root, len, deep, content)
  self.size = len + 1
}

test "insert" {
  let pq: T[Int] = new()
  pq.insert(1)
  assert_eq!(pq.peek(), Some(1))
  pq.insert(8)
  assert_eq!(pq.peek(), Some(1))
  pq.insert(3)
  assert_eq!(pq.peek(), Some(1))
  pq.insert(5)
  assert_eq!(pq.peek(), Some(1))
  pq.insert(1)
  assert_eq!(pq.peek(), Some(1))
  pq.insert(0)
  assert_eq!(pq.peek(), Some(0))
  pq.insert(6)
  assert_eq!(pq.peek(), Some(0))
}