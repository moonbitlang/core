
trait MyShow {
  my_output(Self, Logger) -> Unit
  my_to_string(Self) -> String
}
impl MyShow with my_output(self, logger) {
  logger.write_string(MyShow::my_to_string(self))
}

impl MyShow with my_to_string(self) {
  let logger = StringBuilder::new()
  self.my_output(logger)
  logger.to_string()
}

type X  Int

// fn my_to_string(self: X) -> String {
//   self._.to_string()
// }


test {
  let u = X(42)  
  inspect!(u.my_to_string()) // this fails type checker
  let u0 = u as MyShow // this works, it should fail
  inspect!(u0.my_to_string())
  ignore(u0)  
}

type Y Int 

fn my_to_string(self: Y) -> String {
  self._.to_string()
}

impl MyShow for Y with my_to_string(self) {
  self.my_to_string()
}
test {
  let sb = StringBuilder::new()
  let v = Y(42)
  v.my_output(sb)
  inspect!(sb.to_string(), content="42")
}