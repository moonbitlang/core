// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
/// Create a new cookie value
#alias(new, deprecated)
pub fn Cookie::Cookie(
  name : String,
  value : String,
  path? : String,
  expires_raw? : String,
  max_age? : Int64,
  domain? : String,
  secure~ : Bool = false,
  http_only~ : Bool = false,
  extensions~ : Array[String] = [],
) -> Cookie {
  {
    name,
    value,
    path,
    expires_raw,
    max_age,
    domain,
    secure,
    http_only,
    extensions,
  }
}

///|
/// Parse the value of a `Set-Cookie` header.
/// Following RFC 6265 section 5.2, a line without `=` in its name-value pair
/// is ignored (`None`), and so is a malformed `Max-Age` attribute, instead of
/// failing the whole response.
#cfg(any(target="native", target="wasm"))
fn Cookie::parse(line : StringView) -> Cookie? {
  let (name_value, attrs) = match line.split_once(";") {
    Some(pair) => pair
    None => (line, "")
  }
  guard name_value.split_once("=") is Some((name, value)) else { return None }
  let name = name.to_owned()
  let value = value.to_owned()
  if attrs is "" {
    return Some(Cookie(name, value))
  }

  let mut path = None
  let mut expires_raw = None
  let mut max_age = None
  let mut domain = None
  let mut secure = false
  let mut http_only = false
  let extensions = []
  for attr in attrs.split(";") {
    let attr = attr.trim()
    if attr.split_once("=") is Some((name, value)) {
      match name.to_lower() {
        "path" => path = Some(value.to_owned())
        "expires" => expires_raw = Some(value.to_owned())
        "max-age" =>
          if parse_max_age(value) is Some(value) {
            max_age = Some(value)
          }
        "domain" => domain = Some(value.to_owned())
        _ => extensions.push(attr.to_owned())
      }
    } else {
      match attr.to_lower() {
        "secure" => secure = true
        "httponly" => http_only = true
        _ => extensions.push(attr.to_owned())
      }
    }
  }
  Some({
    name,
    value,
    path,
    expires_raw,
    max_age,
    domain,
    secure,
    http_only,
    extensions,
  })
}

///|
/// RFC 6265 section 5.2.2 ignores a value that is not an optional `-`
/// followed by digits. A value that has this form but does not fit in `Int64`
/// is ignored as well, since it cannot be represented.
#cfg(any(target="native", target="wasm"))
fn parse_max_age(value : StringView) -> Int64? {
  let digits = if value.has_prefix("-") { value[1:] } else { value }
  guard digits.length() > 0 && digits.iter().all(c => c is ('0'..<='9')) else {
    return None
  }
  try @string.parse_int64(value) catch {
    _ => None
  } noraise {
    value => Some(value)
  }
}

///|
#cfg(any(target="native", target="wasm"))
async fn[W : @io.BinaryWriter] Cookie::write_to(cookie : Cookie, w : W) -> Unit {
  w
  ..write(@utf8.encode(cookie.name))
  ..write(b"=")
  .write(@utf8.encode(cookie.value))
  if cookie.path is Some(path) {
    w..write(b"; Path=").write(@utf8.encode(path))
  }
  if cookie.expires_raw is Some(expires_raw) {
    w..write(b"; Expires=").write(@utf8.encode(expires_raw))
  }
  if cookie.max_age is Some(max_age) {
    w..write(b"; Max-Age=").write(@utf8.encode(max_age.to_string()))
  }
  if cookie.domain is Some(domain) {
    w..write(b"; Domain=").write(@utf8.encode(domain))
  }
  if cookie.secure {
    w.write(b"; Secure")
  }
  if cookie.http_only {
    w.write(b"; HttpOnly")
  }
  for ext in cookie.extensions {
    w..write(b"; ").write(@utf8.encode(ext))
  }
}
