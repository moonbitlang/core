type StringBuilder Array[String]

pub fn StringBuilder::make() -> StringBuilder {
  StringBuilder([])
}

pub fn StringBuilder::add_string(self : StringBuilder, str : String) -> Unit {
  self.0.push(str)
}

/// @intrinsic %str_vec.join_to_str
fn StringBuilder::join(arr : Array[String], sep : String) -> String {
  if arr.length() == 0 {
    return ""
  }
  let len = arr.fold_left(fn(acc, it) { acc + it.length() }, init=0) + sep.length() *
    (arr.length() - 1)
  let buf = Buffer::make(len)
  if arr.length() > 1 && sep != "" {
    buf.write_string(arr[0])
    for i = 1; i < arr.length(); i = i + 1 {
      buf.write_string(sep)
      buf.write_string(arr[i])
    }
  } else {
    for i = 0; i < arr.length(); i = i + 1 {
      buf.write_string(arr[i])
    }
  }
  buf.to_string()
}

pub fn StringBuilder::to_string(self : StringBuilder) -> String {
  match self.0.length() {
    0 => ""
    1 => self.0[0]
    _ => {
      let str = StringBuilder::join(self.0, "")
      self.0.clear()
      self.0.push(str)
      str
    }
  }
}
