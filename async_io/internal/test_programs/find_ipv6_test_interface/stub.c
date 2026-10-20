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

#include <stdint.h>
#include <moonbit.h>

#ifdef _WIN32

#include <winsock2.h>
#include <ws2tcpip.h>
#include <iphlpapi.h>
#include <windows.h>

#pragma comment(lib, "Iphlpapi.lib")

#else

#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/tcp.h>
#include <netinet/in.h>
#include <netdb.h>
#include <fcntl.h>
#include <unistd.h>
#include <net/if.h>
#include <ifaddrs.h>

#endif

MOONBIT_FFI_EXPORT
int32_t find_ipv6_test_interface() {
#ifdef _WIN32
  ULONG flags =
    GAA_FLAG_SKIP_ANYCAST |
    GAA_FLAG_SKIP_MULTICAST |
    GAA_FLAG_SKIP_DNS_SERVER;
  ULONG buf_len = 16 * 1024;
  IP_ADAPTER_ADDRESSES *addrs = 0;
  ULONG err = ERROR_BUFFER_OVERFLOW;

  for (int i = 0; i < 3 && err == ERROR_BUFFER_OVERFLOW; i++) {
    if (addrs != 0) {
      HeapFree(GetProcessHeap(), 0, addrs);
      addrs = 0;
    }
    addrs = (IP_ADAPTER_ADDRESSES*)HeapAlloc(GetProcessHeap(), 0, buf_len);
    if (addrs == 0) {
      return 0;
    }
    err = GetAdaptersAddresses(AF_INET6, flags, NULL, addrs, &buf_len);
  }

  if (err != NO_ERROR) {
    if (addrs != 0) {
      HeapFree(GetProcessHeap(), 0, addrs);
    }
    return 0;
  }

  int32_t result = 0;
  for (IP_ADAPTER_ADDRESSES *adapter = addrs; adapter; adapter = adapter->Next) {
    if (adapter->OperStatus != IfOperStatusUp) continue;
    if (adapter->Ipv6IfIndex == 0) continue;
    if (adapter->Flags & IP_ADAPTER_NO_MULTICAST) continue;

    for (
      IP_ADAPTER_UNICAST_ADDRESS *unicast = adapter->FirstUnicastAddress;
      unicast;
      unicast = unicast->Next
    ) {
      struct sockaddr *sa = unicast->Address.lpSockaddr;
      if (sa == NULL || sa->sa_family != AF_INET6) continue;

      struct sockaddr_in6 *sa6 = (struct sockaddr_in6*)sa;
      if (!IN6_IS_ADDR_LINKLOCAL(&sa6->sin6_addr)) continue;

      result = adapter->Ipv6IfIndex;
      break;
    }

    if (result != 0) break;
  }

  HeapFree(GetProcessHeap(), 0, addrs);
  return result;

#else

  int32_t result = 0;
  struct ifaddrs *ifs0 = 0;
  if (getifaddrs(&ifs0) < 0)
    return 0;

  for (struct ifaddrs *ifs = ifs0; ifs; ifs = ifs->ifa_next) {
    if (
      ifs->ifa_addr
      && ifs->ifa_addr->sa_family == AF_INET6
    // on Linux: loopback cannot do multicast
    // on MacOS: a lot of non-localhost non-routable interface
#   ifdef __linux__
      && !(ifs->ifa_flags & IFF_LOOPBACK)
#else
      && (ifs->ifa_flags & IFF_LOOPBACK)
#   endif
      && (ifs->ifa_flags & IFF_UP)
      && (ifs->ifa_flags & IFF_RUNNING)
      && (ifs->ifa_flags & IFF_MULTICAST)
      && IN6_IS_ADDR_LINKLOCAL(&(((struct sockaddr_in6*)ifs->ifa_addr)->sin6_addr))
    ) {
      result = if_nametoindex(ifs->ifa_name);
      if (result) break;
    }
  }
  freeifaddrs(ifs0);
  return result;

#endif
}
