# Implementation and Working Principles of Patience Diff

Patience Diff was first proposed by Bram Cohen. It is essentially a heuristic
text-partitioning strategy that can cooperate with other diff algorithms. Its
core idea is as follows:

- For the text blocks `old` and `new`, first count the occurrences of each
  line, then use the lines whose contents appear exactly once in `old` and
  exactly once in `new` as candidate anchors.

Suppose `old` looks like this:

```
1| Ruby: ruby-lang.org
2| #
3| Python: python.org
4| #
5| MoonBit: www.moonbitlang.com
6| #
7| Perl: use.perl.org
```

In this example, within `old`, `#` appears more than once, so it is not unique
on the `old` side. The other four lines are unique in `old`, and they can
serve as anchors only if they also appear exactly once in `new`.

- Then, among the lines that are unique on both sides, select those that
  appear in both blocks to form a candidate anchor sequence.

Suppose `new` looks like this:

```
1| Python: python.org
2| #
3| MoonBit: www.moonbitlang.com
4| #
5| Javascript: tc39.es
6| #
7| Ruby: ruby-lang.org
```

Then the candidate anchor sequence is:

```
"Ruby: ruby-lang.org": old index = 1, new index = 7
"Python: python.org": old index = 3, new index = 1
"MoonBit: www.moonbitlang.com": old index = 5, new index = 3
```

The candidate anchor sequence must ensure that one column of `index` values is
ordered. Here we arrange it from top to bottom in ascending order of `old
index`.

- Next, within this candidate sequence, search for the longest increasing
  subsequence by `new index`. Once this is done, the indices on both sides are
  in ascending order.

The sequence found from the candidate anchor sequence above is:

```
"Python: python.org": old index = 3, new index = 1
"MoonBit: www.moonbitlang.com": old index = 5, new index = 3
```

- Finally, split the two text blocks according to the anchors, and apply a
  basic diff algorithm to the resulting subranges.

There is another approach commonly described online: apply patience again to
each subrange until no suitable anchors can be found. This was the first
version of Patience proposed by Bram Cohen. In a later blog post, he argued
that in practical use, a single split did not appear significantly worse than
recursive splitting, while being simpler, so this document still uses the
single-split approach.

Its basic principle is this simple. In many real code edits, this heuristic
works well.

Its implementation is basically just the process above. The only relatively
complicated part is finding the longest increasing subsequence, which uses an
algorithm called `Patience sort` (also the origin of the name Patience diff).

## Patience Sort

The name `Patience Sort` is said to come from a solitaire card game called
`Patience`. At the start of the game there is a shuffled deck of cards
(corresponding to an unordered `new index` list). By dealing the cards one by
one into a series of piles on the table according to a few rules, the longest
increasing subsequence can be found.

Below, we use an array containing the numbers 1 through 13 as an example. Each
number appears only once, because they are all filtered candidate anchors.

```
5   9   4   6   12   8   7   1   10   11   3   2   13
```

First, take out `5`. Since the table is currently empty, create a new pile to
hold it.

```
9   4   6   12   8   7   1   10   11   3   2   13
-------------------------------------------------


5
```

Next, take out `9`. Since `9` is greater than `5`, it cannot be placed on top
of `5`, so it can only go to the right of `5`, forming a new pile. This time,
unlike the first step, we need to record some extra information. The last
number `9` compares against is `5`, so we create a *back pointer* from `9` to
`5`.

```
4   6   12   8   7   1   10   11   3   2   13       9 -> 5
---------------------------------------------


5   9
```

Next, take out `4`. Since `4` is smaller than `5`, place it directly on top of
`5` without recording a back pointer.

```
6   12   8   7   1   10   11   3   2   13      9 -> 5
-----------------------------------------


4
5   9
```

The following steps work in the same way. Take out `6`: `6` is greater than
`4` but smaller than `9`, so place it on top of `9` and record a back pointer
from `6` to `4`.

```
12   8   7   1   10   11   3   2   13      9 -> 5
-------------------------------------      6 -> 4


4   6
5   9
```

By repeating this process, we eventually get the following piles and back
pointer records:

```
  9   ->  5
  6   ->  4
  12  ->  6
  8   ->  6
  7   ->  6
  10  ->  7
  11  ->  10
  3   ->  1
  2   ->  1
  13  ->  11

    2
1   3    7
4   6    8
5   9   12   10   11   13
```

Finally, start from `13`, the top card of the rightmost pile, and follow the
back pointers: `13 -> 11 -> 10 -> 7 -> 6 -> 4`. Reverse this sequence to get
one longest increasing subsequence.

When translating this process into code, there is one optimization that can be
made: because the top elements of these piles are ordered, once the number of
piles becomes large, binary search can be used to find the final position for a
new card.
