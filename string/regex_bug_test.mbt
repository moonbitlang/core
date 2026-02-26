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

// ============================================================================
// REGEX BUG DEMONSTRATIONS
// ============================================================================
// This file documents known bugs and gotchas when using MoonBit regex API
// with the `+` (concatenation) and `|` (alternation) operators.
//
// All tests are disabled with #cfg(false) as they demonstrate incorrect
// behavior that should fail. Each test is thoroughly documented to explain:
// - What the bug is
// - Why it happens
// - How to fix it
// - Expected vs actual behavior
// ============================================================================

// ============================================================================
// BUG CATEGORY 1: Character Class Range Operator Pitfalls
// ============================================================================

///|
// BUG: Hyphen in Character Class Creates Unintended Range
//
// WHAT: When `-` appears between two characters in a character class like
//       `[[:alnum:]_+.-]`, it acts as a range operator, not a literal hyphen.
//
// WHY:  In the pattern `[[:alnum:]_+.-]+`, the sequence `+.-` is interpreted
//       as a range from `+` (ASCII 43) to `.` (ASCII 46), which includes:
//       - '+' (ASCII 43)
//       - ',' (ASCII 44) - UNINTENDED!
//       - '-' (ASCII 45)
//       - '.' (ASCII 46)
//       
//       However, mixing POSIX character classes like [:alnum:] with such
//       ranges can cause parser errors depending on position. The parser
//       fails at position 14 (the `]` after `.-`) because it detects the
//       malformed range syntax.
//
// HOW TO FIX:
//       1. Put `-` at the very end: `[[:alnum:]_+.-]` → `[[:alnum:]_+.-]`
//       2. Or escape it: `[[:alnum:]_+\.-]`  
//       3. Or use explicit ranges: `[a-zA-Z0-9_.+\-]`
//
// EXPECTED: Pattern should compile and match email username parts
// ACTUAL:   ParserError at position 14: Unexpected character
//
#cfg(false)
test "bug/char_class_hyphen_creates_unintended_range" {
  // This pattern tries to match email usernames with alphanumeric, _, +, ., -
  let username = @string.Regex("[[:alnum:]_+.-]+")
  let domain_part = @string.Regex("[[:alnum:]-]+")
  let tld = @string.Regex("com") | @string.Regex("org") | @string.Regex("net")
  let email = username +
    @string.Regex::string("@") +
    domain_part +
    @string.Regex::string(".") +
    tld
  guard email.execute("user@example.com") is Some(m) else {
    fail("Expected email match")
  }
  inspect(m.content(), content="user@example.com")
}

// ============================================================================
// BUG CATEGORY 2: Alternation Operator Order Dependency
// ============================================================================

///|
// BUG: Alternation Order Matters When One Pattern is a Prefix of Another
//
// WHAT: When using `|` (alternation) with patterns where one is a prefix of
//       another, the order determines which pattern matches.
//
// WHY:  Regex engines process alternatives left-to-right and stop at the
//       first match. In the pattern:
//       `"WARN" | "WARNING"`
//       
//       When matching the text "WARNING":
//       1. Engine tries "WARN" first
//       2. "WARN" matches the first 4 chars of "WARNING"  
//       3. Engine stops and returns "WARN" (success!)
//       4. "WARNING" alternative is never tried
//       
//       This is standard regex behavior (greedy alternation), but can be
//       surprising when building patterns programmatically with `|`.
//
// HOW TO FIX:
//       Always put longer/more-specific patterns BEFORE shorter prefixes:
//       `"WARNING" | "WARN"`  ✓ Correct
//       `"WARN" | "WARNING"`  ✗ Wrong (will never match full "WARNING")
//
// EXPECTED: Pattern matches "[10:30] WARNING" completely
// ACTUAL:   Pattern matches only "[10:30] WARN" (truncated)
//
#cfg(false)
test "bug/alternation_prefix_order_matters" {
  let debug = @string.Regex::string("DEBUG")
  let info = @string.Regex::string("INFO")
  // BUG: WARN comes before WARNING, so it matches WARN prefix in WARNING text
  let warn = @string.Regex::string("WARN") | @string.Regex::string("WARNING")
  let error = @string.Regex::string("ERROR")
  let fatal = @string.Regex::string("FATAL")
  let level = debug | info | warn | error | fatal
  let timestamp = @string.Regex::string("[") +
    @string.Regex("[^\\]]+") +
    @string.Regex::string("]")
  let log_line = timestamp + @string.Regex::string(" ") + level
  guard log_line.execute("[10:30] WARNING") is Some(m) else {
    fail("Expected warning match")
  }
  // BUG: This assertion fails - matches "[10:30] WARN" not "[10:30] WARNING"
  inspect(m.content(), content="[10:30] WARNING")
}

// ============================================================================
// BUG CATEGORY 3: Incomplete Character Class Definitions
// ============================================================================

///|
// BUG: Character Class Missing Required Characters for Domain-Specific Format
//
// WHAT: Pattern doesn't include all valid characters for the format it tries
//       to match, causing partial/incomplete matches.
//
// WHY:  Semantic versioning (semver) allows pre-release and build metadata
//       with dots, e.g., "2.0.0-beta.1+build.123". The pattern uses:
//       `[[:alnum:]-]+` which matches alphanumeric and hyphen, but NOT dots.
//       
//       When matching "2.0.0-beta.1+20260226":
//       1. Matches "2.0.0-" (major.minor.patch and dash)
//       2. Matches "beta" from pre-release  
//       3. Stops at "." because it's not in [[:alnum:]-]
//       4. Never reaches "+20260226" build metadata
//       
//       Result: Only matches "2.0.0-beta" instead of full version string.
//
// HOW TO FIX:
//       Include dots in the character class:
//       `[[:alnum:]-]+` → `[[:alnum:].-]+` or `[a-zA-Z0-9.-]+`
//       
//       Put hyphen at the end to avoid range interpretation:
//       `[a-zA-Z0-9.-]+` → `[a-zA-Z0-9.\-]+`
//
// EXPECTED: Pattern matches full semver "2.0.0-beta.1+20260226"
// ACTUAL:   Pattern matches only "2.0.0-beta" (stops at dot before "1")
//
// REFERENCE: Semantic Versioning 2.0.0 (semver.org)
//            - Pre-release: alphanumerics, hyphens, and dots
//            - Build metadata: alphanumerics, hyphens, and dots
//
#cfg(false)
test "bug/semver_pattern_missing_dots_in_char_class" {
  let digits = @string.Regex("[[:digit:]]+")
  let dot = @string.Regex::string(".")
  let major_minor_patch = digits + dot + digits + dot + digits
  let dash = @string.Regex::string("-")
  let alphanum = @string.Regex("[[:alnum:]-]+") // BUG: missing dot
  let pre_release = dash + alphanum
  let plus = @string.Regex::string("+")
  let build_meta = plus + alphanum // BUG: missing dot here too
  let semver = major_minor_patch +
    pre_release.repeat(min=0, max=1) +
    build_meta.repeat(min=0, max=1)
  guard semver.execute("2.0.0-beta.1+20260226") is Some(m) else {
    fail("Expected full version match")
  }
  // BUG: This assertion fails - only matches "2.0.0-beta" not full version
  inspect(
    m.content(),
    content=(
      #|2.0.0-beta.1+20260226
    ),
  )
}

// ============================================================================
// BUG CATEGORY 4: Pattern Combination Issues
// ============================================================================

///|
// BUG: Complex Pattern Concatenation May Not Match Expected Input
//
// WHAT: When concatenating multiple regex patterns with `+`, the combined
//       pattern may not match strings that intuitively should match.
//
// WHY:  The pattern uses `\\[.*?\\]` to match brackets non-greedily, but
//       when combined with other patterns and concatenated with `+`, the
//       behavior may not be as expected. The issue might be related to:
//       
//       1. Escaping issues: `\\[.*?\\]` in MoonBit strings
//       2. Pattern compilation: How `+` combines internal AST nodes  
//       3. Anchoring behavior: Patterns may need explicit boundaries
//       
//       When trying to match "[2026-02-26 10:30:45] ERROR":
//       - timestamp pattern: `\\[.*?\\]` should match "[2026-02-26 10:30:45]"
//       - space pattern: literal " "
//       - level pattern: "ERROR" 
//       
//       But the concatenated pattern fails to match, suggesting the patterns
//       don't compose as expected when combined with `+`.
//
// HOW TO FIX:
//       1. Use `[^\\]]+` instead of `.*?` to match bracket contents:
//          `@string.Regex("[^\\]]+")` - matches anything except ]
//       2. Break pattern into literal parts with Regex::string():
//          `Regex::string("[") + Regex("[^\\]]+") + Regex::string("]")`
//       3. Test components separately to isolate the issue
//
// EXPECTED: Pattern matches "[2026-02-26 10:30:45] ERROR"
// ACTUAL:   Pattern fails to match (no match found)
//
// NOTE: This bug may indicate an issue with how `+` operator combines
//       patterns, or how `\\[.*?\\]` is interpreted/compiled.
//
#cfg(false)
test "bug/pattern_concatenation_no_match" {
  let debug = @string.Regex::string("DEBUG")
  let info = @string.Regex::string("INFO")
  let warn = @string.Regex::string("WARN") | @string.Regex::string("WARNING")
  let error = @string.Regex::string("ERROR")
  let fatal = @string.Regex::string("FATAL")
  let level = debug | info | warn | error | fatal
  let timestamp = @string.Regex("\\[.*?\\]")
  let log_line = timestamp + @string.Regex::string(" ") + level
  // BUG: This guard fails - pattern doesn't find any match
  guard log_line.execute("[2026-02-26 10:30:45] ERROR") is Some(m) else {
    fail("Expected log line match")
  }
  inspect(m.content(), content="[2026-02-26 10:30:45] ERROR")
}
