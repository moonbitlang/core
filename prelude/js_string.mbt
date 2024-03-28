/// Create a JS string from a string in Moonbit by calling intrinsic primitive
pub fn Js_string::new(x : String) -> Js_string {
  x.to_js_string()
}

/// Call FFI to log the JS string
pub fn log(self : Js_string) -> Unit = "js_string" "log"

/// Call FFI to append two JS strings
pub fn op_add(self : Js_string, other : Js_string) -> Js_string = "js_string" "append"
