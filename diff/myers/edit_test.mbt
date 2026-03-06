///|
test "group_edits handles empty edits" {
  debug_inspect(
    @myers.group_edits([]),
    content=(
      #|[]
    ),
  )
}

///|
test "group_edits splits long equal blocks into multiple hunks" {
  let edits : Array[@myers.Edit] = [
    Delete(old_index=0, new_index=0, old_len=1),
    Equal(old_index=1, new_index=0, len=10),
    Insert(old_index=11, new_index=10, new_len=2),
  ]
  debug_inspect(
    @myers.group_edits(edits),
    content=(
      #|[
      #|  [
      #|    Delete(old_index=0, new_index=0, old_len=1),
      #|    Equal(old_index=1, new_index=0, len=3),
      #|  ],
      #|  [
      #|    Equal(old_index=8, new_index=7, len=3),
      #|    Insert(old_index=11, new_index=10, new_len=2),
      #|  ],
      #|]
    ),
  )
}

///|
test "range display for single and empty span" {
  inspect(
    @myers.HunkHeader::new([Equal(old_index=4, new_index=2, len=1)]).to_string(),
    content="@@ -5 +3 @@",
  )
  inspect(
    @myers.HunkHeader::new([Insert(old_index=4, new_index=2, new_len=1)]).to_string(),
    content="@@ -4,0 +3 @@",
  )
}
