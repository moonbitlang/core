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
fn CloseCode::write_show(self : CloseCode, logger : &Logger) -> Unit {
  match self {
    Normal => logger <+ "Normal"
    GoingAway => logger <+ "GoingAway"
    ProtocolError => logger <+ "ProtocolError"
    UnsupportedData => logger <+ "UnsupportedData"
    Abnormal => logger <+ "Abnormal"
    InvalidFramePayload => logger <+ "InvalidFramePayload"
    PolicyViolation => logger <+ "PolicyViolation"
    MessageTooBig => logger <+ "MessageTooBig"
    MissingExtension => logger <+ "MissingExtension"
    InternalError => logger <+ "InternalError"
    Other(code) => logger <+ "Other(\{code})"
  }
}

///|
#deprecated("`Show` implementation for this type is deprecated, use `Debug` related API, or use `@debug.to_string` instead.")
pub impl Show for MessageKind

///|
pub impl Show for MessageKind with fn output(self, logger) {
  match self {
    Binary => logger <+ "Binary"
    Text => logger <+ "Text"
  }
}

///|
#deprecated("`Show` implementation for this type is deprecated, use `Debug` related API, or use `@debug.to_string` instead.")
#doc(hidden)
pub extend MessageKind with Show::{to_string}

///|
#deprecated("`Show` implementation for this type is deprecated, use `Debug` related API, or use `@debug.to_string` instead.")
pub impl Show for CloseCode

///|
pub impl Show for CloseCode with fn output(self, logger) {
  self.write_show(logger)
}

///|
#deprecated("`Show` implementation for this type is deprecated, use `Debug` related API, or use `@debug.to_string` instead.")
#doc(hidden)
pub extend CloseCode with Show::{to_string}

///|
#deprecated("`Show` implementation for this type is deprecated, use `Debug` related API, or use `@debug.to_string` instead.")
pub impl Show for WebSocketError

///|
#warnings("-deprecated")
pub impl Show for WebSocketError with fn output(self, logger) {
  match self {
    ConnectionClosed(close_code, msg) =>
      logger <+ "ConnectionClosed(\{close_code}, \{msg})"
    InvalidHandshake(msg) => logger <+ "InvalidHandshake(\{msg})"
    HandshakeRejected(msg, response) =>
      logger <+
        "HandshakeRejected(\{msg}, \{response.code}, \{@debug.Repr(response.reason)})"
    ProtocolError(msg) => logger <+ "ProtocolError(\{msg})"
  }
}

///|
#deprecated("`Show` implementation for this type is deprecated, use `Debug` related API, or use `@debug.to_string` instead.")
#doc(hidden)
pub extend WebSocketError with Show::{to_string}

///|
#deprecated
#doc(hidden)
pub extend MessageKind with @debug.Debug::{to_repr}

///|
#deprecated
#doc(hidden)
pub extend MessageKind with Show::{output}

///|
#deprecated
#doc(hidden)
pub extend CloseCode with @debug.Debug::{to_repr}

///|
#deprecated
#doc(hidden)
pub extend CloseCode with Eq::{not_equal, equal}

///|
#deprecated
#doc(hidden)
pub extend CloseCode with Show::{output}

///|
#deprecated
#doc(hidden)
pub extend WebSocketError with @debug.Debug::{to_repr}

///|
#deprecated
#doc(hidden)
pub extend WebSocketError with Show::{output}
