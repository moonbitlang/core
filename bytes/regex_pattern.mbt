// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
#internal(internal, "not intended for public use")
#doc(hidden)
struct Pattern(@re.Pattern)

///|
/// Create an epsilon pattern that matches an empty sequence.
///
/// Example:
///
/// ```mbt check
/// test {
///   let _p : @bytes.Pattern = @bytes.Pattern::epsilon()
/// }
/// ```
#internal(internal, "not intended for public use")
#doc(hidden)
pub fn Pattern::epsilon() -> Pattern {
  Pattern(@re.epsilon)
}

///|
/// Create a pattern that matches nothing.
///
/// Example:
///
/// ```mbt check
/// test {
///   let _p : @bytes.Pattern = @bytes.Pattern::empty()
/// }
/// ```
#internal(internal, "not intended for public use")
#doc(hidden)
pub fn Pattern::empty() -> Pattern {
  Pattern(@re.empty)
}

///|
/// Create a single-character-class pattern from an inclusive integer range.
#internal(internal, "not intended for public use")
#doc(hidden)
pub fn Pattern::char_range(lo : Int, hi : Int) -> Pattern {
  Pattern(@re.char(@re.RecharSet::char_range(lo, hi)))
}

///|
/// Create a single-character-class pattern from sorted disjoint intervals.
#internal(internal, "not intended for public use")
#doc(hidden)
pub fn Pattern::char_set(cs : ReadOnlyArray[(Int, Int)]) -> Pattern {
  Pattern(@re.char(@re.RecharSet::from_sorted_array(cs)))
}

///|
/// Concatenate multiple patterns into a sequence.
#internal(internal, "not intended for public use")
#doc(hidden)
pub fn Pattern::seq(pats : ReadOnlyArray[Pattern]) -> Pattern {
  Pattern(@re.seq(pats.map(p => p.0)))
}

///|
/// Build an alternation that matches any of the input patterns.
#internal(internal, "not intended for public use")
#doc(hidden)
pub fn Pattern::alt(pats : ReadOnlyArray[Pattern]) -> Pattern {
  Pattern(@re.alt(pats.map(p => p.0)))
}

///|
/// Apply repetition bounds and greediness to a pattern.
///
/// - `min`: minimum repetition count.
/// - `max`: optional maximum repetition count.
/// - `greedy`: `true` for greedy, `false` for non-greedy.
#internal(internal, "not intended for public use")
#doc(hidden)
pub fn Pattern::quantifier(
  pat : Pattern,
  min~ : Int,
  max~ : Int?,
  greedy~ : Bool,
) -> Pattern {
  Pattern(
    @re.quantifier(pat.0, {
      min,
      max,
      mode: if greedy {
        Greedy
      } else {
        NonGreedy
      },
    }),
  )
}

///|
/// Wrap a pattern in a capturing group, optionally named.
#internal(internal, "not intended for public use")
#doc(hidden)
pub fn Pattern::capture(pat : Pattern, name? : String) -> Pattern {
  Pattern(@re.capture(pat.0, name?))
}

///|
/// Create a start-of-input assertion pattern.
#internal(internal, "not intended for public use")
#doc(hidden)
pub fn Pattern::start_of_input() -> Pattern {
  Pattern(@re.start_of_input)
}

///|
/// Create an end-of-input assertion pattern.
#internal(internal, "not intended for public use")
#doc(hidden)
pub fn Pattern::end_of_input() -> Pattern {
  Pattern(@re.end_of_input)
}
