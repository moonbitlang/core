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
/// HTTP request method
pub(all) enum RequestMethod {
  Get
  Head
  Post
  Put
  Delete
  Connect
  Options
  Trace
  Patch
} derive(@debug.Debug, Eq, Compare, Hash, @json.ToJson)

///|
pub impl Show for RequestMethod with fn to_string(self) {
  match self {
    Get => "GET"
    Head => "HEAD"
    Post => "POST"
    Put => "PUT"
    Delete => "DELETE"
    Connect => "CONNECT"
    Options => "OPTIONS"
    Trace => "TRACE"
    Patch => "PATCH"
  }
}

///|
pub extend RequestMethod with Show::{to_string}

///|
/// Type for HTTP headers. The names of headers are case insensitive.
///
/// The RFC requires that multiple header entries with the same name
/// should be semantically equivalent to concatenating values with comma,
/// so a `Map` with unique keys can be used to represent headers.
///
/// One important exception to the above rule is the `Set-Cookie` header,
/// which is handled specially via the `Cookie` type.
pub type Headers = Map[CaseInsensitiveString, String]

///|
/// HTTP request header
pub(all) struct Request {
  meth : RequestMethod
  path : String
  headers : Headers
} derive(@debug.Debug, @json.ToJson)

///|
/// HTTP response header
pub(all) struct Response {
  code : Int32
  reason : String
  headers : Headers
  /// The list of cookies specified in `Set-Cookie` headers.
  ///
  /// JS backend note: browsers forbid JS code from accessing raw cookie values,
  /// so this field is always empty on JS backend.
  cookies : Array[Cookie]
} derive(@debug.Debug, @json.ToJson)

///|
/// A cookie value returned by a HTTP server via the `Set-Cookie` header
pub struct Cookie {
  name : String
  value : String
  path : String?
  expires_raw : String?
  max_age : Int64?
  domain : String?
  secure : Bool
  http_only : Bool
  extensions : Array[String]
} derive(@debug.Debug, @json.ToJson)
