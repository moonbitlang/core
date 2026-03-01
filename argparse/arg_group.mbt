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
/// Declarative argument group constructor.
pub struct ArgGroup {
  priv name : String
  priv required : Bool
  priv multiple : Bool
  priv args : Array[String]
  priv requires : Array[String]
  priv conflicts_with : Array[String]

  /// Create an argument group.
  fn new(
    name : StringView,
    required? : Bool,
    multiple? : Bool,
    args? : ArrayView[String],
    requires? : ArrayView[String],
    conflicts_with? : ArrayView[String],
  ) -> ArgGroup
}

///|
/// Create an argument group.
///
/// Notes:
/// - `required=true` means at least one member of the group must be present.
/// - `multiple=false` means group members are mutually exclusive.
/// - `requires` and `conflicts_with` can reference either group names or arg names.
pub fn ArgGroup::new(
  name : StringView,
  required? : Bool = false,
  multiple? : Bool = true,
  args? : ArrayView[String] = [],
  requires? : ArrayView[String] = [],
  conflicts_with? : ArrayView[String] = [],
) -> ArgGroup {
  {
    name: name.to_string(),
    required,
    multiple,
    args: args.to_array(),
    requires: requires.to_array(),
    conflicts_with: conflicts_with.to_array(),
  }
}
