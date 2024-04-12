pub enum JsonValue {
  Null
  Boolean(Bool)
  Number(Double)
  String(String)
  Array(@vec.Vec[JsonValue])
  Object(@map.Map[String, JsonValue])
}
