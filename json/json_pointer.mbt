///|
pub enum JsonPointer {
  RootPointer
  Pointer(JsonPointer, token~ : String)
} derive(Show)

///|
pub(all) enum PointerComponentInterpretion {
  ArrayIndex(Int)
  ObjectIndex(String)
} derive(Show)

///|
fn interprete(component : String) -> PointerComponentInterpretion {
  if component.length() == 0 {
    return ObjectIndex(component)
  }
  match component[0].to_char() {
    Some('1'..<'9') =>
      match (try? @strconv.parse_int(component, base=10)) {
        Err(_) => ObjectIndex(component)
        Ok(i) => ArrayIndex(i)
      }
    Some('0') =>
      if component.length() == 1 {
        ArrayIndex(0)
      } else {
        ObjectIndex(component)
      }
    _ => ObjectIndex(component)
  }
}

///|
pub fn JsonPointer::apply(self : JsonPointer, value : Json) -> Json? {
  match (self, value) {
    (RootPointer, _) => Some(value)
    (Pointer(p, token~), v) =>
      match p.apply(v) {
        Some(Object(parent)) => Some(parent[token])
        Some(Array(parent)) =>
          if interprete(token) is ArrayIndex(i) {
            Some(parent[i])
          } else {
            None
          }
        _ => None
      }
  }
}

///|
pub impl Div for JsonPointer with div(parent, child) {
  match child {
    RootPointer => parent
    Pointer(p, token~) => Pointer(parent / p, token~)
  }
}

///|
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
suberror JsonPointerParsingError (String, String) derive(Eq, Show, ToJson)

///|
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
test {
  println(get_unescaped(1, "~2"))
}

///|
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
pub fn JsonPointer::iter(self : Self) -> Iter[String] {
  Iter::new(yield_ => match self {
    RootPointer => IterEnd
    Pointer(p, token~) =>
      for component in p {
        guard yield_(component) is IterContinue else { break IterEnd }
      } else {
        if yield_(token) is IterContinue {
          IterEnd
        } else {
          IterEnd
        }
      }
  })
}

///|
// pub impl Show for JsonPointer with output(self, logger) {
//   match self {
//     RootPointer => logger.write_char('/')
//     Pointer(p, token~) =>
//       logger..write_object(p)..write_string(escape_component(token))
//   }
// }

///|
fn JsonPointer::from_iter(
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
    Pointer(RootPointer, token="def") / Pointer(RootPointer, token="abc"),
    content=Pointer(Pointer(RootPointer, token="def"), token="abc").to_json(),
  )
}
