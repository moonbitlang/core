///|
pub fn new[A : Compare]() -> T[A] {
  { node: Empty, size: 0 }
}

///|
pub fn is_empty[A](self : T[A]) -> Bool {
  self.size == 0
}

///|
pub fn top[A : Compare](self : T[A]) -> A {
  match self.node {
    Empty => abort("Empty")
    Leaf(a) => a
    Branch(a, ..) => a
  }
}

///|
fn deepth(num : Int) -> Int {
  if num == 0 {
    0
  } else {
    deepth(num >> 1) + 1
  }
}

///|
fn change_element[A : Compare](self : T[A], value : A) -> T[A] {
  match self.node {
    Empty => {node: Empty, size: self.size}
    Leaf(_) => {node: Leaf(value), size: self.size}
    Branch(_, left=l, right=r) => {node: Branch(value, left=l, right=r), size: self.size}
  }
}

///|
pub fn push[A : Compare](self : T[A], value : A) -> T[A] {
  match self.node {
    Empty => { node : Leaf(value), size : 1 }
    Leaf(a) => {
      if a > value {
        { node: Branch(value, left={node: Leaf(a), size: 1}, right={ node: Empty, size: 0 }), size: 2 }
      } else {
        { node: Branch(a, left={node: Leaf(value), size: 1}, right={ node: Empty, size: 0 }), size: 2 }
      }
    }
    Branch(a, left=l, right=r) => {
      if r.size == 0 {
        if a > value {
          {node: Branch(value, left=l, right={node: Leaf(a), size: 1}), size: 3}
        } else {
          {node: Branch(a, left=l, right={node: Leaf(value), size: 1}), size: 3}
        }
      } else {
        let deep = deepth(self.size)
        let full = (1 << (deep - 1)) - 1
        if (l.size == full && r.size == full) || (l.size < full) {
          let temp = {node: Branch(a, left=l.push(value), right=r), size: self.size + 1}
          match temp.node {
            Empty => abort("Empty!")
            Leaf(_) => abort("Leaf!")
            Branch(a, left=l, right=r) => {
              if value < a {
                {node: Branch(value, left=l.change_element(a), right=r), size: temp.size}
              } else {
                temp
              }
            }
          }
        } else {
          let temp = {node: Branch(a, left=l, right=r.push(value)), size: self.size + 1}
          match temp.node {
            Empty => abort("Empty!")
            Leaf(_) => abort("Leaf!")
            Branch(a, left=l, right=r) => {
              if value < a {
                {node: Branch(value, left=l, right=r.change_element(a)), size: temp.size}
              } else {
                temp
              }
            }
          }
        }
      }
    }
  }
}

///|
fn from_array[A : Compare](array : Array[A]) -> T[A] {
  let mut pq = new()
  for i in 0..<array.length() {
    pq = pq.push(array[i])
  }
  pq
}

///|
fn find_element[A : Compare](self : T[A]) -> A {
  match self.node {
    Empty => abort("Priority queue is empty!")
    Leaf(a) => a
    Branch(_, left=l, right=r) => {
      if r.size == 0 {
        l.top()
      } else {
        let deep = deepth(self.size)
        let full_right = (1 << (deep - 2)) - 1
        if r.size == full_right {
          l.find_element()
        } else {
          r.find_element()
        }
      }
    }
  }
}

///|
fn delet_leaf[A : Compare](self : T[A]) -> T[A] {
  match self.node {
    Empty => abort("Priority queue is empty!")
    Leaf(_) => {node: Empty, size: 0}
    Branch(a, left=l, right=r) => {
      if r.size == 0 {
        {node: Leaf(a), size: 1}
      } else {
        let deep = deepth(self.size)
        let full_right = (1 << (deep - 2)) - 1
        if r.size == full_right {
          {node: Branch(a, left=l.delet_leaf(), right=r), size: self.size - 1}
        } else {
          {node: Branch(a, left=l, right=r.delet_leaf()), size: self.size - 1}
        }
      }
    }
  }
}

///|
fn down[A : Compare](self : T[A], value : A) -> T[A] {
  match self.node {
    Empty => {node: Empty, size: 0}
    Leaf(_) => {node: Leaf(value), size: 1}
    Branch(_, left=l, right=r) => {
      if (r.size == 0 && l.top() >= value) || (value <= l.top() && value <= r.top()) {
        {node: Branch(value, left=l, right=r), size: self.size}
      } else if r.size == 0 && l.top() < value {
        {node: Branch(l.top(), left={node: Leaf(value), size: 1}, right={node: Empty, size: 0}), size: self.size}
      } else if l.top() > r.top() {
        {node: Branch(r.top(), left=l, right=r.down(value)), size: self.size}
      } else {
        {node: Branch(l.top(), left=l.down(value), right=r), size: self.size}
      }
    }
  }
}

///|
pub fn pop[A : Compare](self : T[A]) -> T[A] {
  match self.node {
    Empty => abort("Priority queue is empty!")
    Leaf(_) => {node: Empty, size: 0}
    Branch(a, right=r, ..) => {
      if r.size == 0 {
        {node: Leaf(a), size: 1}
      } else {
        let value = self.find_element()
        let temp = self.delet_leaf()
        temp.change_element(value).down(value)
      }
    }
  }
}

// fn down[A : Compare](self : Node[A], value : A) -> Node[A] {
  // match self {
    // Nil => Nil
    // Cons(_) as node => {
      // if node.left.isempty() && node.right.isempty() {
        // return Cons(content = value, left = Nil, right = Nil)
      // } else if node.right.isempty() {
        // if node.content <= node.left.get_content() {
          // return Cons(content = value, left = Cons(content = node.left.get_content(), left = Nil, right = Nil), right = Nil)
        // } else {
          // return Cons(content = node.left.get_content(), left = Cons(content = node.content, left = Nil, right = Nil), right = Nil)
        // }
      // } else {
        // if node.content < node.right.get_content() && node.content < node.left.get_content() {
          // return Cons(content = value, left = node.left, right = node.right)
        // } else {
          // if node.right.get_content() > node.left.get_content() {
            // Cons(content = node.left.get_content(), left = down(node.left, value), right = node.right)
          // } else {
            // Cons(content = node.right.get_content(), left = node.left, right = down(node.right, value))
          // }
        // }
      // }
    // }
  // }
// }
// pub fn pop[A : Compare](self : T[A]) -> Unit {
  // let len = self.size
  // let deep = deepth(len)
  // if len == 1 {
    // self.clear()
    // return
  // }
  // self.root = match self.root {
    // Nil => Nil
    // Cons(_) as node => {
      // let temp = node.find_element(len, deep)
      // Cons(content = temp, left = node.left, right = node.right)
    // }
  // }
  // self.size -= 1
  // let temp = self.root.down(self.root.get_content())
  // self.root = temp
// }
// 


///|
fn show[A : Show + Compare](self : T[A]) -> Unit {
  match self.node {
    Empty => return
    Leaf(a) => {
      println("------")
      println(a)
      println("------")
    }
    Branch(a, left=l, right=r) => {
      println("------")
      println(a)
      if l.size == 0 {
        println("l.empty")
        println(r.top())
      } else if r.size == 0 {
        println(l.top())
        println("r.empty")
      } else {
        println(l.top())
        println(r.top())
      }
      println("------")
      l.show()
      r.show()
    }
  }  
}

///|
test "push" {
  let pq = [8, 7, 6, 5, 4, 3, 2, 1]
  let pq_test = from_array(pq)
  //inspect!(pq_test.show(), content = "()")
  let pq_new = pq_test.pop()
  inspect!(pq_new.show(), content = "()")
  let pq1 = pq_new.pop()
  inspect!(pq1.show(),content = "()")
}
