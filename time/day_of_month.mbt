// Copyright 2024 International Digital Economy Academy
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

type DayOfMonth Int derive(Debug, Eq, Show, Compare)

let min_day_of_month = 1

let max_day_of_month = 31

pub fn DayOfMonth::new(day : Int) -> Result[DayOfMonth, String] {
  if day < min_day_of_month || day > max_day_of_month {
    return Err(dom_out_of_range_err)
  }
  Ok(DayOfMonth(day))
}

pub fn value(self : DayOfMonth) -> Int {
  self.0
}

test "new" {
  @assertion.assert_eq(DayOfMonth::new(0), Err(dom_out_of_range_err))?
  @assertion.assert_eq(DayOfMonth::new(32), Err(dom_out_of_range_err))?
  @assertion.assert_eq(DayOfMonth::new(1), Ok(DayOfMonth(1)))?
  @assertion.assert_eq(DayOfMonth::new(31), Ok(DayOfMonth(31)))?
}
