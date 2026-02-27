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
test "execute/non_capture_group" {
  let regex = @string.Regex("(?:ab)(c)(?:d)")
  guard regex.execute("abcd") is Some(m) else { fail("Expected match") }
  debug_inspect(
    m,
    content=(
      #|{
      #|  input: <StringView: "abcd">,
      #|  group_names: <ReadOnlyArray: [None, None]>,
      #|  result: MatchResult([0, 4, 2, 3]),
      #|}
    ),
  )
}

///|
test "execute/non_capture_with_named_group" {
  let regex = @string.Regex("(?:a)(b)(?:c)(?<d>d)")
  guard regex.execute("abcd") is Some(m) else { fail("Expected match") }
  debug_inspect(
    m,
    content=(
      #|{
      #|  input: <StringView: "abcd">,
      #|  group_names: <ReadOnlyArray: [None, None, Some("d")]>,
      #|  result: MatchResult([0, 4, 1, 2, 3, 4]),
      #|}
    ),
  )
}

///|
test "execute/any_char_on_supplementary_plane" {
  let regex = @string.Regex(".")
  guard regex.execute("😀") is Some(m) else {
    fail("Expected match for supplementary-plane Unicode escape")
  }
  debug_inspect(
    m,
    content=(
      #|{
      #|  input: <StringView: "😀">,
      #|  group_names: <ReadOnlyArray: [None]>,
      #|  result: MatchResult([0, 2]),
      #|}
    ),
  )
}

///|
test "execute/range_crossing_surrogate_gap_has_no_half_match" {
  let regex = @string.Regex("[\\uD7FF-\\uE000]")
  guard regex.execute("😀") is None else {
    fail("Expected no surrogate-half match")
  }
}

///|
test "compile/error_unclosed_group" {
  guard (try? @string.Regex("(")) is Err(_) else {
    fail("Expected compile failure for unclosed group")
  }
}

///|
test "compile/error_unclosed_char_class" {
  guard (try? @string.Regex("[abc")) is Err(_) else {
    fail("Expected compile failure for unclosed char class")
  }
}

///|
test "compile/unicode_escape_supplementary_plane" {
  let regex = @string.Regex("\\u{1F600}")
  guard regex.execute("a😀b") is Some(m) else {
    fail("Expected match for supplementary-plane Unicode escape")
  }
  debug_inspect(
    m,
    content=(
      #|{
      #|  input: <StringView: "a😀b">,
      #|  group_names: <ReadOnlyArray: [None]>,
      #|  result: MatchResult([1, 3]),
      #|}
    ),
  )
}

///|
test "string/literal_metacharacters" {
  let regex = @string.Regex::string("a+b(c)")
  guard regex.execute("xa+b(c)y") is Some(m) else {
    fail("Expected literal match")
  }
  debug_inspect(
    m,
    content=(
      #|{
      #|  input: <StringView: "xa+b(c)y">,
      #|  group_names: <ReadOnlyArray: [None]>,
      #|  result: MatchResult([1, 7]),
      #|}
    ),
  )
  debug_inspect(
    regex.execute("xabccy"),
    content=(
      #|None
    ),
  )
}

///|
test "repeat/greedy_and_nongreedy" {
  let base = @string.Regex("[[:digit:]]")
  let greedy = base.repeat(min=2, max=4)
  let nongreedy = base.repeat(min=2, max=4, greedy=false)
  guard greedy.execute("a12345") is Some(m1) else {
    fail("Expected greedy match")
  }
  guard nongreedy.execute("a12345") is Some(m2) else {
    fail("Expected non-greedy match")
  }
  debug_inspect(
    m1,
    content=(
      #|{
      #|  input: <StringView: "a12345">,
      #|  group_names: <ReadOnlyArray: [None]>,
      #|  result: MatchResult([1, 5]),
      #|}
    ),
  )
  debug_inspect(
    m2,
    content=(
      #|{
      #|  input: <StringView: "a12345">,
      #|  group_names: <ReadOnlyArray: [None]>,
      #|  result: MatchResult([1, 3]),
      #|}
    ),
  )
}

///|
test "panic repeat/invalid_min_negative" {
  let base = @string.Regex("[[:digit:]]")
  ignore(base.repeat(min=-1))
}

///|
test "panic repeat/invalid_max_less_than_min" {
  let base = @string.Regex("[[:digit:]]")
  ignore(base.repeat(min=3, max=2))
}

///|
test "panic repeat/invalid_min_too_large" {
  let base = @string.Regex("[[:digit:]]")
  ignore(base.repeat(min=257))
}

///|
test "panic repeat/invalid_max_too_large" {
  let base = @string.Regex("[[:digit:]]")
  ignore(base.repeat(min=0, max=257))
}

///|
test "add/sequence" {
  let regex = @string.Regex::string("ab") + @string.Regex::string("cd")
  guard regex.execute("xxabcdyy") is Some(m) else {
    fail("Expected concatenated match")
  }
  debug_inspect(
    m,
    content=(
      #|{
      #|  input: <StringView: "xxabcdyy">,
      #|  group_names: <ReadOnlyArray: [None]>,
      #|  result: MatchResult([2, 6]),
      #|}
    ),
  )
}

///|
test "bitor/alternation" {
  let regex = @string.Regex::string("cat") | @string.Regex::string("dog")
  debug_inspect(
    regex.execute("dog"),
    content=(
      #|Some(
      #|  {
      #|    input: <StringView: "dog">,
      #|    group_names: <ReadOnlyArray: [None]>,
      #|    result: MatchResult([0, 3]),
      #|  },
      #|)
    ),
  )
  debug_inspect(
    regex.execute("cow"),
    content=(
      #|None
    ),
  )
}

///|
test "complex/email_pattern" {
  // Build readable email pattern using + and |
  // Use simpler character class - avoid complex mixing with POSIX classes
  // Put - at end to avoid it being interpreted as a range operator
  let username = @string.Regex("[a-zA-Z0-9_.+\\-]+")
  let domain_part = @string.Regex("[a-zA-Z0-9\\-]+")
  let tld = @string.Regex("com") | @string.Regex("org") | @string.Regex("net")
  let email = username +
    @string.Regex::string("@") +
    domain_part +
    @string.Regex::string(".") +
    tld
  guard email.execute("user@example.com") is Some(m) else {
    fail("Expected email match")
  }
  debug_inspect(
    m,
    content=(
      #|{
      #|  input: <StringView: "user@example.com">,
      #|  group_names: <ReadOnlyArray: [None]>,
      #|  result: MatchResult([0, 16]),
      #|}
    ),
  )
  guard email.execute("test.user+tag@my-domain.org") is Some(x) else {
    fail("Expected complex email match")
  }
  debug_inspect(
    x,
    content=(
      #|{
      #|  input: <StringView: "test.user+tag@my-domain.org">,
      #|  group_names: <ReadOnlyArray: [None]>,
      #|  result: MatchResult([0, 27]),
      #|}
    ),
  )
}

///|
test "complex/url_protocol" {
  // Build URL pattern with multiple protocol support
  let http = @string.Regex::string("http")
  let https = @string.Regex::string("https")
  let ftp = @string.Regex::string("ftp")
  let protocol = http | https | ftp
  let url = protocol + @string.Regex::string("://") + @string.Regex("[^/]+")
  guard url.execute("https://example.com") is Some(m) else {
    fail("Expected URL match")
  }
  debug_inspect(
    m,
    content=(
      #|{
      #|  input: <StringView: "https://example.com">,
      #|  group_names: <ReadOnlyArray: [None]>,
      #|  result: MatchResult([0, 19]),
      #|}
    ),
  )
  guard url.execute("ftp://files.server.org") is Some(m2) else {
    fail("Expected FTP URL match")
  }
  debug_inspect(
    m2,
    content=(
      #|{
      #|  input: <StringView: "ftp://files.server.org">,
      #|  group_names: <ReadOnlyArray: [None]>,
      #|  result: MatchResult([0, 22]),
      #|}
    ),
  )
  debug_inspect(
    url.execute("gopher://old.site"),
    content=(
      #|None
    ),
  )
}

///|
test "complex/date_formats" {
  // Support multiple date formats using | for readability
  let year = @string.Regex("[[:digit:]]{4}")
  let month = @string.Regex("[[:digit:]]{2}")
  let day = @string.Regex("[[:digit:]]{2}")
  let dash_sep = @string.Regex::string("-")
  let slash_sep = @string.Regex::string("/")
  let dot_sep = @string.Regex::string(".")
  let sep = dash_sep | slash_sep | dot_sep
  let date = year + sep + month + sep + day
  guard date.execute("2026-02-26") is Some(m1) else {
    fail("Expected dash date match")
  }
  debug_inspect(
    m1,
    content=(
      #|{
      #|  input: <StringView: "2026-02-26">,
      #|  group_names: <ReadOnlyArray: [None]>,
      #|  result: MatchResult([0, 10]),
      #|}
    ),
  )
  guard date.execute("2026/02/26") is Some(m2) else {
    fail("Expected slash date match")
  }
  debug_inspect(
    m2,
    content=(
      #|{
      #|  input: <StringView: "2026/02/26">,
      #|  group_names: <ReadOnlyArray: [None]>,
      #|  result: MatchResult([0, 10]),
      #|}
    ),
  )
  guard date.execute("2026.02.26") is Some(m3) else {
    fail("Expected dot date match")
  }
  debug_inspect(
    m3,
    content=(
      #|{
      #|  input: <StringView: "2026.02.26">,
      #|  group_names: <ReadOnlyArray: [None]>,
      #|  result: MatchResult([0, 10]),
      #|}
    ),
  )
}

///|
test "complex/programming_identifier" {
  // Match valid programming identifiers with optional namespace
  let start_char = @string.Regex("[[:alpha:]_]")
  let id_char = @string.Regex("[[:alnum:]_]")
  let identifier = start_char + id_char.repeat(min=0)
  let namespace_sep = @string.Regex::string("::")
  let namespaced_id = (identifier + namespace_sep).repeat(min=0) + identifier
  guard namespaced_id.execute("std::string::length") is Some(m) else {
    fail("Expected namespaced identifier match")
  }
  debug_inspect(
    m,
    content=(
      #|{
      #|  input: <StringView: "std::string::length">,
      #|  group_names: <ReadOnlyArray: [None]>,
      #|  result: MatchResult([0, 19]),
      #|}
    ),
  )
  guard namespaced_id.execute("_internal_var") is Some(m2) else {
    fail("Expected simple identifier match")
  }
  debug_inspect(
    m2,
    content=(
      #|{
      #|  input: <StringView: "_internal_var">,
      #|  group_names: <ReadOnlyArray: [None]>,
      #|  result: MatchResult([0, 13]),
      #|}
    ),
  )
  // Test should fail to match if starting with digit - the match skips leading digits
  guard namespaced_id.execute("123invalid") is Some(m3) else {
    fail("Expected match somewhere in string")
  }
  debug_inspect(
    m3,
    content=(
      #|{
      #|  input: <StringView: "123invalid">,
      #|  group_names: <ReadOnlyArray: [None]>,
      #|  result: MatchResult([3, 10]),
      #|}
    ),
  )
}

///|
test "complex/log_level" {
  // Match log levels with readable alternatives
  let debug = @string.Regex::string("DEBUG")
  let info = @string.Regex::string("INFO")
  // Fixed: Put WARNING before WARN since WARN is a prefix of WARNING
  let warn = @string.Regex::string("WARNING") | @string.Regex::string("WARN")
  let error = @string.Regex::string("ERROR")
  let fatal = @string.Regex::string("FATAL")
  let level = debug | info | warn | error | fatal
  // Fixed: Use [^\\]] to match anything except closing bracket
  // Otherwise .+ is greedy and matches past the ]
  let timestamp = @string.Regex::string("[") +
    @string.Regex("[^\\]]+") +
    @string.Regex::string("]")
  let log_line = timestamp + @string.Regex::string(" ") + level
  guard log_line.execute("[2026-02-26 10:30:45] ERROR") is Some(m) else {
    fail("Expected log line match")
  }
  debug_inspect(
    m,
    content=(
      #|{
      #|  input: <StringView: "[2026-02-26 10:30:45] ERROR">,
      #|  group_names: <ReadOnlyArray: [None]>,
      #|  result: MatchResult([0, 27]),
      #|}
    ),
  )
  guard log_line.execute("[10:30] WARNING") is Some(m2) else {
    fail("Expected warning match")
  }
  debug_inspect(
    m2,
    content=(
      #|{
      #|  input: <StringView: "[10:30] WARNING">,
      #|  group_names: <ReadOnlyArray: [None]>,
      #|  result: MatchResult([0, 15]),
      #|}
    ),
  )
}

///|
test "complex/phone_number" {
  // Match phone with optional country code and various formats
  let plus = @string.Regex::string("+")
  let country = plus + @string.Regex("[[:digit:]]{1,3}")
  let space = @string.Regex::string(" ")
  let dash = @string.Regex::string("-")
  let lparen = @string.Regex::string("(")
  let rparen = @string.Regex::string(")")
  let area = @string.Regex("[[:digit:]]{3}")
  let prefix = @string.Regex("[[:digit:]]{3}")
  let line = @string.Regex("[[:digit:]]{4}")
  let phone = country.repeat(min=0, max=1) +
    space.repeat(min=0, max=1) +
    ((lparen + area + rparen) | area) +
    (space | dash).repeat(min=0, max=1) +
    prefix +
    (space | dash).repeat(min=0, max=1) +
    line
  guard phone.execute("+1 (555)123-4567") is Some(m) else {
    fail("Expected phone match")
  }
  debug_inspect(
    m,
    content=(
      #|{
      #|  input: <StringView: "+1 (555)123-4567">,
      #|  group_names: <ReadOnlyArray: [None]>,
      #|  result: MatchResult([0, 16]),
      #|}
    ),
  )
}

///|
test "complex/semantic_version" {
  // Match semantic versioning with optional pre-release and build metadata
  let digits = @string.Regex("[[:digit:]]+")
  let dot = @string.Regex::string(".")
  let major_minor_patch = digits + dot + digits + dot + digits
  let dash = @string.Regex::string("-")
  // Fixed: pre-release and build can contain dots (e.g., "beta.1", "build.123")
  // Put - at the very end to avoid range interpretation
  let alphanum = @string.Regex("[a-zA-Z0-9.\\-]+")
  let pre_release = dash + alphanum
  let plus = @string.Regex::string("+")
  let build_meta = plus + alphanum
  let semver = major_minor_patch +
    pre_release.repeat(min=0, max=1) +
    build_meta.repeat(min=0, max=1)
  guard semver.execute("1.2.3") is Some(m1) else {
    fail("Expected simple version match")
  }
  debug_inspect(
    m1,
    content=(
      #|{
      #|  input: <StringView: "1.2.3">,
      #|  group_names: <ReadOnlyArray: [None]>,
      #|  result: MatchResult([0, 5]),
      #|}
    ),
  )
  guard semver.execute("2.0.0-beta.1+20260226") is Some(m2) else {
    fail("Expected full version match")
  }
  debug_inspect(
    m2,
    content=(
      #|{
      #|  input: <StringView: "2.0.0-beta.1+20260226">,
      #|  group_names: <ReadOnlyArray: [None]>,
      #|  result: MatchResult([0, 21]),
      #|}
    ),
  )
}

///|
test "complex/hex_color" {
  // Match hex colors in different formats
  let hash = @string.Regex::string("#")
  let hex = @string.Regex("[0-9a-fA-F]")
  // Match longest first to avoid short match on long colors
  let alpha_color = hash + hex + hex + hex + hex + hex + hex + hex + hex
  let long_color = hash + hex + hex + hex + hex + hex + hex
  let short_color = hash + hex + hex + hex
  let color = alpha_color | long_color | short_color
  guard color.execute("#FFF") is Some(m1) else {
    fail("Expected short hex match")
  }
  debug_inspect(
    m1,
    content=(
      #|{
      #|  input: <StringView: "#FFF">,
      #|  group_names: <ReadOnlyArray: [None]>,
      #|  result: MatchResult([0, 4]),
      #|}
    ),
  )
  guard color.execute("#FF5733") is Some(m2) else {
    fail("Expected long hex match")
  }
  debug_inspect(
    m2,
    content=(
      #|{
      #|  input: <StringView: "#FF5733">,
      #|  group_names: <ReadOnlyArray: [None]>,
      #|  result: MatchResult([0, 7]),
      #|}
    ),
  )
  guard color.execute("#FF5733AA") is Some(m3) else {
    fail("Expected alpha hex match")
  }
  debug_inspect(
    m3,
    content=(
      #|{
      #|  input: <StringView: "#FF5733AA">,
      #|  group_names: <ReadOnlyArray: [None]>,
      #|  result: MatchResult([0, 9]),
      #|}
    ),
  )
}

///|
test "complex/json_number" {
  // Match JSON number format
  let minus = @string.Regex::string("-")
  let plus_sign = @string.Regex::string("+")
  let zero = @string.Regex::string("0")
  let digit19 = @string.Regex("[1-9]")
  let digit = @string.Regex("[[:digit:]]")
  let int = zero | (digit19 + digit.repeat(min=0))
  let dot = @string.Regex::string(".")
  let frac = dot + digit.repeat(min=1)
  let e = @string.Regex::string("e") | @string.Regex::string("E")
  let exp = e + (plus_sign | minus).repeat(min=0, max=1) + digit.repeat(min=1)
  let number = minus.repeat(min=0, max=1) +
    int +
    frac.repeat(min=0, max=1) +
    exp.repeat(min=0, max=1)
  guard number.execute("-42") is Some(m1) else {
    fail("Expected integer match")
  }
  debug_inspect(
    m1,
    content=(
      #|{
      #|  input: <StringView: "-42">,
      #|  group_names: <ReadOnlyArray: [None]>,
      #|  result: MatchResult([0, 3]),
      #|}
    ),
  )
  guard number.execute("3.14159") is Some(m2) else {
    fail("Expected float match")
  }
  debug_inspect(
    m2,
    content=(
      #|{
      #|  input: <StringView: "3.14159">,
      #|  group_names: <ReadOnlyArray: [None]>,
      #|  result: MatchResult([0, 7]),
      #|}
    ),
  )
  guard number.execute("6.022e23") is Some(m3) else {
    fail("Expected scientific match")
  }
  debug_inspect(
    m3,
    content=(
      #|{
      #|  input: <StringView: "6.022e23">,
      #|  group_names: <ReadOnlyArray: [None]>,
      #|  result: MatchResult([0, 8]),
      #|}
    ),
  )
}

///|
test "add/with_any_quantifier" {
  let re1 = @string.Regex(".*?\\.")
  let re2 = re1 + @string.Regex::string(" ")
  guard re1.execute("abc.") is Some(_) else { fail("Expected match") }
  guard re2.execute("abc. ") is Some(_) else { fail("Expected match") }
}

///|
test "add/with_any_quantifier_and_empty_wrappers" {
  let empty = @string.Regex::string("")
  let re = empty + @string.Regex(".*?\\.") + empty + @string.Regex::string(" ")
  guard re.execute("abc. ") is Some(m) else { fail("Expected match") }
  inspect(m.content(), content="abc. ")
}

///|
test "should_raise" {
  assert_true(
    [
      try? @string.Regex::new("[-a]"),
      try? @string.Regex::new("[^-a]"),
      try? @string.Regex::new("[a-]"),
    ].all(it => it is Err(_)),
  )
}

///|
test "escaped_dash_in_char_class" {
  let regex = @string.Regex::new("[a\\-z]")
  inspect(regex.execute("a-z") is Some(_), content="true")
  inspect(regex.execute("b") is Some(_), content="false")
  inspect(regex.execute("-") is Some(_), content="true")
  inspect(regex.execute("a") is Some(_), content="true")
  inspect(regex.execute("z") is Some(_), content="true")
}
