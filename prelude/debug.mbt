/// [Debug] indicates a type can be printed for debugging
pub trait Debug {
  debug_write(Self, Buffer) -> Unit
}

/// print a value to the console using [Debug], with a tailing newline
pub fn debug[X : Debug](x : X) -> Unit {
  let buf = Buffer::make(10)
  x.debug_write(buf)
  println(buf.to_string())
}

pub fn debug_write(self : Unit, buf : Buffer) -> Unit {
  let _ = self
  buf.write_string("()")
}

pub fn debug_write(self : Bool, buf : Buffer) -> Unit {
  buf.write_string(self.to_string())
}

pub fn debug_write(self : Int, buf : Buffer) -> Unit {
  buf.write_string(self.to_string())
}

pub fn debug_write(self : Int64, buf : Buffer) -> Unit {
  buf.write_string(self.to_string())
}

pub fn debug_write(self : Double, buf : Buffer) -> Unit {
  buf.write_string(self.to_string())
}

pub fn debug_write(self : Char, buf : Buffer) -> Unit {
  buf.write_char('\'')
  match self {
    '\n' => buf.write_string("\\n")
    '\r' => buf.write_string("\\r")
    '\'' => buf.write_string("\\'")
    '\\' => buf.write_string("\\\\")
    _ => buf.write_char(self)
  }
  buf.write_char('\'')
}

pub fn debug_write[X : Debug](self : Option[X], buf : Buffer) -> Unit {
  match self {
    None => buf.write_string("None")
    Some(arg) => {
      buf.write_string("Some(")
      arg.debug_write(buf)
      buf.write_string(")")
    }
  }
}

pub fn debug_write[T : Debug, E : Debug](
  self : Result[T, E],
  buf : Buffer
) -> Unit {
  match self {
    Ok(x) => {
      buf.write_string("Ok(")
      x.debug_write(buf)
      buf.write_string(")")
    }
    Err(e) => {
      buf.write_string("Err(")
      e.debug_write(buf)
      buf.write_string(")")
    }
  }
}

pub fn debug_write[X : Debug](self : Ref[X], buf : Buffer) -> Unit {
  buf.write_string("{val: ")
  self.val.debug_write(buf)
  buf.write_string("}")
}

pub fn debug_write[X : Debug](self : Array[X], buf : Buffer) -> Unit {
  buf.write_char('[')
  for i = 0; i < self.length(); i = i + 1 {
    if i > 0 {
      buf.write_string(", ")
    }
    self[i].debug_write(buf)
  }
  buf.write_char(']')
}

pub fn debug_write(self : String, buf : Buffer) -> Unit {
  buf.write_char('"')
  let mut segment_start = 0
  fn flush_segment(i : Int) {
    if i > segment_start {
      buf.write_sub_string(self, segment_start, i - segment_start)
    }
    segment_start = i + 1
  }

  for i = 0; i < self.length(); i = i + 1 {
    let c = self[i]
    match c {
      '\n' => {
        flush_segment(i)
        buf.write_string("\\n")
      }
      '\r' => {
        flush_segment(i)
        buf.write_string("\\r")
      }
      '"' => {
        flush_segment(i)
        buf.write_string("\\\"")
      }
      '\\' => {
        flush_segment(i)
        buf.write_string("\\\\")
      }
      _ => ()
    }
  }
  flush_segment(self.length())
  buf.write_char('"')
}

pub fn debug_write[X : Debug, Y : Debug](self : (X, Y), buf : Buffer) -> Unit {
  buf.write_char('(')
  self.0.debug_write(buf)
  buf.write_string(", ")
  self.1.debug_write(buf)
  buf.write_char(')')
}

pub fn debug_write[X : Debug, Y : Debug, Z : Debug](
  self : (X, Y, Z),
  buf : Buffer
) -> Unit {
  buf.write_char('(')
  self.0.debug_write(buf)
  buf.write_string(", ")
  self.1.debug_write(buf)
  buf.write_string(", ")
  self.2.debug_write(buf)
  buf.write_char(')')
}

pub fn debug_write[X : Debug, Y : Debug, Z : Debug, W : Debug](
  self : (X, Y, Z, W),
  buf : Buffer
) -> Unit {
  buf.write_char('(')
  self.0.debug_write(buf)
  buf.write_string(", ")
  self.1.debug_write(buf)
  buf.write_string(", ")
  self.2.debug_write(buf)
  buf.write_string(", ")
  self.3.debug_write(buf)
  buf.write_char(')')
}

pub fn debug_write[X1 : Debug, X2 : Debug, X3 : Debug, X4 : Debug, X5 : Debug](
  self : (X1, X2, X3, X4, X5),
  buf : Buffer
) -> Unit {
  buf.write_char('(')
  self.0.debug_write(buf)
  buf.write_string(", ")
  self.1.debug_write(buf)
  buf.write_string(", ")
  self.2.debug_write(buf)
  buf.write_string(", ")
  self.3.debug_write(buf)
  buf.write_string(", ")
  self.4.debug_write(buf)
  buf.write_char(')')
}
