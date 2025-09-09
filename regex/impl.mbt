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
priv enum Instruction {
  Matched
  Save(Int)
  Char(Array[Char])
  Jump(Int)
  Split(Int, Int)
  /// Zero-width assertions
  Assertion(Predicate)
  Backreference(Int)
}

///|
priv enum Predicate {
  BeginText
  EndText
  BeginLine
  EndLine
  WordBoundary
  NoWordBoundary
} derive(Show, ToJson(style="flat"))

///|
/// A thread represents a point in the execution of the VM.
/// It contains the program counter (pc) and an array of captures.
priv struct Thread {
  pc : Int
  sp : Int
  captures : Array[Int]
}

///|
/// Add a thread to the list of threads to be processed.
/// 
/// This function will forward the thread to the next instruction that consumes at least one character.
/// 
/// @param sp the current position in the input string  
/// @param content the input string  
/// @param instructions the list of instructions to execute  
/// @param inst_gen an array to track the generation of each instruction  
/// @param thread the current thread to add  
/// @param clist the list of threads to be processed in the next iteration  
fn add_thread(
  content : @string.View,
  instructions : Array[Instruction],
  inst_gen : Array[Int],
  thread : Thread,
  clist : Array[Thread],
) -> Unit {
  if inst_gen[thread.pc] == thread.sp {
    // already on the list
    return
  }
  inst_gen[thread.pc] = thread.sp
  match instructions[thread.pc] {
    Save(i) => {
      thread.captures[i] = thread.sp
      add_thread(
        content,
        instructions,
        inst_gen,
        { ..thread, pc: thread.pc + 1, captures: thread.captures },
        clist,
      )
    }
    Jump(i) =>
      add_thread(
        content,
        instructions,
        inst_gen,
        { ..thread, pc: i, captures: thread.captures },
        clist,
      )
    Split(i1, i2) => {
      add_thread(
        content,
        instructions,
        inst_gen,
        { ..thread, pc: i1, captures: thread.captures.copy() },
        clist,
      )
      add_thread(
        content,
        instructions,
        inst_gen,
        { ..thread, pc: i2, captures: thread.captures },
        clist,
      )
    }
    Assertion(pred) => {
      let sp = thread.sp
      let assertion = match pred {
        BeginText => sp == 0
        EndText => sp == content.length()
        BeginLine => sp == 0 || content[sp - 1] == '\n'
        EndLine => sp == content.length() || content[sp] == '\n'
        WordBoundary =>
          is_word_char_at(content, sp - 1) != is_word_char_at(content, sp)
        NoWordBoundary =>
          is_word_char_at(content, sp - 1) == is_word_char_at(content, sp)
      }
      if assertion {
        add_thread(
          content,
          instructions,
          inst_gen,
          { ..thread, pc: thread.pc + 1, captures: thread.captures },
          clist,
        )
      }
    }
    Backreference(i) if i * 2 >= thread.captures.length() ||
      thread.captures[i * 2] == -1 ||
      thread.captures[i * 2 + 1] == thread.captures[i * 2] =>
      add_thread(
        content,
        instructions,
        inst_gen,
        { ..thread, pc: thread.pc + 1, captures: thread.captures },
        clist,
      )
    _ => clist.push(thread)
  }
}

///|
/// The core VM function that executes the instructions against the input string.
/// 
/// @param instructions the list of instructions to execute
/// @param input the input string to match against
/// @param captures the number of capture groups
/// @param allow_exponentiaion whether to allow exponential backtracking (default: false)
/// @return an array of integers representing the start and end indices of the matches, or an empty array if no match is found
fn vm(
  instructions : Array[Instruction],
  input : @string.View,
  captures : Int,
  allow_exponentiaion~ : Bool = false,
) -> Array[Int] {
  guard instructions is [.., Save(1), Matched]
  let inst_gen = Array::make(instructions.length(), -1)
  let mut clist = Array::new(capacity=instructions.length())
  let mut nlist = Array::new(capacity=instructions.length())
  let mut matched : Array[Int] = []
  add_thread(
    input,
    instructions,
    inst_gen,
    { sp: 0, pc: 0, captures: Array::make(captures * 2, -1) },
    clist,
  )
  for sp = 0; sp <= input.length(); {
    if clist.is_empty() {
      break
    }
    let actual_char = if sp == input.length() {
      (-1).unsafe_to_char()
    } else {
      input.get_char(sp).unwrap()
    }
    let next_sp = if actual_char.to_int() > 0xFFFF { sp + 2 } else { sp + 1 }
    for thread in clist {
      let { pc, captures, sp: thread_sp } = thread
      if thread_sp > sp {
        // this thread is in the future state
        nlist.push(thread)
        continue
      }
      guard thread_sp == sp
      if instructions[pc] is Matched {
        matched = captures
        // drop everything that has lower priority
        break
      }
      // should have been handled in the add_thread
      match instructions[pc] {
        Char(chars) =>
          if char_in_ranges(actual_char, chars) {
            add_thread(
              input,
              instructions,
              if allow_exponentiaion {
                Array::make(instructions.length(), -1)
              } else {
                inst_gen
              },
              { pc: pc + 1, captures, sp: next_sp },
              nlist,
            )
          }
        Backreference(i) => {
          let start = captures[i * 2]
          let end = captures[i * 2 + 1]
          let len = end - start
          guard len != 0
          let next_sp = sp + len
          if next_sp <= input.length() &&
            input.view(start_offset=start, end_offset=end) ==
            input.view(start_offset=sp, end_offset=next_sp) {
            add_thread(
              input,
              instructions,
              Array::make(instructions.length(), -1),
              { pc: pc + 1, captures, sp: next_sp },
              nlist,
            )
          }
        }
        _ => panic()
      }
    }
    let tmp = clist
    clist = nlist
    nlist = tmp
    nlist.clear()
    continue next_sp
  }
  return matched
}
