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
  days : Int
} derive(Debug, Eq, Compare)

pub fn Period::of(
  ~years : Int = 0,
  ~months : Int = 0,
  ~days : Int = 0
) -> Period {
  { years, months, days }
}

pub fn Period::zero() -> Period {
  { years: 0, months: 0, days: 0 }
}

pub fn Period::from_string(str : String) -> Result[Period, String] {
  // TODO: better parsing impl
  if str[0] != 'P' {
    return Err(invalid_period_err)
  }
  let buf = Buffer::make(0)
  let mut years = 0
  let mut months = 0
  let mut days = 0
  for i = 1; i < str.length(); i = i + 1 {
    match str[i] {
      '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' | '-' =>
        buf.write_char(str[i])
      'Y' => {
        years = @strconv.parse(buf.to_string())?
        buf.reset()
      }
      'M' => {
        months = @strconv.parse(buf.to_string())?
        buf.reset()
      }
      'D' => {
        days = @strconv.parse(buf.to_string())?
        buf.reset()
        break
      }
      _ => return Err(invalid_period_err)
    }
  }
  Ok(Period::of(~years, ~months, ~days))
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
  if self.days != 0 {
    buf.write_string(self.days.to_string())
    buf.write_char('D')
  }
  buf.to_string()
}

pub fn years(self : Period) -> Int {
  self.years
}

pub fn months(self : Period) -> Int {
  self.months
}

pub fn days(self : Period) -> Int {
  self.days
}

pub fn add_years(self : Period, years : Int) -> Result[Period, String] {
  if years == 0 {
    return Ok(self)
  }
  let new_years = checked_add_int(self.years, years)?
  Ok(Period::of(years=new_years, months=self.months, days=self.days))
}

pub fn add_weeks(self : Period, weeks : Int) -> Result[Period, String] {
  if weeks == 0 {
    return Ok(self)
  }
  let new_days = checked_add_int(self.days, checked_mul_int(weeks, 7)?)?
  Ok(Period::of(years=self.years, months=self.months, days=new_days))
}

pub fn add_months(self : Period, months : Int) -> Result[Period, String] {
  if months == 0 {
    return Ok(self)
  }
  let new_months = checked_add_int(self.months, months)?
  Ok(
    Period::of(
      years=self.years,
      months=new_months,
      days=self.days,
    ),
  )
}

pub fn add_days(self : Period, days : Int) -> Result[Period, String] {
  if days == 0 {
    return Ok(self)
  }
  let new_days = checked_add_int(self.days, days)?
  Ok(
    Period::of(
      years=self.years,
      months=self.months,
      days=new_days,
    ),
  )
}

pub fn add_period(self : Period, other : Period) -> Result[Period, String] {
  if other.is_zero() {
    return Ok(self)
  }
  self.add_years(other.years())?.add_months(other.months())?.add_days(other.days())
}

pub fn op_add(self : Period, other : Period) -> Result[Period, String] {
  self.add_period(other)
}

pub fn op_sub(self : Period, other : Period) -> Result[Period, String] {
  self.add_period(other.negated()?)
}

pub fn multiply(self : Period, n : Int) -> Result[Period, String] {
  if n == 0 {
    return Ok(Period::zero())
  }
  if self.is_zero() || n == 1 {
    return Ok(self)
  }
  let years = checked_mul_int(self.years, n)?
  let months = checked_mul_int(self.months, n)?
  let days = checked_mul_int(self.days, n)?
  Ok(Period::of(~years, ~months, ~days))
}

pub fn negated(self : Period) -> Result[Period, String] {
  self.multiply(-1)
}

pub fn with_years(self : Period, years : Int) -> Period {
  if years == self.years {
    self
  } else {
    Period::of(~years, months=self.months, days=self.days)
  }
}

pub fn with_months(self : Period, months : Int) -> Period {
  if months == self.months {
    self
  } else {
    Period::of(years=self.years, ~months, days=self.days)
  }
}

pub fn with_days(self : Period, days : Int) -> Period {
  if days == self.days {
    self
  } else {
    Period::of(years=self.years, months=self.months, ~days)
  }
}

pub fn is_zero(self : Period) -> Bool {
  self.years == 0 && self.months == 0 && self.days == 0
}

pub fn is_neg(self : Period) -> Bool {
  self.years < 0 || self.months < 0 || self.days < 0
}

pub fn Period::get_calendar(_self : Period) -> Calendar {
  iso_calendar
}
