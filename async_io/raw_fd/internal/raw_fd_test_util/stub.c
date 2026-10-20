/*
 * Copyright 2025 International Digital Economy Academy
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifdef _WIN32

#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>

#else

#include <sys/socket.h>

typedef int HANDLE;
typedef int SOCKET;

#endif

#include "moonbit.h"

MOONBIT_FFI_EXPORT
HANDLE raw_fd_test_make_udp_socket() {
#ifdef _WIN32
  SOCKET sock = WSASocket(
    AF_INET,
    SOCK_DGRAM,
    0,
    NULL,
    0,
    WSA_FLAG_NO_HANDLE_INHERIT
  );
  if (sock == INVALID_SOCKET)
    return INVALID_HANDLE_VALUE;
  return (HANDLE)sock;
#else
  return socket(AF_INET, SOCK_DGRAM, 0);
#endif
}

MOONBIT_FFI_EXPORT
int raw_fd_test_connect(HANDLE sock, struct sockaddr *addr) {
  return connect((SOCKET)sock, addr, Moonbit_array_length(addr));
}
