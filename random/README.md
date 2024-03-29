# Moonbit/Core Random

## Overview

This is an efficient random number generation function based on the (MT19937 algorithm)[https://en.wikipedia.org/wiki/Mersenne_Twister], which supports generating pseudo-random numbers of type Int, Int64 and Double.

## Usage

### Create Summoner

We have three summoners, RandInt, RandInt64, and RandDouble, and you can construct them using seeds of type Int.

```moonbit
let summoner_int = RandomInt::new(114514)
let summoner_int64 = RandomInt64::new(114514)
let summoner_double = RandomDouble::new(114514)
```

### Generate random numbers

You can use the summon method of each summoner to generate random numbers, RandInt and RandInt64 both create positive integers in their range, while RandDouble generates floating-point numbers in the range [0,1].

```moonbit
let summoner_int = RandomInt::new(114514)
let summoner_int64 = RandomInt64::new(114514)
let summoner_double = RandomDouble::new(114514)

summoner_int.summon()
summoner_int64.summon()
summoner_double.summon()
```
