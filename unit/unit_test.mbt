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

test {
  let unit1 = ()
  let unit2 = ()
  assert_eq!(unit1, unit2)
}

test {
  let unit1 = ()
  let unit2 = ()
  assert_true!(physical_equal(unit1, unit2))
}

test {
  let unit = ()
  assert_eq!(@unit.default(), unit)
  assert_eq!(unit.to_string(), "()")
}

test {
  let unit1 = ()
  let unit2 = ()
  assert_eq!(@unit.compare(unit1, unit2), 0)
}

test {
  let unit = ()
  assert_eq!(unit.hash(), 0)
}
