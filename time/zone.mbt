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

/// Time zone.
struct Zone {
  id : String
  offsets : Array[ZoneOffset]
  // TODO: offset transition rules
} derive(Eq)

/// UTC time zone.
pub let utc_zone : Zone = { id: "UTC", offsets: [utc_offset] }

/// Creates a time zone with fixed offset from time zone id and offset seconds.
pub fn fixed_zone(id : String, offset_seconds : Int) -> Result[Zone, String] {
  let offset = ZoneOffset::from_seconds(offset_seconds)?
  Ok(Zone::{ id, offsets: [offset] })
}

/// Checks if this zone only has one offset.
pub fn is_fixed(self : Zone) -> Bool {
  self.offsets.length() == 1
}

/// Returns the zone id.
pub fn to_string(self : Zone) -> String {
  self.id
}

fn lookup_offset(self : Zone, _secs : Int64) -> ZoneOffset {
  if self.offsets.length() == 0 {
    return utc_offset
  }
  if self.is_fixed() {
    return self.offsets[0]
  }
  // TODO: lookup the offset by the seconds elapsed from unix epoch and the offset transition rules
  self.offsets[0]
}
