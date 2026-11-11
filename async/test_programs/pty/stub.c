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

#ifndef _WIN32
#define _XOPEN_SOURCE 700
// For NSIG.
#ifdef __APPLE__
#define _DARWIN_C_SOURCE
#else
#define _DEFAULT_SOURCE
#endif
#endif

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <moonbit.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/ioctl.h>
#include <sys/wait.h>
#include <termios.h>
#include <unistd.h>
#endif

// Terminal management only; everything else lives in pty.mbt. The caller owns
// `input` and `output` once taken. `error` is non-zero (errno or
// GetLastError) when spawning failed, in which case every other resource has
// already been released.
struct pty {
  int32_t error;
  int32_t pid;
#ifdef _WIN32
  HANDLE input, output, process, job;
  HPCON console;
#else
  // A slave descriptor kept until the terminal is closed: all child stdio is
  // /dev/null, so the child has to open /dev/tty before it owns a slave
  // itself, and the master would otherwise report EOF/EIO before then.
  int input, output, slave;
#endif
};

static struct pty *allocate_pty(void) {
  struct pty *pty = calloc(1, sizeof(struct pty));
  if (!pty) {
    fputs("pty: out of memory\n", stderr);
    exit(1);
  }
  return pty;
}

#ifdef _WIN32
// Converts NUL-terminated UTF-8 into `out`, which has room for `size` UTF-16
// units; with `size == 0`, only measures. Returns the UTF-16 length including
// the NUL, or 0 on failure.
static int to_utf16(moonbit_bytes_t utf8, WCHAR *out, int size) {
  return MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, (const char *)utf8,
                             -1, out, size);
}

// A CreateProcessW environment block: NUL-terminated entries, then a NUL.
static WCHAR *make_environment(moonbit_bytes_t *env) {
  int count = Moonbit_array_length(env);
  size_t size = 1;
  for (int i = 0; i < count; i++) {
    int n = to_utf16(env[i], NULL, 0);
    if (!n)
      return NULL;
    size += (size_t)n;
  }
  // An empty block still needs its own terminating NUL after the entries'.
  if (!count)
    size = 2;
  WCHAR *block = calloc(size, sizeof(WCHAR));
  if (!block) {
    SetLastError(ERROR_NOT_ENOUGH_MEMORY);
    return NULL;
  }
  WCHAR *p = block;
  for (int i = 0; i < count; i++) {
    int n = to_utf16(env[i], p, (int)(size - (size_t)(p - block)));
    if (!n) {
      free(block);
      return NULL;
    }
    p += n;
  }
  return block;
}

MOONBIT_FFI_EXPORT
struct pty *moonbitlang_async_pty_spawn(moonbit_bytes_t path, moonbit_bytes_t *env,
                                        int32_t rows, int32_t cols) {
  struct pty *pty = allocate_pty();
  HANDLE input_read = NULL, output_write = NULL;
  PROCESS_INFORMATION child = {0};
  STARTUPINFOEXW startup = {0};
  int attributes_initialized = 0;
  WCHAR *application = NULL, *environment = NULL;
  int n = to_utf16(path, NULL, 0);
  if (!n)
    goto fail;
  application = malloc((size_t)n * sizeof(WCHAR));
  if (!application) {
    SetLastError(ERROR_NOT_ENOUGH_MEMORY);
    goto fail;
  }
  if (!to_utf16(path, application, n) || !(environment = make_environment(env)))
    goto fail;

  // If the test process dies, the child must die as well.
  pty->job = CreateJobObjectW(NULL, NULL);
  JOBOBJECT_EXTENDED_LIMIT_INFORMATION limits = {0};
  limits.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
  if (!pty->job ||
      !SetInformationJobObject(pty->job, JobObjectExtendedLimitInformation,
                               &limits, sizeof(limits)))
    goto fail;
  if (!CreatePipe(&input_read, &pty->input, NULL, 0) ||
      !CreatePipe(&pty->output, &output_write, NULL, 0))
    goto fail;
  COORD size = {(SHORT)cols, (SHORT)rows};
  HRESULT result =
    CreatePseudoConsole(size, input_read, output_write, 0, &pty->console);
  if (FAILED(result)) {
    pty->console = NULL;
    SetLastError(HRESULT_CODE(result));
    goto fail;
  }
  CloseHandle(input_read);
  input_read = NULL;
  CloseHandle(output_write);
  output_write = NULL;

  SIZE_T attr_size = 0;
  InitializeProcThreadAttributeList(NULL, 1, 0, &attr_size);
  startup.StartupInfo.cb = sizeof(startup);
  // Do not inherit our redirected stdio into the console child.
  startup.StartupInfo.dwFlags = STARTF_USESTDHANDLES;
  startup.lpAttributeList = malloc(attr_size);
  if (!startup.lpAttributeList ||
      !InitializeProcThreadAttributeList(startup.lpAttributeList, 1, 0, &attr_size))
    goto fail;
  attributes_initialized = 1;
  if (!UpdateProcThreadAttribute(startup.lpAttributeList, 0,
        PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE, pty->console, sizeof(HPCON),
        NULL, NULL))
    goto fail;
  // A process started in a new process group, as @process does, has Ctrl-C
  // disabled, and the child inherits that flag. Clear it so that Ctrl-C works
  // in the child's own pseudo console.
  if (!SetConsoleCtrlHandler(NULL, FALSE))
    goto fail;
  // No command line: the child takes its parameters from the environment.
  if (!CreateProcessW(application, NULL, NULL, NULL, FALSE,
        EXTENDED_STARTUPINFO_PRESENT | CREATE_SUSPENDED |
          CREATE_UNICODE_ENVIRONMENT,
        environment, NULL, &startup.StartupInfo, &child))
    goto fail;
  if (!AssignProcessToJobObject(pty->job, child.hProcess) ||
      ResumeThread(child.hThread) == (DWORD)-1)
    goto fail;
  pty->process = child.hProcess;
  pty->pid = (int32_t)child.dwProcessId;
  goto cleanup;

fail:
  pty->error = (int32_t)GetLastError();
  if (child.hProcess) {
    TerminateProcess(child.hProcess, 1);
    WaitForSingleObject(child.hProcess, INFINITE);
    CloseHandle(child.hProcess);
  }
  if (input_read) CloseHandle(input_read);
  if (output_write) CloseHandle(output_write);
  if (pty->input) CloseHandle(pty->input);
  if (pty->output) CloseHandle(pty->output);
  if (pty->console) ClosePseudoConsole(pty->console);
  if (pty->job) CloseHandle(pty->job);
  pty->console = pty->job = NULL;
cleanup:
  if (attributes_initialized)
    DeleteProcThreadAttributeList(startup.lpAttributeList);
  free(startup.lpAttributeList);
  free(application);
  free(environment);
  if (child.hThread) CloseHandle(child.hThread);
  return pty;
}

MOONBIT_FFI_EXPORT
int32_t moonbitlang_async_pty_resize(struct pty *pty, int32_t rows, int32_t cols) {
  COORD size = {(SHORT)cols, (SHORT)rows};
  HRESULT result = ResizePseudoConsole(pty->console, size);
  return SUCCEEDED(result) ? 0 : HRESULT_CODE(result);
}

// Before Windows 11 24H2, ClosePseudoConsole waits until the output pipe is
// drained, so the caller must close or keep reading its end of the output.
// Closing the job kills the child if it is still running.
MOONBIT_FFI_EXPORT
void moonbitlang_async_pty_close(struct pty *pty) {
  if (pty->console) ClosePseudoConsole(pty->console);
  if (pty->process) CloseHandle(pty->process);
  if (pty->job) CloseHandle(pty->job);
  free(pty);
}

MOONBIT_FFI_EXPORT
HANDLE moonbitlang_async_pty_take_input(struct pty *pty) {
  HANDLE input = pty->input;
  pty->input = NULL;
  return input;
}

MOONBIT_FFI_EXPORT
HANDLE moonbitlang_async_pty_take_output(struct pty *pty) {
  HANDLE output = pty->output;
  pty->output = NULL;
  return output;
}
#else
static int resize_terminal(int terminal, int32_t rows, int32_t cols) {
  struct winsize size = {0};
  size.ws_row = (unsigned short)rows;
  size.ws_col = (unsigned short)cols;
  return ioctl(terminal, TIOCSWINSZ, &size) == 0;
}

static void child_failed(int exec_status) {
  int error = errno;
  ssize_t ignored = write(exec_status, &error, sizeof(error));
  (void)ignored;
  _exit(127);
}

MOONBIT_FFI_EXPORT
struct pty *moonbitlang_async_pty_spawn(moonbit_bytes_t path, moonbit_bytes_t *env,
                                        int32_t rows, int32_t cols) {
  struct pty *pty = allocate_pty();
  // The child writes its errno here if it fails before or at exec. Both ends
  // are FD_CLOEXEC, so a successful exec shows up as EOF.
  int exec_status[2] = {-1, -1};
  pid_t child = -1;
  // Prepared before fork: the child only makes async-signal-safe calls.
  char *argv[] = {(char *)path, NULL};
  int env_count = Moonbit_array_length(env);
  char **envp = calloc((size_t)env_count + 1, sizeof(char *));
  if (!envp) {
    fputs("pty: out of memory\n", stderr);
    exit(1);
  }
  for (int i = 0; i < env_count; i++)
    envp[i] = (char *)env[i];
  pty->input = pty->output = pty->slave = -1;
  // O_NONBLOCK lets the event loop poll the master; the duplicate for input
  // shares it, being the same open file description. Everything is opened
  // FD_CLOEXEC at once, as other threads may be spawning processes.
  int master = pty->output =
    open("/dev/ptmx", O_RDWR | O_NOCTTY | O_CLOEXEC | O_NONBLOCK);
  if (master < 0 || grantpt(master) < 0 || unlockpt(master) < 0 ||
      (pty->input = fcntl(master, F_DUPFD_CLOEXEC, 0)) < 0)
    goto fail;
  char *name = ptsname(master);
  if (!name || (pty->slave = open(name, O_RDWR | O_NOCTTY | O_CLOEXEC)) < 0 ||
      !resize_terminal(master, rows, cols) || pipe(exec_status) < 0 ||
      fcntl(exec_status[0], F_SETFD, FD_CLOEXEC) < 0 ||
      fcntl(exec_status[1], F_SETFD, FD_CLOEXEC) < 0)
    goto fail;
  child = fork();
  if (child < 0)
    goto fail;
  if (child == 0) {
    // The async runtime ignores SIGPIPE and changes the signal mask, and the
    // test runner may have ignored others; all of that survives exec.
    sigset_t empty;
    sigemptyset(&empty);
    if (sigprocmask(SIG_SETMASK, &empty, NULL) < 0)
      child_failed(exec_status[1]);
    for (int sig = 1; sig < NSIG; sig++)
      signal(sig, SIG_DFL);
    if (setsid() < 0 || ioctl(pty->slave, TIOCSCTTY, 0) < 0 ||
        tcsetpgrp(pty->slave, getpgrp()) < 0)
      child_failed(exec_status[1]);
    int null = open("/dev/null", O_RDWR);
    if (null < 0)
      child_failed(exec_status[1]);
    for (int fd = 0; fd < 3; fd++) {
      if (dup2(null, fd) < 0)
        child_failed(exec_status[1]);
    }
    // Everything else, the slave included, is closed by FD_CLOEXEC.
    execve(argv[0], argv, envp);
    child_failed(exec_status[1]);
  }
  close(exec_status[1]);
  exec_status[1] = -1;
  int child_error = 0;
  ssize_t n = read(exec_status[0], &child_error, sizeof(child_error));
  if (n != 0) {
    if (n > 0)
      errno = child_error;
    goto fail;
  }
  close(exec_status[0]);
  free(envp);
  pty->pid = (int32_t)child;
  return pty;

fail:
  pty->error = errno;
  if (child > 0) {
    kill(child, SIGKILL);
    waitpid(child, NULL, 0);
  }
  if (exec_status[0] >= 0) close(exec_status[0]);
  if (exec_status[1] >= 0) close(exec_status[1]);
  if (pty->slave >= 0) close(pty->slave);
  if (pty->input >= 0) close(pty->input);
  if (pty->output >= 0) close(pty->output);
  pty->slave = -1;
  free(envp);
  return pty;
}

MOONBIT_FFI_EXPORT
int32_t moonbitlang_async_pty_resize(struct pty *pty, int32_t rows, int32_t cols) {
  // The master belongs to the caller now; the anchor reaches the same terminal.
  return resize_terminal(pty->slave, rows, cols) ? 0 : errno;
}

// Once the master is closed too, the terminal hangs up, which sends SIGHUP to
// the child if it is still running.
MOONBIT_FFI_EXPORT
void moonbitlang_async_pty_close(struct pty *pty) {
  if (pty->slave >= 0) close(pty->slave);
  free(pty);
}

MOONBIT_FFI_EXPORT
int32_t moonbitlang_async_pty_take_input(struct pty *pty) {
  int input = pty->input;
  pty->input = -1;
  return input;
}

MOONBIT_FFI_EXPORT
int32_t moonbitlang_async_pty_take_output(struct pty *pty) {
  int output = pty->output;
  pty->output = -1;
  return output;
}
#endif

MOONBIT_FFI_EXPORT
int32_t moonbitlang_async_pty_error(struct pty *pty) {
  return pty->error;
}

MOONBIT_FFI_EXPORT
int32_t moonbitlang_async_pty_pid(struct pty *pty) {
  return pty->pid;
}
