// Copyright 2024 International Digital Economy Academy
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

pub fn init_state(~state : Int = 1) -> RandomState {
  { state: state.to_int64() }
}

pub fn gen_int64(self : RandomState) -> Int64 {
  self.state = self.state.lxor(self.state.lsr(12))
  self.state = self.state.lxor(self.state.lsl(25))
  self.state = self.state.lxor(self.state.lsr(27))
  self.state *= 0x2545F4914F6CDD1DL
  if self.state < 0L {
    self.state += @int64.max_value()
  }
  self.state
}

pub fn gen_double(self : RandomState) -> Double {
  self.gen_int64().to_double() / @int64.max_value().to_double()
}

pub fn gen_int(self : RandomState) -> Int {
  self.gen_int64().asr(32).to_int()
}
