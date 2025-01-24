// Copyright 2025 International Digital Economy Academy
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
pub type! IOError String derive(Show)

///| Reads the content of a file specified by the given path and returns its
/// content as `Bytes`
///
/// # Parameters
///
/// - `path` : The path to the file to be read.
///
/// # Returns
///
/// - A `Bytes` representing the content of the file.
pub fn read_file_to_bytes(path : String) -> Bytes! {
  read_file_to_bytes_internal!(path)
}

///| Reads the content of a file specified by the given path and returns its
/// content as `String`.
///
/// # Parameters
///
/// - `path` : The path to the file to be read.
/// - `encoding~` : The encoding of the file. Only support `utf8` for now.
///
/// # Returns
///
/// - A `String` representing the content of the file.
pub fn read_file_to_string(
  path : String,
  encoding~ : String = "utf8"
) -> String! {
  read_file_to_string_internal!(path, encoding~)
}

///| Writes a `Bytes` to a file at the specified path.
///
/// # Parameters
///
/// - `path` : The path to the file where the bytes will be written.
/// - `content` : A `Bytes` to be written to the file.
pub fn write_bytes_to_file(path : String, content : Bytes) -> Unit! {
  write_bytes_to_file_internal!(path, content)
}

///| Writes a `String` to a file at the specified path.
///
/// # Parameters
///
/// - `path` : The path to the file where the string will be written.
/// - `content` : A `String` to be written to the file.
/// - `encoding~` : The encoding of the file. Only support `utf8` for now.
pub fn write_string_to_file(
  path : String,
  content : String,
  encoding~ : String = "utf8"
) -> Unit! {
  write_string_to_file_internal!(path, content, encoding~)
}
