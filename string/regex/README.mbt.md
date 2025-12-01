# 🔍 regexp.mbt

> ⚠️ **API STABILITY NOTICE**\
> This is a alpha release with a stabilizing API. While core functionality is
> complete and well-tested,\
> API changes may occur in future versions as we refine the implementation.

**Regular expression engine for MoonBit** — inspired by
[Russ Cox's regex series](https://swtch.com/~rsc/regexp/regexp1.html).

## ⚡ Quick Start

```mbt check
///|
test {
  // Compile once, use everywhere
  let regexp = @regex.compile("a(bc|de)f")
  guard regexp.execute("xxabcf") is Some(result)
  inspect(result.content(), content="abcf")
  inspect(
    result.group(1),
    content=(
      #|Some("bc")
    ),
  )

  // Write a simple split with regexp
  fn split(regexp : @regex.Regex, target : StringView) -> Array[StringView] {
    let result = []
    for str = target {
      match regexp.execute(str) {
        None => {
          result.push(str)
          break
        }
        Some(res) => {
          result.push(res.before())
          continue res.after()
        }
      }
    }
    result
  }

  let re = @regex.compile("_+")
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
- `engine.execute(text)` → Returns `MatchResult?`

### Inspect Results

- `result.content()` → `StringView`
- `result.before()` → `StringView`
- `result.after()` → `StringView`
- `result.group(index)` → Capture group content
- `result.named_group(name)` → Named capture group content

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

## 🌍 Unicode Property Support

Match characters by their Unicode general categories:

```mbt check
///|
test "unicode properties" {
  // Matching gc=L
  let regex = @regex.compile("\\p{Letter}+")
  inspect(
    regex.execute("Hello 世界").map(it => it.content()),
    content=(
      #|Some("Hello")
    ),
  )

  // Matching gc=N
  let regex = @regex.compile("\\p{Number}+")
  inspect(
    regex.execute("123 and 456").map(it => it.content()),
    content=(
      #|Some("123")
    ),
  )
}
```

**Supported Propertes:**

- [General Category](https://www.unicode.org/reports/tr44/#General_Category_Values)

## 💡 Real Examples

```mbt check
///|
test "character classes" {
  // Email validation (simplified)
  let email = @regex.compile(
    (
      #|[\w-]+@[\w-]+\.\w+
    ),
  )
  let email_result = email.execute("user@example.com")
  guard email_result is Some(email_result)
  inspect(email_result.content(), content="user@example.com")
  // Extract numbers
  let numbers = @regex.compile(
    (
      #|\d+\.\d{2}
    ),
  )
  let result = numbers.execute("Price: $42.99")
  guard result is Some(result)
  inspect(result.content(), content="42.99")

  // Named captures for parsing
  let parser = @regex.compile(
    (
      #|(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})
    ),
  )
  let date_result = parser.execute("2024-03-15")
  guard date_result is Some(date_result)
  inspect(
    date_result.named_group("year"),
    content=(
      #|Some("2024")
    ),
  )
  inspect(
    date_result.named_group("month"),
    content=(
      #|Some("03")
    ),
  )
  inspect(
    date_result.named_group("day"),
    content=(
      #|Some("15")
    ),
  )
}
```

## 🚨 Error Handling

```mbt check
///|
test {
  try {
    let _ = @regex.compile("a(b")
    // Oops! Missing )
  } catch {
    err => {
      let _msg = Error::to_string(err)
      ignore("Fix your regex! 🔧")
    }
  }
}
```

## ⚡ Performance Characteristics

- **Predictable complexity** — Designed to avoid catastrophic backtracking
  (except with backreferences)
- **VM-based** — Structured interpreter design
- **Unicode support** — Character set and property support (Currently based on Unicode 16.0 )

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
