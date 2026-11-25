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
#include <string.h>
#include <moonbit.h>

#ifdef _WIN32

#include <winsock2.h>
#include <ws2tcpip.h>
#include <iphlpapi.h>
#include <windows.h>

#define setsockopt(sock, level, opt, optval, len)\
  setsockopt((SOCKET)sock, level, opt, (const char*)(optval), len)

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
#include <errno.h>

#ifdef __linux__
#include <sys/ioctl.h>
#endif

typedef int HANDLE;
typedef int SOCKET;

#ifdef __MACH__
#define IPV6_ADD_MEMBERSHIP IPV6_JOIN_GROUP
#endif

#endif

MOONBIT_EXPORT
HANDLE moonbit_rt_make_tcp_socket(int family) {
#ifdef _WIN32
  SOCKET sock = WSASocket(
    family == 4 ? AF_INET : AF_INET6,
    SOCK_STREAM,
    0,
    NULL,
    0,
    WSA_FLAG_OVERLAPPED | WSA_FLAG_NO_HANDLE_INHERIT
  );
  if (sock == INVALID_SOCKET)
    return INVALID_HANDLE_VALUE;

  int exclusive_addruse = 0;
  if (
    setsockopt(
      sock,
      SOL_SOCKET,
      SO_EXCLUSIVEADDRUSE,
      (char*)&exclusive_addruse,
      sizeof(int)
    ) < 0
  ) {
    closesocket(sock);
    return INVALID_HANDLE_VALUE;
  }

  return (HANDLE)sock;
#else
  return socket(family == 4 ? AF_INET : AF_INET6, SOCK_STREAM, SOCK_CLOEXEC);
#endif
}

MOONBIT_EXPORT
int moonbit_rt_disable_nagle(HANDLE sock) {
  int enable = 1;
  return setsockopt(sock, IPPROTO_TCP, TCP_NODELAY, &enable, sizeof(int));
}

MOONBIT_EXPORT
int moonbit_rt_allow_reuse_addr(HANDLE sock) {
  int reuse_addr = 1;
  return setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &reuse_addr, sizeof(int));
}

MOONBIT_EXPORT
int moonbit_rt_allow_reuse_port(HANDLE sock) {
#ifdef SO_REUSEPORT
  int reuse_port = 1;
  return setsockopt(sock, SOL_SOCKET, SO_REUSEPORT, &reuse_port, sizeof(int));
#else
  (void)sock;
  return 0;
#endif
}

MOONBIT_EXPORT
HANDLE moonbit_rt_make_udp_socket(int family, int32_t multicast) {
#ifdef _WIN32
  SOCKET sock = WSASocket(
    family == 4 ? AF_INET : AF_INET6,
    SOCK_DGRAM,
    0,
    NULL,
    0,
    WSA_FLAG_OVERLAPPED | WSA_FLAG_NO_HANDLE_INHERIT
  );
  if (sock == INVALID_SOCKET)
    return INVALID_HANDLE_VALUE;

  if (multicast) {
    int reuse_multicastport = 1;
    if (
      setsockopt(
        sock,
        SOL_SOCKET,
        SO_REUSE_MULTICASTPORT,
        &reuse_multicastport,
        sizeof(int)
      ) < 0
    ) {
      closesocket(sock);
      return INVALID_HANDLE_VALUE;
    }
  } else {
    int exclusive_addruse = 0;
    if (
      setsockopt(
        sock,
        SOL_SOCKET,
        SO_EXCLUSIVEADDRUSE,
        &exclusive_addruse,
        sizeof(int)
      ) < 0
    ) {
      closesocket(sock);
      return INVALID_HANDLE_VALUE;
    }
  }

  return (HANDLE)sock;
#else
  int sock = socket(family == 4 ? AF_INET : AF_INET6, SOCK_DGRAM, 0);
  if (multicast) {
    int enable = 1;
# ifdef __linux__
    if (setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &enable, sizeof(int)) < 0) {
      close(sock);
      return -1;
    }
# elif defined(__MACH__)
    if (setsockopt(sock, SOL_SOCKET, SO_REUSEPORT, &enable, sizeof(int)) < 0) {
      close(sock);
      return -1;
    }
# else
    moonbit_panic();
# endif
  }
  return sock;
#endif
}

MOONBIT_EXPORT
int moonbit_rt_join_multicast_group(
  HANDLE sock,
  struct sockaddr_in *multi_addr,
  struct sockaddr_in *local_addr
) {
  struct ip_mreq mreq;
  mreq.imr_multiaddr = multi_addr->sin_addr;
  mreq.imr_interface = local_addr->sin_addr;
  return setsockopt(sock, IPPROTO_IP, IP_ADD_MEMBERSHIP, &mreq, sizeof(struct ip_mreq));
}

MOONBIT_EXPORT
int moonbit_rt_join_multicast_group_v6(
  HANDLE sock,
  struct sockaddr_in6 *multi_addr,
  uint32_t if_index
) {
  struct ipv6_mreq mreq;
  mreq.ipv6mr_multiaddr = multi_addr->sin6_addr;
  mreq.ipv6mr_interface = if_index;
  return setsockopt(sock, IPPROTO_IPV6, IPV6_ADD_MEMBERSHIP, &mreq, sizeof(struct ipv6_mreq));
}

MOONBIT_EXPORT
int moonbit_rt_set_multicast_interface(
  HANDLE sock,
  struct sockaddr_in *local_addr
) {
  return setsockopt(
    sock,
    IPPROTO_IP,
    IP_MULTICAST_IF,
    &local_addr->sin_addr,
    sizeof(struct in_addr)
  );
}

MOONBIT_EXPORT
int moonbit_rt_set_multicast_interface_v6(
  HANDLE sock,
  uint32_t interface_index
) {
  return setsockopt(
    sock,
    IPPROTO_IPV6,
    IPV6_MULTICAST_IF,
    &interface_index,
    sizeof(interface_index)
  );
}

MOONBIT_EXPORT
int moonbit_rt_set_multicast_ttl(HANDLE sock, int32_t ttl, int32_t family) {
  return setsockopt(
    sock,
    family == 4 ? IPPROTO_IP : IPPROTO_IPV6,
    family == 4 ? IP_MULTICAST_TTL : IPV6_MULTICAST_HOPS,
    (char*)&ttl,
    sizeof(ttl)
  );
}

MOONBIT_EXPORT
int moonbit_rt_set_multicast_loopback(HANDLE sock, int32_t enable, int32_t family) {
  return setsockopt(
    sock,
    family == 4 ? IPPROTO_IP : IPPROTO_IPV6,
    family == 4 ? IP_MULTICAST_LOOP : IPV6_MULTICAST_LOOP,
    (char*)&enable,
    sizeof(enable)
  );
}

MOONBIT_EXPORT
int moonbit_rt_set_ipv6_only(HANDLE sockfd, int ipv6_only) {
  return setsockopt(sockfd, IPPROTO_IPV6, IPV6_V6ONLY, &ipv6_only, sizeof(int));
}

MOONBIT_EXPORT
int moonbit_rt_listen(HANDLE sockfd) {
  return listen((SOCKET)sockfd, SOMAXCONN);
}

MOONBIT_EXPORT
int moonbit_rt_udp_client_connect(HANDLE sock, struct sockaddr *addr) {
  return connect((SOCKET)sock, addr, Moonbit_array_length(addr));
}

#ifdef TCP_KEEPINTVL
// Note for Windows:
//   According to https://learn.microsoft.com/en-us/windows/win32/winsock/ipproto-tcp-socket-options,
//   both `TCP_KEEPIDLE` and `TCP_KEEPINTVL` were introduced in Windows 10, version 1709,
//   while TCP_KEEPCNT` was introduced in Windows 10, version 1703.
//   So if `TCP_KEEPIDLE` is present, we can set keep alive stuff in a UNIX-like way.

MOONBIT_EXPORT
int moonbit_rt_enable_keepalive(
  HANDLE sock,
  int keep_idle,
  int keep_cnt,
  int keep_intvl
) {
  int value = 1;
  if (setsockopt(sock, SOL_SOCKET, SO_KEEPALIVE, &value, sizeof(int)) < 0)
    return -1;

  if (keep_cnt > 0) {
    if (setsockopt(sock, IPPROTO_TCP, TCP_KEEPCNT, &keep_cnt, sizeof(int)) < 0)
      return -1;
  }

  if (keep_idle > 0) {
#ifdef __MACH__
    if (setsockopt(sock, IPPROTO_TCP, TCP_KEEPALIVE, &keep_idle, sizeof(int)) < 0)
      return -1;
#else
    if (setsockopt(sock, IPPROTO_TCP, TCP_KEEPIDLE, &keep_idle, sizeof(int)) < 0)
      return -1;
#endif
  }

  if (keep_intvl > 0) {
    if (setsockopt(sock, IPPROTO_TCP, TCP_KEEPINTVL, &keep_intvl, sizeof(int)) < 0)
      return -1;
  }

  return 0;
}

#elif defined(_WIN32)
// For older Windows version

MOONBIT_EXPORT
int moonbit_rt_enable_keepalive(
  HANDLE sock,
  int keep_idle,
  int keep_cnt,
  int keep_intvl
) {
  if (keep_idle > 0 || keep_intvl > 0) {
    // On older Windows versions, we cannot set keepalive timeout and interval individually.
    // So if only one of these are specified, we set the other to the universal default
    // according to https://learn.microsoft.com/en-us/windows/win32/winsock/sio-keepalive-vals.
    struct tcp_keepalive config;
    config.onoff = 1;
    config.keepalivetime = (keep_idle > 0 ? keep_idle : 7200) * 1000;
    config.keepaliveinterval = (keep_intvl > 0 ? keep_intvl : 1) * 1000;
    DWORD number_of_bytes_returned;
    if (
      0 != WSAIoctl(
        (SOCKET)sock,
        SIO_KEEPALIVE_VALS,
        &config,
        sizeof(struct tcp_keepalive),
        NULL,
        0,
        &number_of_bytes_returned,
        NULL,
        NULL
      )
    ) {
      return -1;
    }
  } else {
    // Both `keep_idle` and `keep_intvl` are unspecified,
    // enable keep alive only and leave the timeout setting unchanged.
    int value = 1;
    if (setsockopt(sock, SOL_SOCKET, SO_KEEPALIVE, (const char*)&value, sizeof(int)) < 0)
      return -1;
  }

#ifdef TCP_KEEPCNT
  // For systems older than Windows 10, version 1703,
  // there is no way to set the keep alive count.
  if (keep_cnt > 0) {
    if (setsockopt(sock, IPPROTO_TCP, TCP_KEEPCNT, &keep_cnt, sizeof(int)) < 0)
      return -1;
  }
#endif

  return 0;
}

#endif

MOONBIT_EXPORT
int32_t moonbit_rt_ipv4_addr_size() {
  return sizeof(struct sockaddr_in);
}

MOONBIT_EXPORT
int32_t moonbit_rt_ipv6_addr_size() {
  return sizeof(struct sockaddr_in6);
}

MOONBIT_EXPORT
void moonbit_rt_init_ip_addr(struct sockaddr_in *addr, uint32_t ip, int port) {
  addr->sin_family = AF_INET;
  addr->sin_port = htons(port);
  addr->sin_addr.s_addr = htonl(ip);
}

MOONBIT_EXPORT
void moonbit_rt_init_ipv6_addr(
  struct sockaddr_in6 *addr,
  uint8_t *ip,
  int port,
  uint32_t scope_id
) {
  addr->sin6_family = AF_INET6;
  addr->sin6_flowinfo = 0;
  addr->sin6_port = htons(port);
  memcpy(&addr->sin6_addr, ip, 16);
  addr->sin6_scope_id = scope_id;
}

MOONBIT_EXPORT
uint32_t moonbit_rt_ip_addr_get_ip(struct sockaddr_in *addr) {
  return ntohl(addr->sin_addr.s_addr);
}

MOONBIT_EXPORT
uint32_t moonbit_rt_ip_addr_get_port(struct sockaddr_in *addr) {
  return ntohs(addr->sin_port);
}

MOONBIT_EXPORT
int32_t moonbit_rt_addr_is_ipv6(void *addr_bytes) {
  // Check if the address family is AF_INET6
  // use sa_family to be compatible with more platforms(BSD, Linux)
  struct sockaddr *sa = (struct sockaddr *)addr_bytes;
  return sa->sa_family == AF_INET6;
}

MOONBIT_EXPORT
int32_t moonbit_rt_addr_is_multicast(void *addr_bytes) {
  struct sockaddr *sa = (struct sockaddr *)addr_bytes;
  switch (sa->sa_family) {
    case AF_INET: {
      int first_octet = ntohl(((struct sockaddr_in*)sa)->sin_addr.s_addr) >> 24;
      return 224 <= first_octet && first_octet < 240;
    }
    case AF_INET6: {
      return ((struct sockaddr_in6*)sa)->sin6_addr.s6_addr[0] == 0xff;
    };
    default: return 0;
  };
}

MOONBIT_EXPORT
int32_t moonbit_rt_addr_get_ipv6_bytes_offset(void) {
  return offsetof(struct sockaddr_in6, sin6_addr);
}

MOONBIT_EXPORT
uint32_t moonbit_rt_addr_get_ipv6_scope_id(struct sockaddr_in6 *addr) {
  return addr->sin6_scope_id;
}

MOONBIT_EXPORT
int32_t moonbit_rt_addr_is_ipv6_wildcard(struct sockaddr_in6 *addr) {
  uint64_t *chunks = (uint64_t*)(addr->sin6_addr.s6_addr);
  return chunks[0] == 0 && chunks[1] == 0;
}

#ifdef _WIN32
typedef ADDRINFOW addrinfo_t;
#else
typedef struct addrinfo addrinfo_t;
#endif

#ifdef _WIN32

MOONBIT_EXPORT
void moonbit_rt_freeaddrinfo(addrinfo_t *addr) {
  FreeAddrInfoW(addr);
}

#endif

MOONBIT_EXPORT
int32_t moonbit_rt_addrinfo_is_null(addrinfo_t *addrinfo) {
  return addrinfo == 0;
}

MOONBIT_EXPORT
addrinfo_t *moonbit_rt_addrinfo_get_next(addrinfo_t *addrinfo) {
  return addrinfo->ai_next;
}

MOONBIT_EXPORT
int32_t moonbit_rt_addrinfo_addr_size(addrinfo_t *addrinfo) {
  if (addrinfo == NULL || addrinfo->ai_addr == NULL) {
    return 0;
  }

  if (addrinfo->ai_family == AF_INET) {
    return sizeof(struct sockaddr_in);
  } else if (addrinfo->ai_family == AF_INET6) {
    return sizeof(struct sockaddr_in6);
  } else {
    return 0;
  }
}

MOONBIT_EXPORT
void moonbit_rt_addrinfo_fill_addr(
  addrinfo_t *addrinfo,
  void *addr_out,
  int port
) {
  if (addrinfo == NULL || addrinfo->ai_addr == NULL) {
    return;
  }

  if (addrinfo->ai_family == AF_INET) {
    struct sockaddr_in *addr = (struct sockaddr_in*)addr_out;
    memcpy(addr, addrinfo->ai_addr, sizeof(struct sockaddr_in));
    addr->sin_port = htons(port);
    return;
  } else if (addrinfo->ai_family == AF_INET6) {
    struct sockaddr_in6 *addr = (struct sockaddr_in6*)addr_out;
    memcpy(addr, addrinfo->ai_addr, sizeof(struct sockaddr_in6));
    addr->sin6_port = htons(port);
    return;
  } else {
    return;
  }
}

MOONBIT_EXPORT
int moonbit_rt_getsockname(HANDLE sock, struct sockaddr *addr_out) {
  socklen_t len = Moonbit_array_length(addr_out);
  return getsockname((SOCKET)sock, addr_out, &len);
}

MOONBIT_EXPORT
uint32_t moonbit_rt_if_nametoindex(HANDLE sock, const char *name) {
#ifdef _WIN32

  NET_LUID luid;
  int err = ConvertInterfaceAliasToLuid((const WCHAR*)name, &luid);
  if (err) {
    SetLastError(err);
    return 0;
  }

  NET_IFINDEX index;
  err = ConvertInterfaceLuidToIndex(&luid, &index);
  if (err) {
    SetLastError(err);
    return 0;
  }

  return index;

#elif defined(__linux__)

  int name_len = Moonbit_array_length(name);
  if (name_len >= IFNAMSIZ) {
    errno = ENAMETOOLONG;
    return 0;
  }

  struct ifreq ifreq;
  // also copy the null terminator
  memcpy(ifreq.ifr_name, name, name_len + 1);

  if (ioctl(sock, SIOCGIFINDEX, &ifreq) < 0)
    return 0;

  return ifreq.ifr_ifindex;

#else

  return if_nametoindex(name);

#endif
}

MOONBIT_EXPORT
void *moonbit_rt_if_indextoname(HANDLE sock, uint32_t index) {
#ifdef _WIN32

  static WCHAR buf[NDIS_IF_MAX_STRING_SIZE + 1];
  NET_LUID luid;

  int err = ConvertInterfaceIndexToLuid(index, &luid);
  if (err) {
    SetLastError(err);
    return 0;
  }

  err = ConvertInterfaceLuidToAlias(&luid, buf, NDIS_IF_MAX_STRING_SIZE + 1);
  if (err) {
    SetLastError(err);
    return 0;
  }

  return buf;

#elif defined(__linux__)

  static struct ifreq ifreq;
  ifreq.ifr_ifindex = index;

  if (ioctl(sock, SIOCGIFNAME, &ifreq) < 0)
    return 0;

  return ifreq.ifr_name;

#else

  static char buf[IF_NAMESIZE];
  if (!if_indextoname(index, buf))
    return 0;

  return buf;

#endif
}
