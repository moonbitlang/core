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
using @debug {trait Debug, type Repr}

///|
/// Debug implementation. Never forces the thunk:
///
/// - `Forced(v)`  → `<Lazy: <v>>`
/// - `Unforced`   → `<Lazy: ...>` (matches the opaque-container
///   convention used by `Iter`).
/// - `Forcing`    → `<Lazy: forcing>` — only observable from inside the
///   thunk itself (a reentrant peek). Surfacing it explicitly helps
///   diagnose the reentrancy that would otherwise abort `force`.
///
/// Safe to call on infinite or effectful thunks.
pub impl[A : Debug] Debug for Lazy[A] with fn to_repr(self) {
  match self.state {
    Forced(v) => Repr::opaque_("Lazy", @debug.to_repr(v))
    Forcing => Repr::opaque_("Lazy", Repr::literal("forcing"))
    Unforced(_) => Repr::opaque_("Lazy", Repr::omitted())
  }
}
