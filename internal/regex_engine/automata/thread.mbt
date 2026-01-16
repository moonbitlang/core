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
/// An execution thread in the automaton representing a possible matching path.
///
/// `Thread` represents a single execution path during pattern matching. The automaton
/// maintains multiple threads simultaneously to handle nondeterministic choices
/// (alternations, quantifiers, etc.). Each thread tracks its current state using
/// a `MarkSlotMap` to record positions encountered so far.
///
/// # Variants
///
/// - `End(MarkSlotMap)`: Thread has reached a successful match state with the given marks
/// - `Exp(MarkSlotMap, Expr)`: Thread is executing the given expression with current marks
/// - `Seq(Preference, ThreadSet, Expr)`: Thread is executing a sequence where:
///   - The first part has produced multiple threads (stored in `ThreadSet`)
///   - The next expression hasn't been executed yet
///   - Preference determines how to prioritize results (First/Longest)
///
/// # Thread Lifecycle
///
/// 1. Thread starts with `Exp(MarkSlotMap::empty(), initial_expr)`
/// 2. During derivative computation, threads transform based on input:
///    - May split into multiple threads (alternation)
///    - May transition to `Seq` for sequences
///    - May reach `End` when matching succeeds
/// 3. Threads are eliminated if they can't match the current input
priv enum Thread {
  End(MarkSlotMap)
  Exp(MarkSlotMap, Expr)
  Seq(@shared_types.Preference, ThreadSet, Expr)
} derive(Eq, Hash)
