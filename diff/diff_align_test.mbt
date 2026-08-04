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

// Similarity-based line alignment with weighted intraline highlights, per the
// codex-reviewed design. All arithmetic is integer (weights x20, similarity
// in permille) so scores and tracebacks are bit-identical on every backend.

///|
priv enum TokKind {
  Word // identifiers and numbers
  Str // string literals and #|/$| raw-string lines
  Marker // the `///|` block separator
  Punct
  Comment // content tokens inside a // comment (tokenized, not opaque)
  Filler // comment boilerplate: the // marker and comment whitespace
  Space
} derive(Eq, @debug.Debug)

///|
priv struct Tok {
  kind : TokKind
  text : String
}

///|
fn weight(k : TokKind) -> Int {
  match k {
    Word | Str | Marker => 20
    Punct => 6
    Comment => 2
    Space => 1
    // filler carries no signal either way: shared `//` markers and comment
    // spacing must not make unrelated comments look similar
    Filler => 0
  }
}

///|
/// Tokenize the body of a `//` comment: same shapes as code tokens, but all
/// carry the low `Comment` weight, so similar comments pair while unrelated
/// ones do not — a whole comment is never one opaque cheap token.
fn push_comment_tokens(toks : Array[Tok], body : String) -> Unit {
  let mut rest = body.view()
  while rest is [_, ..] {
    rest = lexscan rest with longest {
      (re"^//+" as t, after=next) => {
        toks.push({ kind: Filler, text: t.to_owned() })
        next
      }
      (re"^[A-Za-z_][A-Za-z0-9_]*" as t, after=next) => {
        toks.push({ kind: Comment, text: t.to_owned() })
        next
      }
      (re"^[ \t]+" as t, after=next) => {
        toks.push({ kind: Filler, text: t.to_owned() })
        next
      }
      (re"^." as t, after=next) => {
        toks.push({ kind: Comment, text: t.to_string() })
        next
      }
      _ => abort("unreachable")
    }
  }
}

///|
/// Tokenize one line (no newline). Faithful: concatenating `text`s
/// reproduces the line. Rule order matters: `///|`, raw-string lines and
/// string literals are recognized before the `//` comment rule, so `//`
/// inside strings is never a comment.
fn tokenize_line(line : String) -> Array[Tok] {
  let toks : Array[Tok] = []
  // `///|` prefix must be handled before lexscan: under `longest` matching
  // the comment rule would otherwise swallow `///| x` whole.
  if line is ['/', '/', '/', '|', ..] {
    toks.push({ kind: Marker, text: "///|" })
    push_comment_tokens(toks, line.view(start_offset=4).to_owned())
    return toks
  }
  let mut rest = line.view()
  while rest is [_, ..] {
    rest = lexscan rest with longest {
      (re"^///\|" as t, after=next) => {
        toks.push({ kind: Marker, text: t.to_owned() })
        next
      }
      (re"^#\|[^\n]*" as t, after=next) => {
        toks.push({ kind: Str, text: t.to_owned() })
        next
      }
      (re"^\$\|[^\n]*" as t, after=next) => {
        toks.push({ kind: Str, text: t.to_owned() })
        next
      }
      (re"^\"(\\.|[^\"\\])*\"" as t, after=next) => {
        toks.push({ kind: Str, text: t.to_owned() })
        next
      }
      (re"^//[^\n]*" as t, after=next) => {
        push_comment_tokens(toks, t.to_owned())
        next
      }
      (re"^[A-Za-z_][A-Za-z0-9_]*" as t, after=next) => {
        toks.push({ kind: Word, text: t.to_owned() })
        next
      }
      (re"^[0-9]+" as t, after=next) => {
        toks.push({ kind: Word, text: t.to_owned() })
        next
      }
      (re"^[ \t]+" as t, after=next) => {
        toks.push({ kind: Space, text: t.to_owned() })
        next
      }
      (re"^." as t, after=next) => {
        toks.push({ kind: Punct, text: t.to_string() })
        next
      }
      _ => abort("unreachable")
    }
  }
  toks
}

///|
fn tok_mass(ts : ArrayView[Tok]) -> Int {
  let mut m = 0
  for t in ts {
    m += weight(t.kind)
  }
  m
}

///|
/// Substitution is offered only between same-kind tokens, at 1.5x the class
/// weight: cheaper than delete+insert (2x) so renames align, but expensive
/// enough that two lines with nothing in common score ~0.25, well below the
/// pairing threshold.
fn subst_cost(a : Tok, b : Tok) -> Int? {
  if a.kind == b.kind {
    if a.text == b.text {
      Some(0)
    } else {
      Some(weight(a.kind) * 3 / 2)
    }
  } else {
    None
  }
}

///|
/// Weighted token edit distance, rolling rows (scoring only).
fn wdist(a : ArrayView[Tok], b : ArrayView[Tok]) -> Int {
  let n = b.length()
  let mut prev = Array::makei(n + 1, j => if j == 0 { 0 } else { 0 })
  let mut j0 = 0
  for j in 1..<(n + 1) {
    j0 += weight(b[j - 1].kind)
    prev[j] = j0
  }
  let mut cur = Array::make(n + 1, 0)
  for i in 1..<(a.length() + 1) {
    cur[0] = prev[0] + weight(a[i - 1].kind)
    for j in 1..<(n + 1) {
      let del = prev[j] + weight(a[i - 1].kind)
      let ins = cur[j - 1] + weight(b[j - 1].kind)
      let mut best = if del < ins { del } else { ins }
      match subst_cost(a[i - 1], b[j - 1]) {
        Some(c) => if prev[j - 1] + c < best { best = prev[j - 1] + c }
        None => ()
      }
      cur[j] = best
    }
    let t = prev
    prev = cur
    cur = t
  }
  prev[b.length()]
}

///|
/// Similarity in permille: 1000 * (mass - dist) / mass over both sides.
fn sim_pm(a : ArrayView[Tok], b : ArrayView[Tok]) -> Int {
  let m = tok_mass(a) + tok_mass(b)
  if m == 0 {
    // zero semantic mass (empty or filler-only lines): there is no evidence
    // either way, so pair only textually identical lines.
    if a.length() != b.length() {
      return 0
    }
    for i in 0..<a.length() {
      if a[i].kind != b[i].kind || a[i].text != b[i].text {
        return 0
      }
    }
    return 1000
  }
  (m - wdist(a, b)) * 1000 / m
}

///|
const THETA : Int = 400 // pairing threshold, permille

///|
/// Monotone block alignment maximizing the total positive margin
/// sum(sim - THETA); a pair is only usable when its margin is > 0.
/// Deterministic: integer scores, stored backpointers, tie preference
/// diag > left > up (which yields delete-before-insert in forward order).
fn align(
  olds : Array[Array[Tok]],
  news : Array[Array[Tok]],
) -> Array[(Int?, Int?)] {
  let m = olds.length()
  let n = news.length()
  let dp = Array::makei(m + 1, _ => Array::make(n + 1, 0))
  let bp = Array::makei(m + 1, _ => Array::make(n + 1, 0)) // 1 diag, 2 left, 3 up
  for j in 1..<(n + 1) {
    bp[0][j] = 2
  }
  for i in 1..<(m + 1) {
    bp[i][0] = 3
    for j in 1..<(n + 1) {
      let margin = sim_pm(olds[i - 1][:], news[j - 1][:]) - THETA
      let mut best = dp[i][j - 1]
      let mut way = 2
      if dp[i - 1][j] > best {
        best = dp[i - 1][j]
        way = 3
      }
      if margin > 0 && dp[i - 1][j - 1] + margin >= best {
        best = dp[i - 1][j - 1] + margin
        way = 1
      }
      dp[i][j] = best
      bp[i][j] = way
    }
  }
  let out : Array[(Int?, Int?)] = []
  let mut i = m
  let mut j = n
  while i > 0 || j > 0 {
    match bp[i][j] {
      1 => {
        out.push((Some(i - 1), Some(j - 1)))
        i -= 1
        j -= 1
      }
      2 => {
        out.push((None, Some(j - 1)))
        j -= 1
      }
      _ => {
        out.push((Some(i - 1), None))
        i -= 1
      }
    }
  }
  out.rev_in_place()
  out
}

///|
priv enum Op {
  OEq(Tok)
  OSub(Tok, Tok)
  ODel(Tok)
  OIns(Tok)
}

///|
/// Full traceback for one aligned pair: the highlight script IS the scored
/// script. Fill-time preference: equal/substitution (diag) > insert (left)
/// > delete (up); backward left-before-up yields forward
/// delete-before-insert. Cross-kind substitution is not offered, so it
/// decomposes into delete+insert at equal cost.
fn pair_ops(a : Array[Tok], b : Array[Tok]) -> Array[Op] {
  let m = a.length()
  let n = b.length()
  let dp = Array::makei(m + 1, _ => Array::make(n + 1, 0))
  let bp = Array::makei(m + 1, _ => Array::make(n + 1, 0)) // 1 diag, 2 left, 3 up
  for j in 1..<(n + 1) {
    dp[0][j] = dp[0][j - 1] + weight(b[j - 1].kind)
    bp[0][j] = 2
  }
  for i in 1..<(m + 1) {
    dp[i][0] = dp[i - 1][0] + weight(a[i - 1].kind)
    bp[i][0] = 3
    for j in 1..<(n + 1) {
      let mut best = dp[i - 1][j] + weight(a[i - 1].kind) // delete
      let mut way = 3
      let ins = dp[i][j - 1] + weight(b[j - 1].kind)
      if ins <= best {
        best = ins
        way = 2
      }
      match subst_cost(a[i - 1], b[j - 1]) {
        Some(c) =>
          if dp[i - 1][j - 1] + c <= best {
            best = dp[i - 1][j - 1] + c
            way = 1
          }
        None => ()
      }
      dp[i][j] = best
      bp[i][j] = way
    }
  }
  let out : Array[Op] = []
  let mut i = m
  let mut j = n
  while i > 0 || j > 0 {
    match bp[i][j] {
      1 => {
        if a[i - 1].kind == b[j - 1].kind && a[i - 1].text == b[j - 1].text {
          out.push(OEq(a[i - 1]))
        } else {
          out.push(OSub(a[i - 1], b[j - 1]))
        }
        i -= 1
        j -= 1
      }
      2 => {
        out.push(OIns(b[j - 1]))
        j -= 1
      }
      _ => {
        out.push(ODel(a[i - 1]))
        i -= 1
      }
    }
  }
  out.rev_in_place()
  out
}

///|
/// Render one aligned pair's ops as the two row bodies (left = old side,
/// right = new side), merging adjacent highlighted tokens into single runs.
fn pair_row_html(ops : Array[Op]) -> (String, String) {
  let l = StringBuilder::new()
  let r = StringBuilder::new()
  let lrun = StringBuilder::new()
  let rrun = StringBuilder::new()
  fn flushes() {
    if !lrun.is_empty() {
      l <+ "<b class=\"wd\">\{lrun.to_string()}</b>"
      lrun.reset()
    }
    if !rrun.is_empty() {
      r <+ "<b class=\"wa\">\{rrun.to_string()}</b>"
      rrun.reset()
    }
  }

  for op in ops {
    match op {
      OEq(t) => {
        flushes()
        l <+ "\{esc(t.text)}"
        r <+ "\{esc(t.text)}"
      }
      OSub(a, b) => {
        lrun <+ "\{esc(a.text)}"
        rrun <+ "\{esc(b.text)}"
      }
      ODel(a) => lrun <+ "\{esc(a.text)}"
      OIns(b) => rrun <+ "\{esc(b.text)}"
    }
  }
  flushes()
  (l.to_string(), r.to_string())
}

///|
test "tokenizer: markers, strings, raw lines, comments, faithfulness" {
  // ///| is a full-weight structural marker, not comment content
  @debug.debug_inspect(tokenize_line("///|")[0].kind, content="Marker")
  // // inside a string literal is not a comment
  let toks = tokenize_line("let s = \"a//b\" // real comment")
  @debug.debug_inspect(
    toks.filter(t => t.kind is Str).map(t => t.text),
    content=(
      #|["\"a//b\""]
    ),
  )
  inspect(toks.filter(t => t.kind is Comment).length() > 0, content="true")
  // raw-string lines are one Str token
  @debug.debug_inspect(tokenize_line("#|x // y")[0].kind, content="Str")
  // faithfulness, including Unicode fallbacks
  for
    line in ["let 名 = 'é😀'", "  a\tb  // ok", "///| x", "\"unterminated"] {
    assert_eq(tokenize_line(line).map(t => t.text).join(""), line)
  }
}

///|
test "similarity: comments help but cannot veto; unrelated stays unpaired" {
  fn sim(a : String, b : String) -> Int {
    sim_pm(tokenize_line(a), tokenize_line(b))
  }
  // similar pure-comment edits pair
  inspect(sim("// add tax", "// add the tax") > THETA, content="true")
  // unrelated pure comments do not
  inspect(
    sim("// promoted; output is not", "// totally different topic here") < THETA,
    content="true",
  )
  // code identical, comment rewritten: pairs strongly
  inspect(sim("let x = 1 // sum", "let x = 1 // total") > 900, content="true")
  // comment as tie-breaker: identical comment scores higher
  inspect(
    sim("let x = 1 // a", "let x = 1 // a") >
    sim("let x = 1 // a", "let x = 1 // b"),
    content="true",
  )
  // two lines with nothing in common: same-kind substitutions alone must not
  // reach the threshold (the flat-cost trap codex flagged)
  inspect(
    sim("alpha beta gamma delta eps", "one two three four five") < THETA,
    content="true",
  )
  // respacing pairs easily (space weight is tiny)
  inspect(sim("f(a,b)", "f( a , b )") > 800, content="true")
  // the real_world.html defect pair must not align
  inspect(
    sim(
      "// promoted; `output` is not (use the trait or string interpolation).", "pub extend DiffAlgorithm with Eq::{equal}",
    ) <
    THETA,
    content="true",
  )
}

///|
test "alignment: strong pair beats crossing weak pairs; gaps ordered del-first" {
  let olds = ["unrelated_one thing", "let total = price * count"].map(
    tokenize_line,
  )
  let news = ["let total = price * count + tax", "other_stuff entirely"].map(
    tokenize_line,
  )
  // monotone: the strong pair (1,0) forces line 0 old to be a gap-delete and
  // line 1 new to be a gap-insert; no weak crossing pair may win.
  @debug.debug_inspect(
    align(olds, news),
    content="[(Some(0), None), (Some(1), Some(0)), (None, Some(1))]",
  )
  // fully unrelated block: delete rows come before insert rows
  let a = ["aaa bbb ccc"].map(tokenize_line)
  let b = ["xxx yyy zzz"].map(tokenize_line)
  @debug.debug_inspect(
    align(a, b),
    content="[(Some(0), None), (None, Some(0))]",
  )
}

///|
test "pair_ops reconstruction property" {
  for
    pair in [
      ("let total = a", "let sum = a"),
      ("f(x, 1)", "g(x, 2)"),
      ("let 名 = 'é😀' // c", "let 名 = 'z' // d"),
      ("", "only new"),
    ] {
    let (oa, ob) = pair
    let ta = tokenize_line(oa)
    let tb = tokenize_line(ob)
    let left = StringBuilder::new()
    let right = StringBuilder::new()
    for op in pair_ops(ta, tb) {
      match op {
        OEq(t) => {
          left <+ "\{t.text}"
          right <+ "\{t.text}"
        }
        OSub(a, b) => {
          left <+ "\{a.text}"
          right <+ "\{b.text}"
        }
        ODel(a) => left <+ "\{a.text}"
        OIns(b) => right <+ "\{b.text}"
      }
    }
    assert_eq(left.to_string(), oa)
    assert_eq(right.to_string(), ob)
  }
}

///|
test "zero-mass lines pair only when identical" {
  fn sim(a : String, b : String) -> Int {
    sim_pm(tokenize_line(a), tokenize_line(b))
  }
  inspect(sim("//", "") == 0, content="true")
  inspect(sim("//", "//   ") == 0, content="true")
  inspect(sim("", "") == 1000, content="true")
  inspect(sim("//", "//") == 1000, content="true")
}

///|
test "marker classification survives trailing content" {
  @debug.debug_inspect(tokenize_line("///| x")[0].kind, content="Marker")
  assert_eq(tokenize_line("///| x").map(t => t.text).join(""), "///| x")
}

///|
test "alignment objective is positive margin, not raw similarity or pair count" {
  // A ~ Y (one word changed, sim ~ 910): the strong pair.
  // A ~ X and B ~ Y (four words changed each, sim ~ 640): two moderate pairs.
  // Raw-similarity or pair-count maximization would take the two moderate
  // diagonal pairs (~1280 total); the margin objective must take the single
  // strong pair (margin ~ 510 beats ~ 240+240).
  let a = "alpha beta gamma delta epsilon zeta eta theta"
  let y = "alpha beta gamma delta epsilon zeta eta CHANGED"
  let x = "alpha beta gamma delta ONE TWO THREE FOUR"
  let b = "FIVE SIX SEVEN EIGHT epsilon zeta eta CHANGED"
  let olds = [a, b].map(tokenize_line)
  let news = [x, y].map(tokenize_line)
  @debug.debug_inspect(
    align(olds, news),
    content="[(None, Some(0)), (Some(0), Some(1)), (Some(1), None)]",
  )
}
