# Immutable List

List is implemented as a **linked list**, supporting O(1) head access.
- Moonbit list is **homogeneous** list, which means all elements in the list must be of the same type.
- Moonbit list does not support random access well, you can only access elements by iterating through the list. If you need randomly access the nth element, you should use `Array` instead.

# Usage

## Building lists 

You can create a list manually via the `default()` or construct it using the `of()` method: 
```moonbit
test {
    let list0 : @list.T[Int] = @list.default()
    assert_eq!(list0.length(), 0)
    let list1 = @list.of([1, 2, 3, 4, 5])
    assert_eq!(list1.length(), 5)
}
```

Or use `Cons` constructor directly (Adds a single element to the beginning of a list):
```moonbit
test {
    let list = @list.Cons(1, Cons(2, Cons(3, Nil)))
    assert_eq!(list.to_array(), [1, 2, 3])
}
```

Build a repeated list by using the `repeat()` method:
```moonbit
test {
    assert_eq!(@list.repeat(3, 1).to_array(), [1, 1, 1])
}
```

## Pattern matching
You can use pattern matching to destructure a list:
```moonbit
test {
    let list = @list.of([1, 2, 3, 4, 5])
    let arr = []
    match list {
        Cons(head, _tail) => arr.push(head)
        Nil => println("Empty list")
    }
    assert_eq!(arr, [1])
}
```

## Iterating over a list
The standard library provides a lot of tools for iterating over a list, such as `each()`, `eachi()`, etc. (For details check the API documentation)
```moonbit
test {
    let list = @list.of([1, 2, 3, 4, 5])
    let arr = []
    list.each(fn (ele) { arr.push(ele) }) 
    assert_eq!(arr, [1, 2, 3, 4, 5])
}
```

## Appending / Joining lists
To simply concatenate two lists, you can use the `concat()` method (or `+` operator):
```moonbit
test {
    let list1 = @list.of([1, 2, 3])
    let list2 = @list.of([4, 5, 6])
    let list3 = list1.concat(list2)
    let list4 = list1 + list2
    assert_eq!(list3.to_array(), [1, 2, 3, 4, 5, 6])
    assert_eq!(list4.to_array(), [1, 2, 3, 4, 5, 6])
}
```

For concatenating multiple lists (especially the length is unknown), you can use the `flatten()` method:
```moonbit
test {
    let ls1 = @list.of([1, 2, 3])
    let ls2 = @list.of([4, 5, 6])
    let ls3 = @list.of([7, 8, 9])
    let ls4 = @list.of([ls1, ls2, ls3])
    assert_eq!(ls4.flatten().to_array(), [1, 2, 3, 4, 5, 6, 7, 8, 9])
}
```

To insert separate elements into a list, you can use the `intersperse()` method:

```moonbit
test {
    let list = @list.of([1, 2, 3])
    assert_eq!(list.intersperse(0).to_array(), [1, 0, 2, 0, 3])
}
```

## Filtering / Rejecting / Selecting elements
There are three ways to filter / reject / select multiple elements from a list:
- Go through the entire list and decide whether the element should be present in the resultant list or not. Use `filter` for this.
- To extract the first (or last) N elements of a list (and N is independent of the contents of the list). Use `take` or `drop` in this case.
- To stop selecting elements (terminate the iteration) as soon as a condition is met, using `take_while` or `drop_while`

```moonbit
test {
    let ls = @list.of([1, 2, 3, 4, 5])
    assert_eq!(ls.filter(fn (ele) { ele % 2 == 0 }).to_array(), [2, 4])
    assert_eq!(ls.take(2).to_array(), [1, 2])
    assert_eq!(ls.drop(2).to_array(), [3, 4, 5])
    assert_eq!(ls.take_while(fn (ele) { ele < 3 }).to_array(), [1, 2])
    assert_eq!(ls.drop_while(fn (ele) { ele < 3 }).to_array(), [3, 4, 5])
}
```

## Accessing elements / sub-lists
You can access the head of the list using the `head()` (O(1)) method. It returns `Some(head)` or `None` if the list is empty.
And access the last element using the `last()` method (O(n)). 

```moonbit
test {
    let list = @list.of([1, 2, 3, 4, 5])
    assert_eq!(list.head(), Some(1))
    assert_eq!(list.last(), Some(5))
}
```

For randomly accessing, you can use the `nth()` method, which returns the nth element in the list (O(n)). 
If the index is out of bounds, it returns `None`.
```moonbit
test {
    let list = @list.of([1, 2, 3, 4, 5])
    assert_eq!(list.nth(2), Some(3))
    assert_eq!(list.nth(8), None)
}
```

To get a sub-list from the list, you can use the `init_()` method for getting all elements except the last one, and `tail()` for getting all elements except the first one.
```moonbit
test {
    let list = @list.of([1, 2, 3, 4, 5])
    assert_eq!(list.init_().to_array(), [1, 2, 3, 4])
    assert_eq!(list.tail().to_array(), [2, 3, 4, 5])
}
```

## Reducing Lists
You can reduce (fold) a list to a single value using the `fold()` method.
```moonbit
test {
  let list = @list.of([1, 2, 3, 4, 5])
  assert_eq!(list.fold(init=0, fn(acc, x) { acc + x }), 15)
}
```

There are some special folds that you can use like `any`, `all`, `sum`, `maximum`, and `minimum`. Check the API documentation below for more details.

## List transformations
To transform list elements, you can use the `map()` method.
```moonbit
test {
  let list = @list.of([1, 2, 3, 4, 5])
  assert_eq!(list.map(fn (ele) { ele * 2 }).to_array(), [2, 4, 6, 8, 10])
}
```

The `rev` method reverses the list.
```moonbit
test {
  let list = @list.of([1, 2, 3, 4, 5])
  assert_eq!(list.rev().to_array(), [5, 4, 3, 2, 1])
}
```