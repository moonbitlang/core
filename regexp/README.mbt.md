---
moonbit:
  deps:
    moonbitlang/regexp:
      path: .
---

# 🔍 regexp.mbt

> ⚠️ **API STABILITY NOTICE**\
> This is a alpha release with a stabilizing API. While core functionality is
> complete and well-tested,\
> API changes may occur in future versions as we refine the implementation.

**Regular expression engine for MoonBit** — inspired by
[Russ Cox's regex series](https://swtch.com/~rsc/regexp/regexp1.html).

## ⚡ Quick Start

```moonbit
test {
  // Compile once, use everywhere
  let regexp = @regexp.compile("a(bc|de)f")
  guard regexp.match_("xxabcf") is Some(result)
  inspect(
    result.results(),
    content=(
      #|[Some("abcf"), Some("bc")]
    ),
  )

  // Write a simple split with regexp
  fn split(
    regexp : @regexp.Regexp,
    target : @string.View
  ) -> Array[@string.View] {
    let result = []
    loop target {
      "" => ()
      str => {
        let res = regexp.execute(str)
        result.push(res.before())
        continue res.after()
      }
    }
    result
  }

  let re = @regexp.compile("_+")
  inspect(
    split(re, "1_2__3__4__5_____6"),
    content=(
      #|["1", "2", "3", "4", "5", "6"]
    ),
  )
}
```

## 🎯 Core API

### Build & Execute

- `compile(pattern)` → Creates an `Engine`
- `engine.execute(text)` → Returns `MatchResult`

### Inspect Results

- `result.matched()` → `Bool`
- `result.get(index)` → Capture group content
- `result.results()` → Iterator over all matches

### Named Groups & Advanced

- `engine.group_by_name(name)` → Find group index by name
- `engine.group_count()` → Total capture groups
- `result.groups()` → Get named group content

## 🎪 Syntax Playground

| Feature           | Example              | What it does                        |
| ----------------- | -------------------- | ----------------------------------- |
| **Literals**      | `abc`                | Match exact text                    |
| **Wildcards**     | `a.c`                | `.` matches any character           |
| **Quantifiers**   | `a+`, `b*`, `c?`     | One or more, zero or more, optional |
| **Ranges**        | `a{2,5}`             | Between 2-5 repetitions             |
| **Classes**       | `[a-z]`, `[^0-9]`    | Character sets, negated sets        |
| **Groups**        | `(abc)`, `(?:xyz)`   | Capturing, non-capturing            |
| **Named**         | `(?<word>abc)`       | Named capture groups                |
| **Choice**        | `cat\|dog`           | Match either option                 |
| **Anchors**       | `^start`, `end$`     | Line boundaries                     |
| **Escapes**       | `\\u{41}`, `\\u0041` | Unicode escapes, standard escapes   |
| **Unicode Props** | `\\p{L}`, `\\p{Nd}`  | Unicode general categories          |
| **Backrefs** ⚠️   | `(.)\\1`             | Reference previous captures         |

## 🌍 Unicode Property Support

Match characters by their Unicode general categories:

```moonbit
test "unicode properties" {
  // Matching gc=L
  let regex = @regexp.compile("\\p{Letter}+")
  inspect(
    regex.execute("Hello 世界").results(),
    content=(
      #|[Some("Hello")]
    ),
  )

  // Matching gc=N
  let regex = @regexp.compile("\\p{Number}+")
  inspect(
    regex.execute("123 and 456").results(),
    content=(
      #|[Some("123")]
    ),
  )
}
```

**Supported Propertes:**

- [General Category](https://www.unicode.org/reports/tr44/#General_Category_Values)

## 🔄 Backreferences

> ⚠️ **Performance Warning**: Backreferences can cause exponential time
> complexity in worst cases!

```moonbit
test "backreferences" {
  // Palindrome detection (simple)
  let palindrome = @regexp.compile("^(.)(.)\\2\\1")
  inspect(
    palindrome.execute("abba").results(),
    content=(
      #|[Some("abba"), Some("a"), Some("b")]
    ),
  )

  // HTML tag matching
  let html_regex = @regexp.compile("<([a-zA-Z]+)[^>]*>(.*?)</\\1>")
  let result = html_regex.execute("<div class='test'>content</div>")
  inspect(
    result.results(),
    content=(
      #|[Some("<div class='test'>content</div>"), Some("div"), Some("content")]
    ),
  )
}
```

## 💡 Real Examples

```moonbit
test "character classes" {
  // Email validation (simplified)
  let email = @regexp.compile(
    (
      #|[\w-]+@[\w-]+\.\w+
    ),
  )
  let email_result = email.execute("user@example.com").results()
  inspect(
    email_result,
    content=(
      #|[Some("user@example.com")]
    ),
  )
  // Extract numbers
  let numbers = @regexp.compile(
    (
      #|\d+\.\d{2}
    ),
  )
  let result = numbers.execute("Price: $42.99").results()
  inspect(
    result,
    content=(
      #|[Some("42.99")]
    ),
  )

  // Named captures for parsing
  let parser = @regexp.compile(
    (
      #|(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})
    ),
  )
  let date_result = parser.execute("2024-03-15")
  inspect(
    date_result.groups(),
    content=(
      #|{"year": "2024", "month": "03", "day": "15"}

    ),
  )
}
```

## 🚨 Error Handling

```moonbit
test {
  try {
    let _ = @regexp.compile("a(b")  // Oops! Missing )
  } catch {
    RegexpError(err=MissingParenthesis, source_fragment=_) => println("Fix your regex! 🔧")
    _ => ()
  }
}
```

## ⚡ Performance Characteristics

- **Predictable complexity** — Designed to avoid catastrophic backtracking
  (except with backreferences)
- **VM-based** — Structured interpreter design
- **Unicode support** — Character set and property support

Built with reliability and correctness as primary goals.

## 🔍 Implementation Notes

### Behavior Differences from Other Engines

This implementation has some behavior differences compared to other popular
regex engines:

1. **Empty Character Class Handling**:
   - In JavaScript: `[][]` is parsed as two character classes with no characters
   - In Golang: `[][]` is parsed as one character class containing `]` and `[`
   - In MoonBit: we follow the JavaScript interpretation

2. **Empty Alternatives Behavior**:
   - Expressions like `(|a)*` and `(|a)+` have specific behavior that may differ
     from other implementations
   - See [Golang issue #46123](https://github.com/golang/go/issues/46123) for
     related discussion

3. **Backreferences**:
   - Backreferences are supported but may impact the complexity guarantees of
     the engine
