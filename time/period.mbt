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

struct Period {
  years : Int
  months : Int
  weeks : Int
  days : Int
} derive(Debug, Eq, Compare)

pub fn Period::of(
  ~years : Int = 0,
  ~months : Int = 0,
  ~weeks : Int = 0,
  ~days : Int = 0
) -> Period {
  { years, months, weeks, days }
}

/// Creates a Period consisting of the years, months and days between two dates.
pub fn Period::between(start : PlainDate, end : PlainDate) -> Period {
  iso_calendar.until(start, end).unwrap()
}

pub fn Period::from_string(str : String) -> Result[Period, String] {
  let buf = Buffer::make(str.length())
  if str[0] != 'P' {
    return Err(invalid_period_err)
  }
  let mut years = 0
  let mut months = 0
  let mut weeks = 0
  let mut days = 0
  for i = 1; i < str.length(); i = i + 1 {
    match str[i] {
      '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' =>
        buf.write_char(str[i])
      'Y' => {
        years = @strconv.parse(buf.to_string())?
        buf.reset()
      }
      'M' => {
        months = @strconv.parse(buf.to_string())?
        buf.reset()
      }
      'W' => {
        weeks = @strconv.parse(buf.to_string())?
        buf.reset()
      }
      'D' => {
        days = @strconv.parse(buf.to_string())?
        buf.reset()
      }
      _ => return Err(invalid_period_err)
    }
  }
  Ok(Period::of(~years, ~months, ~weeks, ~days))
}

pub fn years(self : Period) -> Int {
  self.years
}

pub fn months(self : Period) -> Int {
  self.months
}

pub fn weeks(self : Period) -> Int {
  self.weeks
}

pub fn days(self : Period) -> Int {
  self.days
}

pub fn add_years(self : Period, years : Int) -> Result[Period, String] {
  if years == 0 {
    return Ok(self)
  }
  let new_years = match checked_add_int(self.years, years) {
    Some(v) => v
    None => return Err(invalid_period_err)
  }
  Ok(
    Period::of(
      years=new_years,
      months=self.months,
      weeks=self.weeks,
      days=self.days,
    ),
  )
}

pub fn add_weeks(self : Period, weeks : Int) -> Result[Period, String] {
  if weeks == 0 {
    return Ok(self)
  }
  let new_weeks = match checked_add_int(self.weeks, weeks) {
    Some(v) => v
    None => return Err(invalid_period_err)
  }
  Ok(
    Period::of(
      years=self.years,
      months=self.months,
      weeks=new_weeks,
      days=self.days,
    ),
  )
}

pub fn add_months(self : Period, months : Int) -> Result[Period, String] {
  if months == 0 {
    return Ok(self)
  }
  let new_months = match checked_add_int(self.months, months) {
    Some(v) => v
    None => return Err(invalid_period_err)
  }
  Ok(
    Period::of(
      years=self.years,
      months=new_months,
      weeks=self.weeks,
      days=self.days,
    ),
  )
}

pub fn add_days(self : Period, days : Int) -> Result[Period, String] {
  if days == 0 {
    return Ok(self)
  }
  let new_days = match checked_add_int(self.days, days) {
    Some(v) => v
    None => return Err(invalid_period_err)
  }
  Ok(
    Period::of(
      years=self.years,
      months=self.months,
      weeks=self.weeks,
      days=new_days,
    ),
  )
}

pub fn with_years(self : Period, years : Int) -> Period {
  if years == self.years {
    self
  } else {
    Period::of(~years, months=self.months, weeks=self.weeks, days=self.days)
  }
}

pub fn with_months(self : Period, months : Int) -> Period {
  if months == self.months {
    self
  } else {
    Period::of(years=self.years, ~months, weeks=self.weeks, days=self.days)
  }
}

pub fn with_weeks(self : Period, weeks : Int) -> Period {
  if weeks == self.weeks {
    self
  } else {
    Period::of(years=self.years, months=self.months, ~weeks, days=self.days)
  }
}

pub fn with_days(self : Period, days : Int) -> Period {
  if days == self.days {
    self
  } else {
    Period::of(years=self.years, months=self.months, weeks=self.weeks, ~days)
  }
}

pub fn is_zero(self : Period) -> Bool {
  self.years == 0 && self.months == 0 && self.weeks == 0 && self.days == 0
}

pub fn is_neg(self : Period) -> Bool {
  self.years < 0 || self.months < 0 || self.weeks < 0 || self.days < 0
}

pub fn Period::get_calendar(_self : Period) -> Calendar {
  iso_calendar
}

pub fn to_string(self : Period) -> String {
  if self.is_zero() {
    return "P0D"
  }
  let buf = Buffer::make(0)
  buf.write_char('P')
  if self.years != 0 {
    buf.write_string(self.years.to_string())
    buf.write_char('Y')
  }
  if self.months != 0 {
    buf.write_string(self.months.to_string())
    buf.write_char('M')
  }
  if self.weeks != 0 {
    buf.write_string(self.weeks.to_string())
    buf.write_char('W')
  }
  if self.days != 0 {
    buf.write_string(self.days.to_string())
    buf.write_char('D')
  }
  buf.to_string()
}
