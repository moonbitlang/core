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
/// A marker used to track positions in the regex automaton.
///
/// `Mark` is a newtype wrapper around `Int` that represents an abstract position
/// marker in the automaton. The actual integer value has no inherent meaning within
/// the automaton package - it simply serves as a unique identifier that can be
/// placed in the automaton and later mapped to slots for storing information.
///
/// # Usage in Core Package
///
/// The `core` package uses `Mark` to implement capture group support by following
/// a specific encoding convention. Each capture group has two marks:
/// - Start mark: `Mark(group_index * 2)`
/// - End mark: `Mark(group_index * 2 + 1)`
///
/// These marks record where capture groups begin and end during pattern matching,
/// with the mark values mapped to slots in `MarkSlotMap` to store byte positions.
///
/// ## Example
///
/// For a pattern like `(a(b)c)`, the core package assigns marks as:
/// - Group 0 (whole match): Mark(0) for start, Mark(1) for end
/// - Group 1 `(a(b)c)`: Mark(2) for start, Mark(3) for end
/// - Group 2 `(b)`: Mark(4) for start, Mark(5) for end
///
/// Note: This encoding is an implementation detail of the core package.
/// Other uses of the automaton could assign mark values differently.
pub(all) struct Mark(Int) derive(Eq, Hash, Compare)
