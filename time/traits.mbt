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

/// Some date related operations
pub trait Datelike {
  year(Self) -> Int
  month(Self) -> Int
  day(Self) -> Int
  ordinal(Self) -> Int
  weekday(Self) -> Int
  with_year(Self, Int) -> Result[Self, String]
  with_month(Self, Int) -> Result[Self, String]
  with_day(Self, Int) -> Result[Self, String]
  with_ordinal(Self, Int) -> Result[Self, String]
}

/// Some time related operations
pub trait Timelike {
  hour(Self) -> Int
  minute(Self) -> Int
  second(Self) -> Int
  nanosecond(Self) -> Int
  with_hour(Self, Int64) -> Result[Self, String]
  with_minute(Self, Int64) -> Result[Self, String]
  with_second(Self, Int64) -> Result[Self, String]
  with_nanosecond(Self, Int64) -> Result[Self, String]
}
