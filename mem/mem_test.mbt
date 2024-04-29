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

fn test_load(m : Loadable) -> Result[Unit, String] {
  inspect(m.load_int(1, Big), content="33752069")?
  inspect(m.load_int64(1, Big), content="144964032628459529")?
  inspect(m.load_int(1, Little), content="84148994")?
  inspect(m.load_int64(1, Little), content="650777868590383874")?
  Ok(())
}

test "load bytes" {
  test_load(Bytes::[1, 2, 3, 4, 5, 6, 7, 8, 9])?
}

test "load bytes view" {
  test_load(
    {
      Bytes::[0, 1, 2, 3, 4, 5, 6, 7, 8, 9][1..]
    },
  )?
}

test "load int vec" {
  test_load(@vec.Vec::[1, 2, 3, 4, 5, 6, 7, 8, 9])?
}

test "load int vec view" {
  test_load(
    {
      @vec.Vec::[0, 1, 2, 3, 4, 5, 6, 7, 8, 9][1..]
    },
  )?
}

test "bytes" {
  let v = Bytes::make(9, 0x04)
  (v as Storable).store_int(2, 0x08080808, Big)
  inspect(v, content="ЄࠈࠈЄ")?
  (v as Storable).store_int64(1, 0x0607080901020304L, Big)
  inspect(v, content="\u{604}ࠇĉ\u{302}")?
}

test "bytes view" {
  let v = Bytes::make(9, 0x04)
  ((v[1..]) as Storable).store_int(2, 0x08080808, Big)
  inspect(v, content="ЄࠄࠈЈ")?
  ((v[1..]) as Storable).store_int64(0, 0x0607080901020304L, Big)
  inspect(v, content="\u{604}ࠇĉ\u{302}")?
}

test "int vec" {
  let v = @vec.with_capacity(9)
  v.fill(0)
  (v as Storable).store_int(2, 1239873143, Big)
  inspect(v, content="Vec::[0, 0, 73, 230, 246, 119, 0, 0, 0]")?
  (v as Storable).store_int64(1, 1239873143123719283L, Big)
  inspect(v, content="Vec::[0, 17, 52, 234, 13, 246, 111, 180, 115]")?
}

test "int vec view" {
  let v = @vec.with_capacity(9)
  v.fill(0)
  ((v[1..]) as Storable).store_int(3, 1239873143, Big)
  inspect(v, content="Vec::[0, 0, 0, 0, 73, 230, 246, 119, 0]")?
  ((v[1..]) as Storable).store_int64(0, 1239873143123719283L, Big)
  inspect(v, content="Vec::[0, 17, 52, 234, 13, 246, 111, 180, 115]")?
}

test "copy" {
  let src = @vec.Vec::[1, 2, 3, 4, 5]
  let dst = @vec.Vec::[0, 0, 0, 0, 0]
  copy(
    {
      dst[1..]
    },
    {
      src[2..]
    },
    3,
  )
  inspect(dst, content="Vec::[0, 3, 4, 5, 0]")?
}
