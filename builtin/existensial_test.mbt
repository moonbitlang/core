


type! StringError String

type! IntError Int 


test {
  let v : Array[Error] = [StringError("x"), IntError(1)]
  let buf = StringBuilder::new()
  for i in v {
    match i {
      StringError(s) => {
        buf.write_string(s)
      }
      IntError(i) => {
        // assert_eq!(i, 1)
        buf.write_object(i)
      }
      _ => abort("impossible")
    }
  }
  @json.inspect!(buf.to_string(), content="x1")
}