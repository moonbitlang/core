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
#cfg(target="js")
extern "js" fn with_unavailable_cwd(mode : Int32, check : () -> Bool) -> Bool =
  #| (mode, check) => {
  #|   const saved = Object.getOwnPropertyDescriptor(globalThis, "process");
  #|   const replacement = [
  #|     undefined,
  #|     {},
  #|     { cwd() { throw new Error("ENOENT: uv_cwd"); } },
  #|     { cwd() { return ""; } },
  #|   ][mode];
  #|   Object.defineProperty(globalThis, "process", {
  #|     configurable: true, writable: true, value: replacement,
  #|   });
  #|   try {
  #|     return check();
  #|   } finally {
  #|     if (saved) Object.defineProperty(globalThis, "process", saved);
  #|     else delete globalThis.process;
  #|   }
  #| }

///|
#cfg(target="js")
test "JS cwd failures are catchable through public path APIs" {
  let root : @path.Path = if @path.sep == '/' { "/" } else { "C:\\" }
  for mode in 0..<4 {
    assert_true(
      with_unavailable_cwd(mode, () => {
        let failures : Array[() -> Unit raise] = [
          () => ignore(@path.Path::resolve("file")),
          () => ignore(@path.Path::relative("file", base="base")),
          () => ignore(@path.Path::relative("file", base=root)),
          () => ignore(@path.Path::relative(root, base="base")),
        ]
        for failure in failures {
          try failure() catch {
            @path.ResolveError::CurrentDirectoryUnavailable => ()
            _ => return false
          } noraise {
            _ => return false
          }
        }
        try
          (root / "a" / ".." / "b").resolve() == root / "b" &&
          (root / "a" / "c").relative(base=root / "a" / "b") ==
          @path.Path("..") / "c"
        catch {
          _ => false
        }
      }),
    )
  }
}
