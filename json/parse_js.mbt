///|
#cfg(target="js")
pub fn parse(str : StringView) -> Json raise ParseError {
  let mut result = None
  js_parse_ffi(
    str.to_string(),
    Null,
    True,
    False,
    Json::string,
    (value, str) => if str.is_blank() {
      Json::number(value)
    } else if !str.contains_any(chars="eE.") {
      // Check safe integer range
      if value < -9007199254740991.0 || value > 9007199254740991.0 {
        // represent as integer if possible
        if value < 0 {
          return Json::number(@double.neg_infinity, repr=str)
        } else {
          return Json::number(@double.infinity, repr=str)
        }
      } else {
        return Json::number(value)
      }
    } else if value > @double.max_value || value < @double.min_value {
      return Json::number(
        if value < 0 {
          @double.neg_infinity
        } else {
          @double.infinity
        },
        repr=str,
      )
    } else {
      return Json::number(value)
    },
    () => Map::new(),
    Map::set,
    Json::object,
    Json::array,
    obj => result = Some(Ok(convert(obj))),
    err_str => result = Some(Err(ParseError::SyntaxError(err_str))),
    () => result = Some(Err(ParseError::DepthLimitExceeded)),
  )
  result.unwrap().unwrap_or_error()
}

///|
#external
#cfg(target="js")
priv type Object

///|
#cfg(target="js")
fn convert(obj : Object) -> Json = "%identity"

///|
#cfg(target="js")
extern "js" fn js_parse_ffi(
  str : String,
  null : Json,
  true_ : Json,
  false_ : Json,
  string : (String) -> Json,
  number : (Double, String) -> Json,
  new_map : () -> Map[String, Json],
  set_map : (Map[String, Json], String, Json) -> Unit,
  map : (Map[String, Json]) -> Json,
  array : (Array[Json]) -> Json,
  set_result : (Object) -> Unit,
  set_error : (String) -> Unit,
  set_depth_error : () -> Unit,
) =
  #|(str, null_, true_, false_, string, number, new_map, set_map, map, array, set_result, set_error, set_depth_error) => {
  #|  function reviver(key, value, context) {
  #|    if (Object.is(value, null)) {
  #|      return null_;
  #|    } else if (Object.is(value, true)) {
  #|      return true_;
  #|    } else if (Object.is(value, false)) {
  #|      return false_;
  #|    } else if (typeof value === "string") {
  #|      return string(value);
  #|    } else if (typeof value === "number") {
  #|      return number(value, context?.source ?? "");
  #|    } else if (typeof value === "object") {
  #|      if (Array.isArray(value)) { 
  #|        return array(value)
  #|      }
  #|      let mbt_map = new_map();
  #|      for (let k in value) {
  #|        set_map(mbt_map, k, value[k]);
  #|      }
  #|      return map(mbt_map);
  #|    } else {
  #|      return value;
  #|    }
  #|  }
  #|  // Regex to detect unpaired surrogate halves
  #|  const re = /[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?<![\uD800-\uDBFF])[\uDC00-\uDFFF]/g;
  #|  try {
  #|    set_result(JSON.parse(str, reviver))
  #|  } catch(e) {
  #|    if (e instanceof SyntaxError) {
  #|      // Replace unpaired surrogates with their unicode escape sequences
  #|      // The error message could contain unpaired surrogate when the json contained emojis
  #|      const message = e.message.replace(re, ch =>
  #|        `\\u${ch.charCodeAt(0).toString(16).padStart(4, "0")}`
  #|      );
  #|      set_error(message);
  #|    } else if (e instanceof RangeError) {
  #|      set_depth_error();
  #|    } else {
  #|      throw e;
  #|    }
  #|  }
  #|}
  #|
