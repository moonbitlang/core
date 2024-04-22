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

pub trait Calendar {
  get_type(Self) -> CalendarType
  to_string(Self) -> String
  era(Self, PlainDate) -> String
  era_year(Self, PlainDate) -> Int
  year(Self, PlainDate) -> Int
  month(Self, PlainDate) -> Int
  day(Self, PlainDate) -> Int
  day_of_week(Self, PlainDate) -> DayOfWeek
  day_of_year(Self, PlainDate) -> Int
  days_in_week(Self, PlainDate) -> Int
  days_in_month(Self, PlainDate) -> Int
  days_in_year(Self, PlainDate) -> Int
  months_in_year(Self, PlainDate) -> Int
  in_leap_year(Self, PlainDate) -> Bool
  add_years(Self, PlainDate, Int) -> Result[PlainDate, String]
  add_months(Self, PlainDate, Int) -> Result[PlainDate, String]
  add_weeks(Self, PlainDate, Int) -> Result[PlainDate, String]
  add_days(Self, PlainDate, Int) -> Result[PlainDate, String]
  add_period(Self, PlainDate, Period) -> Result[PlainDate, String]
  with_year(Self, PlainDate, Int) -> Result[PlainDate, String]
  with_month(Self, PlainDate, Int) -> Result[PlainDate, String]
  with_day(Self, PlainDate, Int) -> Result[PlainDate, String]
  date_from(Self, Int, Int, Int) -> Result[PlainDate, String]
}

pub enum CalendarType {
  // TODO: implements more calendar
  ISO8601
} derive(Debug, Eq)

pub fn to_string(self: CalendarType) -> String {
  match self {
    ISO8601 => "iso8601"
  }
}

pub fn calendar_of(name : String) -> Option[Calendar] {
  match name {
    "iso8601" => Some(iso_calendar)
    _ => None
  }
}
