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
fn[T : Show] edits_to_string(d : @diff.Diff[T]) -> String {
  let lines = Array::new()
  for edit in d.edits {
    let (prefix, slice) = match edit {
      Insert(new_index~, new_len~, ..) =>
        ("+", d.new.view(start=new_index, end=new_index + new_len))
      Delete(old_index~, old_len~, ..) =>
        ("-", d.old.view(start=old_index, end=old_index + old_len))
      Equal(old_index~, len~, ..) =>
        (" ", d.old.view(start=old_index, end=old_index + len))
    }
    for s in slice {
      lines.push("\{prefix} \{s}")
    }
  }
  lines.join("\n")
}

///|
fn[T : Show] hunks_to_string(hunks : Array[@diff.Hunk[T]]) -> String {
  hunks.map(fn(h) { h.to_string() }).join("\n")
}

///|
struct User {
  id : Int
  name : String
} derive(Hash, Eq)

///|
impl Show for User with output(self, logger) {
  logger.write_string(
    "User { id: " + self.id.to_string() + ", name: " + self.name + " }",
  )
}

///|
enum Token {
  Start
  Stop
  Num(Int)
  Word(String)
} derive(Hash, Eq)

///|
impl Show for Token with output(self, logger) {
  match self {
    Start => logger.write_string("Start")
    Stop => logger.write_string("Stop")
    Num(n) => logger.write_string("Num(" + n.to_string() + ")")
    Word(s) => logger.write_string("Word(\"" + s + "\")")
  }
}

///|
test "condense into one equal" {
  let old = [
      "apple", "pineapple", "banana", "tomato", "carrot", "tomato", "potato", "cabbage",
    ][:]
  let new = [
      "apple", "pineapple", "banana", "tomato", "carrot", "tomato", "potato", "cabbage",
    ][:]
  assert_eq(old, new)
  let d = @diff.Diff(old~, new~)
  inspect(
    edits_to_string(d),
    content=(
      #|  apple
      #|  pineapple
      #|  banana
      #|  tomato
      #|  carrot
      #|  tomato
      #|  potato
      #|  cabbage
    ),
  )
}

///|
test "mixed" {
  let old = ["carrot", "tomato", "potato", "cabbage"][:]
  let new = ["apple", "banana", "tomato", "pineapple"][:]
  let d = @diff.Diff(old~, new~)
  inspect(
    edits_to_string(d),
    content=(
      #|- carrot
      #|+ apple
      #|+ banana
      #|  tomato
      #|- potato
      #|- cabbage
      #|+ pineapple
    ),
  )
}

///|
test "delete then insert to hunks" {
  let old = ["fn main() {", "  println(\"foo\")", "}"][:]
  let new = ["fn main() {", "  println(\"bar\")", "}"][:]
  let d = @diff.Diff(old~, new~)
  inspect(
    edits_to_string(d),
    content=(
      #|  fn main() {
      #|-   println("foo")
      #|+   println("bar")
      #|  }
    ),
  )
  inspect(
    hunks_to_string(d.group()),
    content=(
      #|@@ -1,3 +1,3 @@
      #| fn main() {
      #|-  println("foo")
      #|+  println("bar")
      #| }
      #|
    ),
  )
}

///|
test "large text to hunks" {
  let old = [
      "alert", "chop", "brave", "arise", "bring", "boy", "answer", "count", "begin",
      "casual", "dot", "bottom",
    ][:]
  let new = [
      "alert", "chop", "brave", "arise", "bring", "joy", "answer", "count", "begin",
      "casual", "dot", "bottom",
    ][:]
  let d = @diff.Diff(old~, new~)
  inspect(
    edits_to_string(d),
    content=(
      #|  alert
      #|  chop
      #|  brave
      #|  arise
      #|  bring
      #|- boy
      #|+ joy
      #|  answer
      #|  count
      #|  begin
      #|  casual
      #|  dot
      #|  bottom
    ),
  )
  inspect(
    hunks_to_string(d.group()),
    content=(
      #|@@ -3,7 +3,7 @@
      #| brave
      #| arise
      #| bring
      #|-boy
      #|+joy
      #| answer
      #| count
      #| begin
      #|
    ),
  )
  inspect(
    hunks_to_string(d.group(radius=2)),
    content=(
      #|@@ -4,5 +4,5 @@
      #| arise
      #| bring
      #|-boy
      #|+joy
      #| answer
      #| count
      #|
    ),
  )
}

///|
test "diff with Int elements" {
  let old = [1, 2, 3, 4][:]
  let new = [1, 2, 4, 5][:]
  let d = @diff.Diff(old~, new~)
  inspect(
    edits_to_string(d),
    content=(
      #|  1
      #|  2
      #|- 3
      #|  4
      #|+ 5
    ),
  )
}

///|
test "diff with Bool elements" {
  let old = [true, false, false][:]
  let new = [true, false, true][:]
  let d = @diff.Diff(old~, new~)
  inspect(
    edits_to_string(d),
    content=(
      #|  true
      #|  false
      #|- false
      #|+ true
    ),
  )
}

///|
test "diff with struct elements" {
  let old = [
      { id: 1, name: "alice" },
      { id: 2, name: "bob" },
      { id: 3, name: "charlie" },
    ][:]
  let new = [
      { id: 1, name: "alice" },
      { id: 3, name: "charlie" },
      { id: 4, name: "david" },
    ][:]
  let d = @diff.Diff(old~, new~)
  inspect(
    edits_to_string(d),
    content=(
      #|  User { id: 1, name: alice }
      #|- User { id: 2, name: bob }
      #|  User { id: 3, name: charlie }
      #|+ User { id: 4, name: david }
    ),
  )
}

///|
test "diff with enum elements" {
  let old = [Start, Word("alpha"), Num(1), Stop][:]
  let new = [Start, Num(1), Word("beta"), Stop][:]
  let d = @diff.Diff(old~, new~)
  inspect(
    edits_to_string(d),
    content=(
      #|  Start
      #|- Word("alpha")
      #|  Num(1)
      #|+ Word("beta")
      #|  Stop
    ),
  )
}
