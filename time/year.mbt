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

type Year Int derive(Debug, Eq, Show, Compare)

let min_year : Int = -999999999

let max_year : Int = 999999999

pub fn Year::new(year : Int) -> Result[Year, String] {
  if year < min_year || year > max_year {
    return Err(year_out_of_range_err)
  }
  Ok(Year(year))
}

pub fn add(self : Year, years_to_add : Int) -> Result[Year, String] {
  Year::new(self.0 + years_to_add)
}

pub fn value(self : Year) -> Int {
  self.0
}

pub fn length(self : Year) -> Int {
  if self.is_leap_year() {
    366
  } else {
    365
  }
}

pub fn is_leap_year(self : Year) -> Bool {
  // TODO: improve performance
  self.0 % 4 == 0 && self.0 % 100 != 0 || self.0 % 400 == 0
}

test "new" {
  @assertion.assert_eq(Year::new(-999999999), Ok(Year(-999999999)))?
  @assertion.assert_eq(Year::new(-1000000000), Err(year_out_of_range_err))?
  @assertion.assert_eq(Year::new(999999999), Ok(Year(999999999)))?
  @assertion.assert_eq(Year::new(1000000000), Err(year_out_of_range_err))?
  @assertion.assert_eq(Year::new(1970), Ok(Year(1970)))?
}

test "is_leap" {
  @assertion.assert_true(Year::Year(2000).is_leap_year())?
  @assertion.assert_false(Year::Year(2001).is_leap_year())?
}

test "length" {
  @assertion.assert_eq(Year::Year(2000).length(), 366)?
  @assertion.assert_eq(Year::Year(2001).length(), 365)?
}
