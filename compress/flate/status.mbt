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
/// Outcome of one step of the streaming DEFLATE state machine.
///
/// The engine is runtime-agnostic: it moves bytes between an input view and an
/// output buffer and *suspends* by returning one of these, so any driver — a
/// synchronous loop or an async adapter — can resume it.
pub(all) enum Status {
  /// End of the DEFLATE stream was reached; the operation is complete.
  Done
  /// Input was exhausted mid-stream; supply more bytes and call again.
  NeedMoreInput
  /// The output buffer filled up; drain it and call again.
  NeedMoreOutput
} derive(Eq, @debug.Debug)

///|
/// Requested action for one streaming compression step.
///
/// The action applies after the complete input view has been consumed. If a
/// step reports partial consumption, re-present the remaining suffix with the
/// same action.
pub(all) enum DeflateAction {
  /// Accept input without emitting a control block.
  Continue
  /// Make all input accepted so far available to the decoder while keeping the
  /// DEFLATE stream open.
  SyncFlush
  /// Finish the DEFLATE stream after all input in this view has been accepted.
  Finish
} derive(Eq, @debug.Debug)

///|
/// Result of one streaming codec call. The counts describe the input prefix
/// accepted and the output prefix written by this call, including when it
/// returns `Done`. Keep the result to inspect it independently of later calls.
#valtype
pub(all) struct StepResult {
  /// Whether decoding or encoding completed or needs more input/output.
  status : Status
  /// Number of bytes accepted from this call's input view.
  consumed : Int32
  /// Number of bytes written to this call's output view.
  produced : Int32
}

///|
/// Byte counts from a successful whole-buffer decompression call.
#valtype
pub struct DecompressResult {
  /// Compressed bytes consumed, excluding any trailing data.
  consumed : Int32
  /// Decompressed bytes written to the caller's buffer.
  produced : Int32
}
