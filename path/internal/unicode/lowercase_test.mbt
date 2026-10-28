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
test "default string lowercase special casing" {
  inspect(@unicode.lowercase(""), content="")
  inspect(@unicode.lowercase("ABCXYZ"), content="abcxyz")
  inspect(@unicode.lowercase("İIıi"), content="i\u{0307}iıi")
  inspect(
    @unicode.lowercase("Σ ΟΣ ΟΣΑ ΟΣ. ΟΣ.Α"),
    content="σ ος οσα ος. οσ.α",
  )
  inspect(@unicode.lowercase("AΣ\u{0301}"), content="aς\u{0301}")
  inspect(@unicode.lowercase("AΣ\u{0301}B"), content="aσ\u{0301}b")
  inspect(@unicode.lowercase("A\u{0301}Σ"), content="a\u{0301}ς")
  // U+0345 is both Cased and Case_Ignorable.
  inspect(@unicode.lowercase("\u{0345}Σ"), content="\u{0345}σ")
  inspect(@unicode.lowercase("AΣ\u{0345}"), content="aς\u{0345}")
  inspect(@unicode.lowercase("AΣ\u{0345}B"), content="aσ\u{0345}b")
  inspect(@unicode.lowercase("𐐀Σ\\Σ"), content="𐐨ς\\σ")
  // A letter can be Cased without having a lowercase mapping.
  inspect(@unicode.lowercase("ªΣ"), content="ªς")
  inspect(@unicode.lowercase("ᴬΣ"), content="ᴬσ")
}

///|
#cfg(target="js")
extern "js" fn js_lowercase(source : String) -> String =
  #| source => source.toLowerCase()

///|
#cfg(target="js")
test "lowercase agrees with JavaScript for casing contexts" {
  let contexts = [
    "", "A", "a", "Σ", "σ", "ς", "İ", "ª", "ᴬ", "𐐀", "月", "1", " ", ".",
    "'", "\\", "\u{0301}", "\u{0345}", "\u{200D}", "A\u{0301}",
  ]
  for before in contexts {
    for after in contexts {
      let source = "\{before}Σ\{after}"
      assert_eq(@unicode.lowercase(source), js_lowercase(source))
    }
  }
}
