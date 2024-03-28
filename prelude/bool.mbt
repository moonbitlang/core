pub fn to_string(self : Bool) -> String {
  if self {
    "true"
  } else {
    "false"
  }
}

pub fn to_int(self : Bool) -> Int {
  if self {
    1
  } else {
    0
  }
}

pub fn to_int64(self : Bool) -> Int64 {
  if self {
    1L
  } else {
    0L
  }
}

pub fn debug_write(self : Bool, buf : Buffer) -> Unit {
  buf.write_string(self.to_string())
}
