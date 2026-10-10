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
let profile : @re.Profile = Profile(
  valid=@re.RecharSet::char_range(0, 0x10FFFF),
  word=@re.RecharSet::char_range('a', 'z') +
    @re.RecharSet::char_range('A', 'Z') +
    @re.RecharSet::char_range('0', '9') +
    @re.RecharSet::char('_'),
  category=c => {
    match c {
      'a'..='z' | 'A'..='Z' | '0'..='9' | '_' => @re.Category::word()
      '\n' => @re.Category::newline()
      _ => @re.Category::not_word()
    }
  },
)

///|
// Two independent rolling digests retain the pre-migration capture results
// without retaining the derivative implementation as a test dependency.
// Baseline: cf510ca6, before string.Regex switched to the tagged engine.
priv struct CaptureDigest {
  mut first : UInt
  mut second : UInt
  mut count : Int
}

///|
fn CaptureDigest::feed(self : CaptureDigest, value : Int) -> Unit {
  let value = value.reinterpret_as_uint()
  self.first = (self.first ^ value) * 16777619U
  self.second = (self.second + value) * 2246822519U + 3266489917U
  self.count += 1
}

///|
fn CaptureDigest::record(self : CaptureDigest, group : (Int, Int)??) -> Unit {
  match group {
    None => self.feed(-3)
    Some(None) => self.feed(-2)
    Some(Some((start, end))) => {
      self.feed(-1)
      self.feed(start)
      self.feed(end)
    }
  }
}

///|
test "ordered captures preserve pre-migration results" {
  let a = @re.char(@re.RecharSet::char('a'))
  let b = @re.char(@re.RecharSet::char('b'))
  let empty_a = @re.quantifier(a, { min: 0, max: None, mode: Greedy, })
  let nongreedy_a = @re.quantifier(a, { min: 0, max: None, mode: NonGreedy, })
  let pats = [
    @re.epsilon,
    @re.empty,
    a,
    @re.capture(a),
    @re.seq([@re.capture(empty_a), @re.capture(empty_a)]),
    @re.seq([@re.capture(nongreedy_a), @re.capture(empty_a)]),
    @re.alt([@re.capture(a), @re.capture(a)]),
    @re.quantifier(@re.capture(a), { min: 0, max: None, mode: Greedy, }),
    @re.quantifier(@re.capture(empty_a), { min: 0, max: None, mode: Greedy, }),
    @re.quantifier(@re.capture(empty_a), { min: 0, max: None, mode: NonGreedy, }),
    @re.quantifier(@re.capture(@re.alt([a, @re.seq([a, b])])), {
      min: 0,
      max: None,
      mode: Greedy,
    }),
    @re.seq([
      @re.quantifier(@re.capture(a), { min: 0, max: Some(3), mode: Greedy, }),
      @re.capture(empty_a),
    ]),
    @re.seq([@re.capture(@re.alt([a, @re.epsilon])), @re.capture(b)]),
    @re.seq([
      @re.start_of_input,
      @re.capture(empty_a),
      @re.capture(@re.quantifier(b, { min: 0, max: None, mode: Greedy, })),
      @re.end_of_input,
    ]),
    @re.seq([@re.start_of_word, @re.capture(a), @re.end_of_word]),
    @re.seq([@re.start_of_line, @re.capture(a), @re.end_of_line]),
    @re.seq([@re.capture(a), @re.not_word_boundary, @re.capture(b)]),
  ]
  // Deterministic mixed nested captures, alternatives and nullable quantifiers.
  let seed : FixedArray[Int] = [7]
  fn pick(n : Int) -> Int {
    seed[0] = seed[0] * 1103515245 + 12345
    ((seed[0] >> 16) & 0x7FFF) % n
  }
  fn generate(depth : Int) -> @re.Pattern {
    if depth == 0 {
      return match pick(4) {
        0 => a
        1 => b
        2 => @re.epsilon
        _ => @re.empty
      }
    }
    match pick(7) {
      0 => @re.capture(generate(depth - 1))
      1 => @re.seq([generate(depth - 1), generate(depth - 1)])
      2 => @re.alt([generate(depth - 1), generate(depth - 1)])
      3 => @re.first(generate(depth - 1))
      4 =>
        @re.seq([
          match pick(5) {
            0 => @re.start_of_word
            1 => @re.end_of_word
            2 => @re.not_word_boundary
            3 => @re.start_of_input
            _ => @re.end_of_input
          },
          generate(depth - 1),
        ])
      _ => {
        let min = pick(2)
        let max = if pick(2) == 0 { None } else { Some(min + pick(3)) }
        let mode : @re.QuantifierMode = if pick(2) == 0 {
          Greedy
        } else {
          NonGreedy
        }
        @re.quantifier(generate(depth - 1), { min, max, mode, })
      }
    }
  }
  for _ in 0..<200 {
    pats.push(generate(3))
  }
  let inputs = ["", "éa", "\na\n", "a!", "!a", "a\u{1F600}"]
  for length in 1..<=5 {
    let count = 1 << (2 * length)
    for code in 0..<count {
      let sb = StringBuilder()
      let mut rest = code
      for _ in 0..<length {
        sb.write_char(
          match rest & 3 {
            0 => 'a'
            1 => 'b'
            2 => '!'
            _ => '\n'
          },
        )
        rest = rest >> 2
      }
      inputs.push(sb.to_string())
    }
  }
  let digests : Array[(UInt, UInt, Int)] = []
  for pat in pats {
    let digest = { first: 2166136261U, second: 2654435769U, count: 0, }
    let tagged = @re.compile(profile~, pat)
    for input in inputs {
      for offset in 0..<=input.length() {
        // Repeat after different inputs to detect stale register/candidate state.
        for _ in 0..<2 {
          let actual = tagged.execute(input, offset)
          for group in 0..<=tagged.group_names().length() {
            let actual_group = actual.map(m => m.group(group))
            digest.record(actual_group)
          }
        }
      }
    }
    digests.push((digest.first, digest.second, digest.count))
  }
  @debug.debug_inspect(
    digests,
    content=(
      #|[
      #|  (151054465, 2145916029, 62032),
      #|  (781902973, 691822841, 31016),
      #|  (2089389969, 380746493, 44524),
      #|  (3207698499, 3831905745, 73540),
      #|  (178110017, 2503762269, 155080),
      #|  (1276063025, 3618297093, 155080),
      #|  (896180141, 1116027673, 89048),
      #|  (4021007145, 724635529, 83932),
      #|  (3890385001, 4146312825, 108556),
      #|  (3748631573, 1004529593, 77540),
      #|  (4021007145, 724635529, 83932),
      #|  (3830010401, 1911744321, 130456),
      #|  (1550426717, 840991199, 102460),
      #|  (2064195437, 1296883295, 62284),
      #|  (2708354003, 3280872529, 58564),
      #|  (847099591, 4098826977, 51508),
      #|  (2983166329, 3908228737, 70816),
      #|  (3734337573, 3846490279, 62032),
      #|  (3207698499, 3831905745, 73540),
      #|  (676980729, 2227274393, 46524),
      #|  (2184939917, 332691145, 57484),
      #|  (3575803313, 2304020749, 32380),
      #|  (151054465, 2145916029, 62032),
      #|  (2895867133, 293104505, 37928),
      #|  (2003576641, 1485344241, 62032),
      #|  (676980729, 2227274393, 46524),
      #|  (4102029227, 761952833, 77540),
      #|  (151054465, 2145916029, 62032),
      #|  (648046133, 3043039289, 62032),
      #|  (781902973, 691822841, 31016),
      #|  (2505154031, 1501574529, 64404),
      #|  (151054465, 2145916029, 62032),
      #|  (2089389969, 380746493, 44524),
      #|  (1135250713, 3246729465, 108556),
      #|  (3748631573, 1004529593, 77540),
      #|  (676980729, 2227274393, 46524),
      #|  (151054465, 2145916029, 62032),
      #|  (781902973, 691822841, 31016),
      #|  (1317722127, 4238255425, 131444),
      #|  (4272857309, 4140961949, 47152),
      #|  (781902973, 691822841, 31016),
      #|  (151054465, 2145916029, 62032),
      #|  (781902973, 691822841, 31016),
      #|  (3197443389, 1253059817, 87148),
      #|  (676980729, 2227274393, 46524),
      #|  (3639361341, 1380279241, 108556),
      #|  (3207698499, 3831905745, 73540),
      #|  (343201073, 2717892273, 44492),
      #|  (1924452291, 1391334033, 73476),
      #|  (2003576641, 1485344241, 62032),
      #|  (676980729, 2227274393, 46524),
      #|  (3196132461, 1453012909, 102460),
      #|  (2003576641, 1485344241, 62032),
      #|  (532894637, 1136536009, 108556),
      #|  (151054465, 2145916029, 62032),
      #|  (151054465, 2145916029, 62032),
      #|  (781902973, 691822841, 31016),
      #|  (1924452291, 1391334033, 73476),
      #|  (2505154031, 1501574529, 64404),
      #|  (1924452291, 1391334033, 73476),
      #|  (3039482725, 215773257, 108556),
      #|  (1616443705, 724490969, 52380),
      #|  (4233075661, 1583863349, 88948),
      #|  (470645105, 2241001917, 44492),
      #|  (676980729, 2227274393, 46524),
      #|  (4233075661, 1583863349, 88948),
      #|  (3207698499, 3831905745, 73540),
      #|  (781902973, 691822841, 31016),
      #|  (151054465, 2145916029, 62032),
      #|  (151054465, 2145916029, 62032),
      #|  (1226135293, 4133108649, 131572),
      #|  (781902973, 691822841, 31016),
      #|  (3639361341, 1380279241, 108556),
      #|  (676980729, 2227274393, 46524),
      #|  (151054465, 2145916029, 62032),
      #|  (3748631573, 1004529593, 77540),
      #|  (374767889, 745335497, 80044),
      #|  (151054465, 2145916029, 62032),
      #|  (3735833689, 498672827, 56556),
      #|  (3207698499, 3831905745, 73540),
      #|  (3748631573, 1004529593, 77540),
      #|  (4068432673, 2408841245, 155080),
      #|  (3749191421, 1983234541, 36496),
      #|  (151054465, 2145916029, 62032),
      #|  (676980729, 2227274393, 46524),
      #|  (3207698499, 3831905745, 73540),
      #|  (470645105, 2241001917, 44492),
      #|  (151054465, 2145916029, 62032),
      #|  (151054465, 2145916029, 62032),
      #|  (151054465, 2145916029, 62032),
      #|  (343201073, 2717892273, 44492),
      #|  (151054465, 2145916029, 62032),
      #|  (151054465, 2145916029, 62032),
      #|  (3017458081, 4092821849, 105832),
      #|  (3748631573, 1004529593, 77540),
      #|  (3748631573, 1004529593, 77540),
      #|  (2003576641, 1485344241, 62032),
      #|  (2003576641, 1485344241, 62032),
      #|  (1917340525, 1136652307, 32676),
      #|  (151054465, 2145916029, 62032),
      #|  (676980729, 2227274393, 46524),
      #|  (1817868919, 3601398177, 49268),
      #|  (3749191421, 1983234541, 36496),
      #|  (3748631573, 1004529593, 77540),
      #|  (3748631573, 1004529593, 77540),
      #|  (676980729, 2227274393, 46524),
      #|  (676980729, 2227274393, 46524),
      #|  (3748631573, 1004529593, 77540),
      #|  (574912721, 1186559577, 73088),
      #|  (180254313, 535211865, 46876),
      #|  (676980729, 2227274393, 46524),
      #|  (2964062683, 2808412993, 60000),
      #|  (151054465, 2145916029, 62032),
      #|  (1132464121, 642944477, 44492),
      #|  (3842078153, 3446238617, 54748),
      #|  (781902973, 691822841, 31016),
      #|  (2168651833, 145268185, 52380),
      #|  (4272857309, 4140961949, 47152),
      #|  (676980729, 2227274393, 46524),
      #|  (781902973, 691822841, 31016),
      #|  (151054465, 2145916029, 62032),
      #|  (3748631573, 1004529593, 77540),
      #|  (1803059309, 2540755865, 124064),
      #|  (151054465, 2145916029, 62032),
      #|  (2887863941, 4084461689, 102656),
      #|  (3639361341, 1380279241, 108556),
      #|  (781902973, 691822841, 31016),
      #|  (151054465, 2145916029, 62032),
      #|  (4021007145, 724635529, 83932),
      #|  (2323630101, 2729372069, 56640),
      #|  (4272857309, 4140961949, 47152),
      #|  (3329378705, 2822399345, 44524),
      #|  (2456496081, 2213386825, 51620),
      #|  (648046133, 3043039289, 62032),
      #|  (3748631573, 1004529593, 77540),
      #|  (3639361341, 1380279241, 108556),
      #|  (2191358023, 1560869777, 97604),
      #|  (781902973, 691822841, 31016),
      #|  (3749191421, 1983234541, 36496),
      #|  (3748479719, 2744535793, 83932),
      #|  (3196132461, 1453012909, 102460),
      #|  (532894637, 1136536009, 108556),
      #|  (360266585, 1596747941, 39956),
      #|  (3748631573, 1004529593, 77540),
      #|  (151054465, 2145916029, 62032),
      #|  (3749191421, 1983234541, 36496),
      #|  (151054465, 2145916029, 62032),
      #|  (3639361341, 1380279241, 108556),
      #|  (2003576641, 1485344241, 62032),
      #|  (3206712541, 2721509869, 102556),
      #|  (3173559129, 2539387629, 62032),
      #|  (1868782385, 2580636887, 44524),
      #|  (781902973, 691822841, 31016),
      #|  (2928620851, 2503654673, 73476),
      #|  (3748631573, 1004529593, 77540),
      #|  (2242366447, 4239084193, 55496),
      #|  (1547201161, 1576618725, 39988),
      #|  (3749191421, 1983234541, 36496),
      #|  (676980729, 2227274393, 46524),
      #|  (676980729, 2227274393, 46524),
      #|  (151054465, 2145916029, 62032),
      #|  (676980729, 2227274393, 46524),
      #|  (2505154031, 1501574529, 64404),
      #|  (884017497, 1500992521, 47372),
      #|  (781902973, 691822841, 31016),
      #|  (648046133, 3043039289, 62032),
      #|  (1581942833, 2553541881, 52004),
      #|  (3196132461, 1453012909, 102460),
      #|  (3207698499, 3831905745, 73540),
      #|  (3845059731, 1851088465, 71172),
      #|  (151054465, 2145916029, 62032),
      #|  (3207698499, 3831905745, 73540),
      #|  (470645105, 2241001917, 44492),
      #|  (532894637, 1136536009, 108556),
      #|  (7200505, 1125712257, 70816),
      #|  (781902973, 691822841, 31016),
      #|  (151054465, 2145916029, 62032),
      #|  (676980729, 2227274393, 46524),
      #|  (3639361341, 1380279241, 108556),
      #|  (2003576641, 1485344241, 62032),
      #|  (151054465, 2145916029, 62032),
      #|  (3207698499, 3831905745, 73540),
      #|  (3173559129, 2539387629, 62032),
      #|  (3272588265, 4181403065, 52380),
      #|  (781902973, 691822841, 31016),
      #|  (2982838661, 167639549, 46512),
      #|  (4272857309, 4140961949, 47152),
      #|  (360266585, 1596747941, 39956),
      #|  (3748631573, 1004529593, 77540),
      #|  (151054465, 2145916029, 62032),
      #|  (151054465, 2145916029, 62032),
      #|  (2089389969, 380746493, 44524),
      #|  (1813920761, 3592009161, 77540),
      #|  (781902973, 691822841, 31016),
      #|  (998479805, 1401301273, 56640),
      #|  (781902973, 691822841, 31016),
      #|  (151054465, 2145916029, 62032),
      #|  (4272857309, 4140961949, 47152),
      #|  (591413133, 3816422953, 66836),
      #|  (781902973, 691822841, 31016),
      #|  (1138557551, 2403710705, 100800),
      #|  (3734337573, 3846490279, 62032),
      #|  (4286607849, 1215986821, 62032),
      #|  (3748631573, 1004529593, 77540),
      #|  (4272857309, 4140961949, 47152),
      #|  (4272857309, 4140961949, 47152),
      #|  (7660433, 642835691, 152336),
      #|  (3639361341, 1380279241, 108556),
      #|  (3173559129, 2539387629, 62032),
      #|  (3748631573, 1004529593, 77540),
      #|  (1389920705, 3699800313, 62032),
      #|  (1389920705, 3699800313, 62032),
      #|  (2323630101, 2729372069, 56640),
      #|  (676980729, 2227274393, 46524),
      #|  (323040181, 2489690809, 82768),
      #|  (1924452291, 1391334033, 73476),
      #|  (2598412069, 1372297381, 56556),
      #|]
    ),
  )
}

///|
test "UTF-16 lowering preserves pre-migration results" {
  let patterns = [
    ".", "(.)*", "(.+?)(.*)", "(😀|.)+", "[\u{10000}-\u{10FFFF}]+", "[\u{D7FF}-\u{E000}]",
    "[^a]*", "\\b(.)*\\b", "\\B", "^(.?)*$", "(a|(😀)?)*", "((a?)*)*", "(?<x>.*?)(.*)",
  ]
  let inputs = ["", "a", "aa", "😀", "a😀!", "😀😀", "éa\n😀", "!a!"]
  let digests : Array[(UInt, UInt, Int)] = []
  for pattern in patterns {
    let digest = { first: 2166136261U, second: 2654435769U, count: 0, }
    let current = try! Regex(pattern)
    for input in inputs {
      // Exercise views whose backing strings have a different start offset.
      let backed = "xx" + input + "yy"
      let view = backed[2:2 + input.length()]
      for offset in 0..<=view.length() {
        let actual = current.execute(view, last_index=offset)
        for group in 0..<8 {
          digest.record(
            actual.map(m => {
              m
              .group(group)
              .map(g => {
                let start = g.start_offset() - view.start_offset()
                (start, start + g.length())
              })
            }),
          )
        }
      }
    }
    digests.push((digest.first, digest.second, digest.count))
  }
  @debug.debug_inspect(
    digests,
    content=(
      #|[
      #|  (704941473, 380285787, 268),
      #|  (1986000585, 251064007, 322),
      #|  (1336168747, 3806623785, 340),
      #|  (268088700, 889494306, 304),
      #|  (3346994579, 767978409, 252),
      #|  (2160676285, 651702009, 232),
      #|  (337494008, 449931258, 290),
      #|  (75337786, 1756142456, 272),
      #|  (1460960977, 1382813155, 284),
      #|  (2987372416, 1568983398, 264),
      #|  (737407392, 675884760, 360),
      #|  (2292416985, 2806099525, 406),
      #|  (3629061516, 2234483438, 406),
      #|]
    ),
  )
}

///|
test "cached transitions preserve captures across inputs and views" {
  let a = @re.char(@re.RecharSet::char('a'))
  let q = @re.quantifier(a, { min: 0, max: None, mode: Greedy, })
  let pat = @re.seq([
    @re.start_of_input,
    @re.capture(q),
    @re.capture(q),
    @re.capture(q),
    @re.end_of_input,
  ])
  let tagged = @re.compile(profile~, pat)
  for input in ["a", "aaaa", "", "aaaaa", "b", "aa", "aaaa"] {
    for i in 0..<=3 {
      @test.assert_eq(
        tagged.execute(input, 0).map(m => m.group(i)),
        if input == "b" {
          None
        } else {
          Some(
            Some(
              if i <= 1 {
                (0, input.length())
              } else {
                (input.length(), input.length())
              },
            ),
          )
        },
      )
    }
  }
  for _ in 0..<100 {
    ignore(tagged.execute("aaaa", 0))
  }
  let view : StringView = "xxaaaayy"[2:6]
  for i in 0..<=3 {
    @test.assert_eq(
      tagged.execute(view, 0).map(m => m.group(i)),
      Some(Some(if i <= 1 { (0, 4) } else { (4, 4) })),
    )
  }
}
