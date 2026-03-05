///|
fn[T : Show] edits_to_string(
  old~ : MutArrayView[T],
  new~ : MutArrayView[T],
  edits : Array[@myers.Edit],
) -> String {
  let lines = Array::new()
  for edit in edits {
    match edit {
      Equal(old_index~, len~, ..) =>
        for i in old_index..<(old_index + len) {
          lines.push(" " + old[i].to_string())
        }
      Delete(old_index~, old_len~, ..) =>
        for i in old_index..<(old_index + old_len) {
          lines.push("-" + old[i].to_string())
        }
      Insert(new_index~, new_len~, ..) =>
        for i in new_index..<(new_index + new_len) {
          lines.push("+" + new[i].to_string())
        }
    }
  }
  lines.join("\n")
}

///|
fn[T : Show] hunks_to_string(
  old~ : MutArrayView[T],
  new~ : MutArrayView[T],
  hunks : Array[Array[@myers.Edit]],
) -> String {
  let lines = Array::new()
  for hunk in hunks {
    lines.push(@myers.HunkHeader::new(hunk).to_string())
    for edit in hunk {
      match edit {
        Equal(old_index~, len~, ..) =>
          for i in old_index..<(old_index + len) {
            lines.push(" " + old[i].to_string())
          }
        Delete(old_index~, old_len~, ..) =>
          for i in old_index..<(old_index + old_len) {
            lines.push("-" + old[i].to_string())
          }
        Insert(new_index~, new_len~, ..) =>
          for i in new_index..<(new_index + new_len) {
            lines.push("+" + new[i].to_string())
          }
      }
    }
  }
  lines.join("\n")
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
  ].mut_view()
  let new = [
    "apple", "pineapple", "banana", "tomato", "carrot", "tomato", "potato", "cabbage",
  ].mut_view()
  assert_eq(old, new)
  let edits = @myers.plain_diff(old~, new~)
  inspect(
    edits_to_string(old~, new~, edits),
    content=(
      #| apple
      #| pineapple
      #| banana
      #| tomato
      #| carrot
      #| tomato
      #| potato
      #| cabbage
    ),
  )
}

///|
test "mixed" {
  let old = ["carrot", "tomato", "potato", "cabbage"].mut_view()
  let new = ["apple", "banana", "tomato", "pineapple"].mut_view()
  let edits = @myers.plain_diff(old~, new~)
  inspect(
    edits_to_string(old~, new~, edits),
    content=(
      #|-carrot
      #|+apple
      #|+banana
      #| tomato
      #|-potato
      #|-cabbage
      #|+pineapple
    ),
  )
}

///|
test "delete then insert to hunks" {
  let old = ["fn main() {", "  println(\"foo\")", "}"].mut_view()
  let new = ["fn main() {", "  println(\"bar\")", "}"].mut_view()
  let edits = @myers.plain_diff(old~, new~)
  inspect(
    edits_to_string(old~, new~, edits),
    content=(
      #| fn main() {
      #|-  println("foo")
      #|+  println("bar")
      #| }
    ),
  )
  inspect(
    hunks_to_string(old~, new~, @myers.group_edits(edits)),
    content=(
      #|@@ -1,3 +1,3 @@
      #| fn main() {
      #|-  println("foo")
      #|+  println("bar")
      #| }
    ),
  )
}

///|
test "large text to hunks" {
  let old = [
    "alert", "chop", "brave", "arise", "bring", "boy", "answer", "count", "begin",
    "casual", "dot", "bottom",
  ].mut_view()
  let new = [
    "alert", "chop", "brave", "arise", "bring", "joy", "answer", "count", "begin",
    "casual", "dot", "bottom",
  ].mut_view()
  let edits = @myers.plain_diff(old~, new~)
  inspect(
    edits_to_string(old~, new~, edits),
    content=(
      #| alert
      #| chop
      #| brave
      #| arise
      #| bring
      #|-boy
      #|+joy
      #| answer
      #| count
      #| begin
      #| casual
      #| dot
      #| bottom
    ),
  )
  inspect(
    hunks_to_string(old~, new~, @myers.group_edits(edits)),
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
    ),
  )
  inspect(
    hunks_to_string(old~, new~, @myers.group_edits(edits, radius=2)),
    content=(
      #|@@ -4,5 +4,5 @@
      #| arise
      #| bring
      #|-boy
      #|+joy
      #| answer
      #| count
    ),
  )
}

///|
test "plain_diff with Int elements" {
  let old = [1, 2, 3, 4].mut_view()
  let new = [1, 2, 4, 5].mut_view()
  let edits = @myers.plain_diff(old~, new~)
  inspect(
    edits_to_string(old~, new~, edits),
    content=(
      #| 1
      #| 2
      #|-3
      #| 4
      #|+5
    ),
  )
}

///|
test "plain_diff with Bool elements" {
  let old = [true, false, false].mut_view()
  let new = [true, false, true].mut_view()
  let edits = @myers.plain_diff(old~, new~)
  inspect(
    edits_to_string(old~, new~, edits),
    content=(
      #| true
      #| false
      #|-false
      #|+true
    ),
  )
}

///|
test "plain_diff with struct elements" {
  let old = [
    { id: 1, name: "alice" },
    { id: 2, name: "bob" },
    { id: 3, name: "charlie" },
  ].mut_view()
  let new = [
    { id: 1, name: "alice" },
    { id: 3, name: "charlie" },
    { id: 4, name: "david" },
  ].mut_view()
  let edits = @myers.plain_diff(old~, new~)
  inspect(
    edits_to_string(old~, new~, edits),
    content=(
      #| User { id: 1, name: alice }
      #|-User { id: 2, name: bob }
      #| User { id: 3, name: charlie }
      #|+User { id: 4, name: david }
    ),
  )
}

///|
test "plain_diff with enum elements" {
  let old = [Start, Word("alpha"), Num(1), Stop].mut_view()
  let new = [Start, Num(1), Word("beta"), Stop].mut_view()
  let edits = @myers.plain_diff(old~, new~)
  inspect(
    edits_to_string(old~, new~, edits),
    content=(
      #| Start
      #|-Word("alpha")
      #| Num(1)
      #|+Word("beta")
      #| Stop
    ),
  )
}
