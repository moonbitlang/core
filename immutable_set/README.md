# Moonbit/Core ImmutableSet

## Overview

ImmutableSet is an immutable, persistent implementation of the set structure (each operation returns a new ImmutableSet), implemented here using a balance tree.

## Usage

### Create

Since set is based on comparison, the type used to construct ImmutableSet needs to implement Compare trait.

You can create an empty ImmutableSet with a value separately through the following methods, or create it directly from the Array and List.

```moonbit
let set1 : ImmutableSet[Int] = ImmutableSet::new()
let set2 = ImmutableSet::from_value(1)
let set3 = ImmutableSet.from_list(Cons(1, Nil))
let set4 = ImmutableSet.from_array([1])
let set45= ImmutableSet::[1]
```

### Convert

Instead, you can convert an ImmutableSet to a List, which will be sorted.

```moonbit
let set = ImmutableSet::[3, 2, 1]
println(set.to_list()); // List::[1, 2, 3]
```