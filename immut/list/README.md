# Immutable List

List is implemented as a **linked list**, supporting O(1) head access.
- Moonbit list is **homogeneous** list, which means all elements in the list must be of the same type.
- Moonbit list does not support random access well, you can only access elements by iterating through the list. If you need randomly access the nth element, you should use `Array` instead.

# Usage

## Building lists 

You can create a list manually via the `new()` or construct it using the `of()` method: 
```moonbit
let list0 : @immut/list.T[Int] = @immut/list.new()
let list1 = @immut/list.of([1, 2, 3, 4, 5])
```

Or use `Cons` constructor directly (Adds a single element to the beginning of a list):
```moonbit
let list = @immut/list.Cons(1, Cons(2, Cons(3, Nil)))
```

Build a repeated list by using the `repeat()` method:
```moonbit
println(@immut/list.repeat(3, 1)) // of([1, 1, 1])
```

## Pattern matching
You can use pattern matching to destructure a list:
```moonbit
let list = @immut/list.of([1, 2, 3, 4, 5])
match list {
    Cons(head, tail) => println(head)
    Nil => println("Empty list")
}
```

## Iterating over a list
The standard library provides a lot of tools for iterating over a list, such as `each()`, `eachi()`, etc. (For details check the API documentation)
```moonbit
let list = @immut.list.of([1, 2, 3, 4, 5])
let list1 = list.each(fn (ele) { println(ele) }) 
```

## Appending / Joining lists
To simply concatenate two lists, you can use the `concat()` method (or `+` operator):
```moonbit
let list1 = @immut/list.of([1, 2, 3])
let list2 = @immut/list.of([4, 5, 6])
let list3 = list1.concat(list2) // of([1, 2, 3, 4, 5, 6])
let list4 = list1 + list2 // of([1, 2, 3, 4, 5, 6])
```

For concatenating multiple lists (especially the length is unknown), you can use the `flatten()` method:
```moonbit
let ls1 = @immut/list.of([1, 2, 3])
let ls2 = @immut/list.of([4, 5, 6])
let ls3 = @immut/list.of([7, 8, 9])
let ls4 = @immut/list.of([ls1, ls2, ls3])
println(ls4.flatten()) // of([1, 2, 3, 4, 5, 6, 7, 8, 9])
```

To insert separate elements into a list, you can use the `intersperse()` method:

```moonbit
let list = @immut/list.of([1, 2, 3])
println(list.intersperse(0)) // of([1, 0, 2, 0, 3])
```

## Filtering / Rejecting / Selecting elements
There are three ways to filter / reject / select multiple elements from a list:
- Go through the entire list and decide whether the element should be present in the resultant list or not. Use `filter` for this.
- To extract the first (or last) N elements of a list (and N is independent of the contents of the list). Use `take` or `drop` in this case.
- To stop selecting elements (terminate the iteration) as soon as a condition is met, using `take_while` or `drop_while`

```moonbit
let ls = @immut/list.of([1, 2, 3, 4, 5])
ls.filter(fn (ele) { ele % 2 == 0 }) // of([2, 4])
ls.take(2) // of([1, 2])
ls.drop(2) // of([3, 4, 5])
ls.take_while(fn (ele) { ele < 3 }) // of([1, 2])
ls.drop_while(fn (ele) { ele < 3 }) // of([3, 4, 5])
```

## Accessing elements / sub-lists
You can access the head of the list using the `head()` (O(1)) method. It returns `Some(head)` or `None` if the list is empty.
And access the last element using the `last()` method (O(n)). 

```moonbit
let list = @immut/list.of([1, 2, 3, 4, 5])
println(list.head()) // Some(1)
println(list.last()) // 5
```

For randomly accessing, you can use the `nth()` method, which returns the nth element in the list (O(n)). 
If the index is out of bounds, it returns `None`.
```moonbit
let list = @immut/list.of([1, 2, 3, 4, 5])
list.nth(2) // Some(3)
list.nth(8) // None
```

To get a sub-list from the list, you can use the `init_()` method for getting all elements except the last one, and `tail()` for getting all elements except the first one.
```moonbit
let list = @immut/list.of([1, 2, 3, 4, 5])
list.init_() // of([1, 2, 3, 4])
list.tail() // of([2, 3, 4, 5])
```

## Reducing Lists
You can reduce (fold) a list to a single value using the `fold()` method.
```moonbit
let list = @immut/list.of([1, 2, 3, 4, 5])
list.fold(init=0, fn(acc, x) { acc + x }) // 15
```

There are some special folds that you can use like `any`, `all`, `sum`, `maximum`, and `minimum`. Check the API documentation below for more details.

## List transformations
To transform list elements, you can use the `map()` method.
```moonbit
let list = @immut/list.of([1, 2, 3, 4, 5])
list.map(fn (ele) { ele * 2 }) // of([2, 4, 6, 8, 10])
```

The `rev` method reverses the list.
```moonbit
let list = @immut/list.of([1, 2, 3, 4, 5])
list.rev() // of([5, 4, 3, 2, 1])
```