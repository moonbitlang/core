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
async fn IoHandle::read_via_event_bus(
  handle : IoHandle,
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
  context~ : String,
) -> Int32 {
  if platform is Windows {
    handle.read_via_event_bus_windows(buf, offset~, len~, context~)
  } else {
    handle.read_via_event_bus_unix(buf, offset~, len~, context~)
  }
}

///|
async fn IoHandle::write_via_event_bus(
  handle : IoHandle,
  buf : Bytes,
  offset~ : Int32,
  len~ : Int32,
  context~ : String,
) -> Int32 {
  if platform is Windows {
    handle.write_via_event_bus_windows(buf, offset~, len~, context~)
  } else {
    handle.write_via_event_bus_unix(buf, offset~, len~, context~)
  }
}
