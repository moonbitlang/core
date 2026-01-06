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
/// Direct structural representation for debugging/diffing/pretty-printing.
///
// `pub` makes it readonly outside this package: it can be pattern-matched but
// not directly constructed. Use the smart constructors below.
//
// Design notes:
// - `Record` is encoded as `Record([RecordField(name, value), ...])` (not as an array
//   of `(String, Repr)` pairs) to keep generic traversal/rewrite code simple:
//   every tree edge is a `Repr`, so `children/with_children`, pruning, and diff
//   can work uniformly across node kinds.
// - Labeled enum arguments are encoded as
//   `Enum(name, [EnumLabeledArg(label, value), ...])`,
//   which supports mixing positional and labeled args.
// - `Map` is encoded as `Map([MapEntry(key, value), ...])`, which is
//   intended for "map-like" collections (MoonBit map literals like `{ k: v }`).
// - `Opaque` is intended for "container-like" wrappers that keep a type/tag but
//   otherwise behave structurally through their children.
enum Repr {
  UnitLit
  /// Integer literal stored as string representation.
  /// Covers Int16, Int, Int64, UInt16, UInt, UInt64, BigInt, etc.
  Integer(String)
  /// 64-bit floating-point literal leaf.
  DoubleLit(Double)
  /// 32-bit floating-point literal leaf.
  FloatLit(Float)
  /// Boolean literal leaf.
  BoolLit(Bool)
  /// Character literal leaf.
  CharLit(Char)
  /// String literal leaf.
  StringLit(String)
  /// Tuple node. Children are the tuple elements (`Tuple([])` is unit).
  Tuple(Array[Repr])
  /// Array container node.
  Array(Array[Repr])
  /// Record container node. Conventionally contains only `RecordField` children.
  Record(Array[Repr])
  /// Enum constructor/application node: `Enum(name, args)`.
  Enum(String, Array[Repr])
  /// Association/kv container for map literals.
  Map(Array[Repr])
  /// Record field node. Conventionally appears only under `Record`.
  RecordField(String, Repr)
  /// Labeled argument node. Conventionally appears only under `Enum`.
  EnumLabeledArg(String, Repr)
  /// Opaque wrapper node: prints as `<name>` or `<name: ...>` and keeps children.
  Opaque(String, Repr)
  /// Pre-rendered leaf string (already formatted, no quoting/escaping applied).
  Literal(String)
  /// Key/value node. Conventionally appears only under `Map`.
  MapEntry(Repr, Repr)
  /// Pruned subtree marker used by depth-limited pretty-printing.
  Omitted
}

///|
/// Child nodes of a `Repr` node.
///
/// Design notes:
/// - Leaves return `[]`; container nodes return their stored children.
/// - `RecordField`/`EnumLabeledArg` have one child; `MapEntry` has two.
/// - `children` and `with_children` form a partial lens for tree rewrites:
///   `self.with_children(self.children()) == self`.
fn Repr::children(self : Repr) -> Array[Repr] {
  match self {
    UnitLit
    | Integer(_)
    | DoubleLit(_)
    | FloatLit(_)
    | BoolLit(_)
    | CharLit(_)
    | StringLit(_)
    | Literal(_)
    | Omitted => []
    Tuple(xs) | Array(xs) | Record(xs) | Enum(_, xs) | Map(xs) => xs
    Opaque(_, value) | RecordField(_, value) | EnumLabeledArg(_, value) =>
      [value]
    MapEntry(key, value) => [key, value]
  }
}

///|
/// Rebuild a `Repr` node with a new child list (payload is preserved).
///
/// Notes:
/// - Leaf nodes ignore `children` and return themselves.
/// - `RecordField`/`EnumLabeledArg` expect exactly one child and fall back to
///   `RecordField(name, Omitted)`/`EnumLabeledArg(label, Omitted)`.
/// - `MapEntry` expects exactly two children and falls back to `MapEntry(Omitted, Omitted)`.
/// - This is intentionally not a total inverse of `children`: invalid arity is
///   clamped to keep the tree well-formed for generic traversal.
fn Repr::with_children(self : Repr, children : Array[Repr]) -> Repr {
  match self {
    UnitLit
    | Integer(_)
    | DoubleLit(_)
    | FloatLit(_)
    | BoolLit(_)
    | CharLit(_)
    | StringLit(_)
    | Literal(_)
    | Omitted => self
    Tuple(_) => Tuple(children)
    Array(_) => Array(children)
    Record(_) => Record(children)
    Enum(name, _) => Enum(name, children)
    Map(_) => Map(children)
    RecordField(name, _) =>
      match children {
        [value] => RecordField(name, value)
        _ => RecordField(name, Omitted)
      }
    EnumLabeledArg(label, _) =>
      match children {
        [value] => EnumLabeledArg(label, value)
        _ => EnumLabeledArg(label, Omitted)
      }
    MapEntry(_, _) =>
      match children {
        [key, value] => MapEntry(key, value)
        _ => MapEntry(Omitted, Omitted)
      }
    Opaque(name, _) =>
      match children {
        [value] => Opaque(name, value)
        _ => Opaque(name, Omitted)
      }
  }
}

///|
/// Traverse a `Repr` tree and rewrite each node with `f`.
///
/// `f` runs after children are traversed (post-order), so it sees rewritten
/// children and can hide fields by rewriting `RecordField`/`EnumLabeledArg` nodes.
#doc(hidden)
pub fn Repr::traverse(self : Repr, f : (Repr) -> Repr) -> Repr {
  fn go(node : Repr) -> Repr {
    let children = node.children()
    let next_children = children.map(fn(child) { go(child) })
    f(node.with_children(next_children))
  }

  go(self)
}

///|
/// Construct a `Integer` leaf.
#doc(hidden)
pub fn Repr::integer(x : String) -> Repr {
  Integer(x)
}

///|
/// Construct a `DoubleLit` leaf.
#doc(hidden)
pub fn Repr::double(x : Double) -> Repr {
  DoubleLit(x)
}

///|
/// Construct a `FloatLit` leaf.
#doc(hidden)
pub fn Repr::float(x : Float) -> Repr {
  FloatLit(x)
}

///|
/// Construct a `BoolLit` leaf.
#doc(hidden)
pub fn Repr::bool(x : Bool) -> Repr {
  BoolLit(x)
}

///|
/// Construct a `CharLit` leaf.
#doc(hidden)
pub fn Repr::char(x : Char) -> Repr {
  CharLit(x)
}

///|
/// Construct a `StringLit` leaf.
#doc(hidden)
pub fn Repr::string(x : String) -> Repr {
  StringLit(x)
}

///|
/// Construct a `Tuple` node from pre-built child `Repr`s.
#doc(hidden)
pub fn Repr::tuple(children : Array[Repr]) -> Repr {
  Tuple(children)
}

///|
/// Construct an `Array` node from pre-built child `Repr`s.
#doc(hidden)
pub fn Repr::array(children : Array[Repr]) -> Repr {
  Array(children)
}

///|
/// Construct a `Record` node from pre-built child `Repr`s.
#doc(hidden)
pub fn Repr::record(fields : Map[String, Repr]) -> Repr {
  Record(fields.to_array().map(fn(p) { RecordField(p.0, p.1) }))
}

///|
/// Construct an `Opaque(name, children)` node.
///
/// This is useful for values where you want to keep a tag/type name but still
/// show a structural summary through children (e.g. `<Map: {...}>`).
#doc(hidden)
pub fn Repr::opaque_(name : String, children : Repr) -> Repr {
  Opaque(name, children)
}

///|
/// Construct a `Literal(value)` leaf (already formatted).
#doc(hidden)
pub fn Repr::literal(value : String) -> Repr {
  Literal(value)
}

///|
/// Construct a `Map` node from key/value `Repr` pairs (for map literals).
#doc(hidden)
pub fn Repr::map(contents : Array[(Repr, Repr)]) -> Repr {
  Map(
    contents.map(fn(pair) {
      let (k, v) = pair
      MapEntry(k, v)
    }),
  )
}

///|
/// Construct an `Omitted` marker node.
#doc(hidden)
pub fn Repr::omitted() -> Repr {
  Omitted
}

///|
#doc(hidden)
pub fn Repr::unit() -> Repr {
  UnitLit
}

///|
/// Construct an `Enum(name, args)` node for enum/constructor applications.
///
/// Use `None` for positional arguments and `Some(label)` for labeled ones.
#doc(hidden)
pub fn Repr::ctor(name : String, args : Array[(String?, Repr)]) -> Repr {
  Enum(
    name,
    args.map(fn(arg) {
      let (label, value) = arg
      match label {
        None => value
        Some(label) => EnumLabeledArg(label, value)
      }
    }),
  )
}

///|
/// A shallow copy of `self` containing only its "label" (children replaced).
///
/// This is used by diff/pretty-print when the structure is preserved but
/// children are rendered separately.
fn Repr::shallow(self : Repr) -> Repr {
  match self {
    UnitLit
    | Integer(_)
    | DoubleLit(_)
    | FloatLit(_)
    | BoolLit(_)
    | CharLit(_)
    | StringLit(_)
    | Literal(_)
    | Omitted => self
    Tuple(_) => Tuple([])
    Array(_) => Array([])
    Record(_) => Record([])
    Enum(name, _) => Enum(name, [])
    Opaque(name, _) => Opaque(name, Omitted)
    Map(_) => Map([])
    RecordField(name, _) => RecordField(name, Omitted)
    EnumLabeledArg(label, _) => EnumLabeledArg(label, Omitted)
    MapEntry(_, _) => MapEntry(Omitted, Omitted)
  }
}
