///|
/// Argument group definition for mutual exclusion / required groups.
struct ArgGroup {
  name : String
  required : Bool
  multiple : Bool
}

///|
pub fn ArgGroup::new(name : String) -> ArgGroup {
  ArgGroup::{ name, required: false, multiple: true }
}

///|
pub fn ArgGroup::required(self : ArgGroup, value? : Bool = true) -> ArgGroup {
  ArgGroup::{ ..self, required: value }
}

///|
pub fn ArgGroup::multiple(self : ArgGroup, value? : Bool = true) -> ArgGroup {
  ArgGroup::{ ..self, multiple: value }
}
