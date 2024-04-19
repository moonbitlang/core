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

enum DayOfWeek {
  Monday
  Tuesday
  Wednesday
  Thursday
  Friday
  Saturday
  Sunday
} derive(Debug, Eq, Show)

fn DayOfWeek::new(week_day : Int) -> Option[DayOfWeek] {
  match week_day {
    1 => Some(Monday)
    2 => Some(Tuesday)
    3 => Some(Wednesday)
    4 => Some(Thursday)
    5 => Some(Friday)
    6 => Some(Saturday)
    7 => Some(Sunday)
    _ => None
  }
}

fn value(self : DayOfWeek) -> Int {
  match self {
    Monday => 1
    Tuesday => 2
    Wednesday => 3
    Thursday => 4
    Friday => 5
    Saturday => 6
    Sunday => 7
  }
}

test "new" {
  inspect(DayOfWeek::new(0), content="None")?
  inspect(DayOfWeek::new(1), content="Some(Monday)")?
  inspect(DayOfWeek::new(2), content="Some(Tuesday)")?
  inspect(DayOfWeek::new(3), content="Some(Wednesday)")?
  inspect(DayOfWeek::new(4), content="Some(Thursday)")?
  inspect(DayOfWeek::new(5), content="Some(Friday)")?
  inspect(DayOfWeek::new(6), content="Some(Saturday)")?
  inspect(DayOfWeek::new(7), content="Some(Sunday)")?
  inspect(DayOfWeek::new(8), content="None")?
}

test "value" {
  inspect(DayOfWeek::Monday.value(), content="1")?
  inspect(DayOfWeek::Tuesday.value(), content="2")?
  inspect(DayOfWeek::Wednesday.value(), content="3")?
  inspect(DayOfWeek::Thursday.value(), content="4")?
  inspect(DayOfWeek::Friday.value(), content="5")?
  inspect(DayOfWeek::Saturday.value(), content="6")?
  inspect(DayOfWeek::Sunday.value(), content="7")?
}
