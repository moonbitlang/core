///|
/// according to RFC6901,
/// a JsonPointer is represented in `/`-joined components,
/// each of whom is a valid Ecmascript property name,
/// encoded with `~` and `/` escaped.
pub enum JsonPointer {
  RootPointer
  Pointer(JsonPointer, token~ : String)
} derive(Show)

///|
/// Note that each part component can represent either:
/// 1. an Array Index
/// 2. an Object Property
/// 
/// We have to distinguish them while indexing with JsonPointer.
pub(all) enum PointerComponentInterpretion {
  ArrayIndex(Int)
  ObjectIndex(String)
} derive(Show)

///|
/// To determine whether a component can represent an Array Index
fn interprete(component : String) -> PointerComponentInterpretion {
  if component.length() == 0 {
    return ObjectIndex(component)
  }
  match component[0].to_char() {
    Some('1'..<'9') =>
      // number in base 10 without leading `0` can be interpreted as Array Index
      match (try? @strconv.parse_int(component, base=10)) {
        Err(_) => ObjectIndex(component)
        Ok(i) => ArrayIndex(i)
      }
    Some('0') =>
      // single `0` as number can be interpreted as Array Index
      if component.length() == 1 {
        ArrayIndex(0)
      } else {
        ObjectIndex(component)
      }
    _ => ObjectIndex(component)
  }
}

///|
/// Use a JsonPointer to index a value from a Json
/// When indexing Null, returns None
/// 
/// TODO:
/// implement another version of this indexing process,
/// making it raise an index error rather than return None.
pub fn JsonPointer::apply(self : JsonPointer, value : Json) -> Json? {
  let mut result = value
  for component in self {
    match result {
      Array(parent) =>
        if interprete(component) is ArrayIndex(i) {
          result = parent[i]
        } else {
          return None
        }
      Object(parent) => result = parent[component]
      _ => return None
    }
  }
  Some(result)
}

///|
/// join 2 JsonPointers:
/// use the referenced object of the first as the root object
///   to execute the second's indexing
pub impl Div for JsonPointer with div(parent, child) {
  JsonPointer::from_escaped_iter(parent.iter() + child.iter())
}

///|
/// used when a Pointer needs to be represented in other way:
/// eacape `/` and `~` with `~1` and  `~0`
fn escape_component(token : String) -> String {
  String::from_iter(
    Iter::new(yield_ => for c in token {
      match c {
        '/' => {
          if yield_('~') is IterContinue {
            if yield_('1') is IterContinue {
              continue
            }
          }
          break IterEnd
        }
        '~' => {
          if yield_('~') is IterContinue {
            if yield_('0') is IterContinue {
              continue
            }
          }
          break IterEnd
        }
        _ => if yield_(c) is IterEnd { break IterEnd }
      }
    } else {
      IterEnd
    }),
  )
}

///|
/// Indicates a parsing error
/// while trying to parse a JsonPointer
/// from a representation.
pub(all) suberror JsonPointerParsingError (String, String) derive (
  Eq,
  Show,
  ToJson,
)

///|
/// When an character lies after a `~`,
/// use this function to find it's unescape result.
fn get_unescaped(p : Int, full : String) -> Char raise JsonPointerParsingError {
  match full[p] {
    '0' => '~'
    '1' => '/'
    _ =>
      raise JsonPointerParsingError(
        (
          full,
          (
            #|Parsing JsonPointer error:
            $|  the escaping sequence ~\{full[p].to_char().unwrap()} is not found
            $|  Note: at position \{p}
          ),
        ),
      )
  }
}

///|
/// Parse a component's original property name from its representation.
fn unescape_component(token : String) -> String raise JsonPointerParsingError {
  let mut escaping : Bool = false
  let res : Array[Char] = []
  for k, v in token {
    if escaping {
      let unescaped = get_unescaped(k, token)
      res.push(unescaped)
      escaping = false
    } else {
      match v {
        '~' => escaping = true
        _ => res.push(v)
      }
    }
  }
  String::from_array(res)
}

///|
/// A iterator that yields a pointer's components.
pub fn JsonPointer::iter(self : Self) -> Iter[String] {
  Iter::new(yield_ => match self {
    RootPointer => IterEnd
    Pointer(p, token~) =>
      for component in p {
        guard yield_(component) is IterContinue else { break IterEnd }
      } else {
        yield_(token)
      }
  })
}

///|
/// These 2 functions constructs JsonPointer from iterators.
/// This one is only used inside this package,
/// to combine pointers.
fn JsonPointer::from_escaped_iter(iter : Iter[String]) -> JsonPointer {
  let mut res = RootPointer
  for token in iter {
    res = Pointer(res, token~)
  }
  res
}

///|
/// This is the often-used constructor of JsonPointer.
/// Components are passed escaped.
/// 
/// Users should consider use from_json more than this from_iter
pub fn JsonPointer::from_iter(
  iter : Iter[String],
) -> JsonPointer raise JsonPointerParsingError {
  let mut res = RootPointer
  for component in iter {
    let token = unescape_component(component)
    res = Pointer(res, token~)
  }
  res
}

///|
/// The primary construction of JsonPointer.
pub impl FromJson for JsonPointer with from_json(json, _) {
  match json {
    String(str) => {
      let preparedError = JsonDecodeError(
        (
          Root,
          "error parsing JsonPointer's json string: invalid format\n\tjson: \{str}",
        ),
      )
      if str != "" && str[0] != '/' {
        raise preparedError
      }
      let components = str.split("/")[1:].map(c => c.to_string())
      let result = try? JsonPointer::from_iter(components)
      match result {
        Ok(pointer) => pointer
        Err(_) => raise preparedError
      }
    }
    _ =>
      raise JsonDecodeError(
        (Root, "JsonPointer can only be constructed from a json string"),
      )
  }
}

///|
/// represent a JsonPointer in Json format.
pub impl ToJson for JsonPointer with to_json(self) {
  match self {
    RootPointer => Json::String("")
    Pointer(_) => {
      let mut res = ""
      for component in self {
        res += "/" + escape_component(component)
      }
      Json::string(res)
    }
  }
}

///|
/// using the following test suite present in rfc 
///  {
///     "foo": ["bar", "baz"],
///     "": 0,
///     "a/b": 1,
///     "c%d": 2,
///     "e^f": 3,
///     "g|h": 4,
///     "i\\j": 5,
///     "k\"l": 6,
///     " ": 7,
///     "m~n": 8
///  }
/// 
/// queries and results:
///      ""           // the whole document
///      "/foo"       ["bar", "baz"]
///      "/foo/0"     "bar"
///      "/"          0
///      "/a~1b"      1
///      "/c%d"       2
///      "/e^f"       3
///      "/g|h"       4
///      "/i\\j"      5
///      "/k\"l"      6
///      "/ "         7
///      "/m~0n"      8
test "json-pointer basic test" {
  let json = Object({
    "foo": Array([String("bar"), String("baz")]),
    "": Json::number(0),
    "a/b": Json::number(1),
    "c%d": Json::number(2),
    "e^f": Json::number(3),
    "g|h": Json::number(4),
    "i\\j": Json::number(5),
    "k\"l": Json::number(6),
    " ": Json::number(7),
    "m~n": Json::number(8),
  })
  let queries = [
    "", "/foo", "/foo/0", "/", "/a~1b", "/c%d", "/e^f", "/g|h", "/i\\j", "/k\"l",
    "/ ", "/m~0n",
  ]
  let pointers = queries
    .map(Json::string)
    .map(json => JsonPointer::from_json(json, Root))
  let results = pointers.map(pointer => pointer.apply(json))
  inspect(pointers, content=queries.to_json())
  inspect(
    results,
    content=[json, ["bar", "baz"].to_json(), "bar", 0, 1, 2, 3, 4, 5, 6, 7, 8]
      .map(a => Some(a))
      .to_json(),
  )
}

///|
test "json-pointer div-operator" {
  inspect(
    Pointer(RootPointer, token="a/b") / Pointer(RootPointer, token="abc"),
    content=Pointer(Pointer(RootPointer, token="a/b"), token="abc").to_json(),
  )
}
