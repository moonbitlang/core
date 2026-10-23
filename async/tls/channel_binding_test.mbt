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
async test "channel binding" {
  @async.with_task_group() <| group => {
    let (client_read_from_server, server_write_to_client) = @pipe.pipe()
    let (server_read_from_client, client_write_to_server) = @pipe.pipe()
    // server
    let server_task = group.spawn(() => {
      defer {
        server_read_from_client.close()
        server_write_to_client.close()
      }
      let server = test_server(server_read_from_client, server_write_to_client)
      defer server.close()
      (
        server.unique_channel_binding(),
        server.server_endpoint_channel_binding(),
      )
    })
    // client
    let client_task = group.spawn(() => {
      defer {
        client_read_from_server.close()
        client_write_to_server.close()
      }
      let client = @tls.Tls::client_from_pair(
        client_read_from_server,
        client_write_to_server,
        trust=NoVerification,
      )
      defer client.close()
      let binding = (
        client.unique_channel_binding(),
        client.server_endpoint_channel_binding(),
      )
      client.shutdown()
      binding
    })
    let (unique_binding_for_server, endpoint_binding_for_server) = server_task.wait()
    let (unique_binding_for_client, endpoint_binding_for_client) = client_task.wait()
    assert_eq(unique_binding_for_client, unique_binding_for_server)
    assert_true(unique_binding_for_client.length() > 0)
    assert_eq(endpoint_binding_for_client, endpoint_binding_for_server)
    assert_true(endpoint_binding_for_client.length() > 0)
  }
}
