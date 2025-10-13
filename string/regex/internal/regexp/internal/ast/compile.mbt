// Copyright 2025 International Digital Economy Academy
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
pub(all) enum Ast {
  Empty
  /// Anything that can be interpreted as range (inclusive) pair list, e.g. `.` (0..=0x10FFFF)
  CharClass(Array[Char], neg~ : Bool)
  Assertion(Predicate)
  Capture(Ast, index~ : Int)
  ZeroOrMore(Ast, greedy~ : Bool)
  OneOrMore(Ast, greedy~ : Bool)
  ZeroOrOne(Ast, greedy~ : Bool)
  /// Matches a specific number of repetitions.
  Repeat(Ast, greedy~ : Bool, min~ : UInt, max~ : UInt?)
  Concat(Array[Ast])
  Alternate(Ast, Ast)
  Backreference(Int)
} derive(Show)

///|
/// @returns next capture
fn Ast::compile_aux(regex : Ast, instructions : Array[Instruction]) -> Unit {
  match regex {
    Empty => ()
    CharClass(chars, neg~) =>
      if neg {
        // compute the complement of the character class
        let complement = compute_char_class_complement(chars)
        instructions.push(Char(complement))
      } else {
        // simplify and sort the character ranges for binary search
        let simplified = simplify_char_ranges(chars)
        instructions.push(Char(simplified))
      }
    Assertion(pred) => instructions.push(Assertion(pred))
    Capture(inner, index=capture) => {
      instructions.push(Save(capture * 2))
      inner.compile_aux(instructions)
      instructions.push(Save(capture * 2 + 1))
    }
    ZeroOrMore(inner, greedy~) => {
      // Compiles to (a+)?
      // See https://github.com/golang/go/issues/46123
      // [ ..., split, inner, split, ... ]
      //          ^ -- instructions.length() at the beginning
      //                            ^ -- instructions.length() at the end
      let split_pos = instructions.length()
      // placeholder for split
      instructions.push(Split(-1, -1))
      inner.compile_aux(instructions)
      let next_pos = instructions.length()
      if not(greedy) {
        instructions.push(Split(next_pos + 1, split_pos + 1))
        instructions[split_pos] = Split(next_pos + 1, split_pos + 1)
      } else {
        instructions.push(Split(split_pos + 1, next_pos + 1))
        instructions[split_pos] = Split(split_pos + 1, next_pos + 1)
      }
    }
    OneOrMore(inner, greedy~) => {
      // [ ..., inner, split, ... ]
      //         ^ -- instructions.length() at the beginning
      let jmp_pos = instructions.length()
      inner.compile_aux(instructions)
      let next_pos = instructions.length()
      if not(greedy) {
        instructions.push(Split(next_pos + 1, jmp_pos))
      } else {
        instructions.push(Split(jmp_pos, next_pos + 1))
      }
    }
    ZeroOrOne(inner, greedy~) => {
      // [ ..., split, inner, ... ]
      //          ^ -- instructions.length() at the beginning
      //                        ^ -- instructions.length() at the end
      let split_pos = instructions.length()
      // for taking up position
      instructions.push(Split(-1, -1))
      inner.compile_aux(instructions)
      if not(greedy) {
        instructions[split_pos] = Split(instructions.length(), split_pos + 1)
      } else {
        instructions[split_pos] = Split(split_pos + 1, instructions.length())
      }
    }
    Repeat(greedy~, min~, max~, inner) =>
      if max is Some(max) {
        // [ ..., inner * min, [ split, inner ] * (max - min), ... ]
        for i in 0U..<min {
          inner.compile_aux(instructions)
        }
        let split_pos = []
        for i in 0U..<(max - min) {
          // placeholder for split
          split_pos.push(instructions.length())
          instructions.push(Split(-1, -1))
          inner.compile_aux(instructions) |> ignore
        }
        let jmp_pos = instructions.length()
        if not(greedy) {
          for pos in split_pos {
            instructions[pos] = Split(jmp_pos, pos + 1)
          }
        } else {
          for pos in split_pos {
            instructions[pos] = Split(pos + 1, jmp_pos)
          }
        }
      } else {
        // [ ..., inner * min, split, inner, jmp, ... ]
        //                      ^ -- instructions.length() at the beginning
        //                                         ^ -- instructions.length() at the end
        for i in 0U..<min {
          inner.compile_aux(instructions)
        }
        let split_pos = instructions.length()
        // placeholder for split
        instructions.push(Split(-1, -1))
        inner.compile_aux(instructions)
        instructions.push(Jump(split_pos))
        if not(greedy) {
          instructions[split_pos] = Split(instructions.length(), split_pos + 1)
        } else {
          instructions[split_pos] = Split(split_pos + 1, instructions.length())
        }
      }
    Concat(regexs) =>
      for regex in regexs {
        regex.compile_aux(instructions)
      }
    Alternate(left, right) => {
      // [ ..., split, left, jmp, right, ... ]
      //          ^ -- instructions.length() at the beginning
      //                      ^ -- instructions.length() at the middle
      //                                   ^ -- instructions.length() at the end
      let split_pos = instructions.length()
      // for taking up position
      instructions.push(Split(-1, -1))
      left.compile_aux(instructions)
      let jmp_pos = instructions.length()
      // placeholder for jump
      instructions.push(Jump(-1))
      right.compile_aux(instructions)
      instructions[split_pos] = Split(split_pos + 1, jmp_pos + 1)
      instructions[jmp_pos] = Jump(instructions.length())
    }
    Backreference(i) => instructions.push(Backreference(i))
  }
}

///|
pub fn Ast::compile(self : Ast) -> Array[Instruction] {
  // for leftmost matching
  let instructions : Array[Instruction] = [
    Split(3, 1),
    Char(['\u{0}', '\u{10FFFF}']),
    Jump(0),
  ]
  // start matching
  instructions.push(Save(0))
  self.compile_aux(instructions)
  instructions.push(Save(1))
  instructions.push(Matched)
  instructions
}

///|
pub impl ToJson for Ast with to_json(self) {
  match self {
    Empty => "Empty"
    CharClass(chars, neg~) => ["CharClass neg=\{neg}", chars.map(c => repr(c))]
    Assertion(pred) => "Assertion \{pred}"
    Capture(inner, index~) => ["Capture \{index}", inner]
    ZeroOrMore(inner, greedy~) => ["ZeroOrMore greedy=\{greedy}", inner]
    OneOrMore(inner, greedy~) => ["OneOrMore greedy=\{greedy}", inner]
    ZeroOrOne(inner, greedy~) => ["ZeroOrOne greedy=\{greedy}", inner]
    Repeat(greedy~, min~, max~, inner) =>
      if max is Some(max) {
        ["Repeat {\{min}, \{max}} greedy=\{greedy}", inner]
      } else {
        ["Repeat {\{min},} greedy=\{greedy}", inner]
      }
    Concat(regexs) => [..regexs.map(_.to_json())]
    Alternate(left, right) => ["Alternate", left, right]
    Backreference(i) => ["Backreference", i]
  }
}
