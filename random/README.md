# Moonbit/Core Random

## Overview

This is an efficient random number generation function based on the [Lagged Fibonacci Generator](https://www.wikiwand.com/en/Lagged_Fibonacci_generator) and standard lib of OCaml, which supports generating pseudo-random numbers of type Int, Int64 and Double.

## Usage

### Create State

You can create a RandomState using the following method, which will be bound to an Int type seed. Of course, you can also use the default seed 1.

```moonbit
let rng1 = init_state(seed=37)
let rng2 = init_state() // seed=0
```

### Generate random numbers

You can use the following methods to obtain random numbers from State, and the results obtained each time will be different.
For integer types, they generate positive numbers within the corresponding type range, while Double is within the interval of (0,1).

```moonbit
let rng = init_state()
rng.gen_int()
rng.gen_int64()
rng.gen_double()
```