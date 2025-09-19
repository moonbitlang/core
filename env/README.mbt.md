# Env Package Documentation

This package provides utilities for interacting with the runtime environment, including access to command line arguments, current time, and working directory information.

## Command Line Arguments

Access command line arguments passed to your program:

```moonbit
///|
test "command line arguments" {
  let arguments = @env.args()

  // The arguments array contains program arguments
  // In a test environment, this will typically be empty or contain test runner args
  inspect(arguments.length() >= 0, content="true")

  // Example of how you might process arguments in a real program:
  fn process_args(args : Array[String]) -> String {
    if args.length() == 0 {
      "No arguments provided"
    } else {
      "First argument: " + args[0]
    }
  }

  let result = process_args(arguments)
  inspect(result.length() > 0, content="true")
}
```

## Current Time

Get the current time in milliseconds since Unix epoch:

```moonbit
///|
test "current time" {
  let timestamp = @env.now()

  // Timestamp should be a reasonable value (after year 2020)
  let year_2020_ms = 1577836800000UL // Jan 1, 2020 in milliseconds
  inspect(timestamp > year_2020_ms, content="true")

  // Demonstrate time-based operations
  fn format_timestamp(ts : UInt64) -> String {
    "Timestamp: " + ts.to_string()
  }

  let formatted = format_timestamp(timestamp)
  inspect(formatted.length() > 10, content="true") // Should contain timestamp data
}
```

## Working Directory

Get the current working directory:

```moonbit
///|
test "working directory" {
  let cwd = @env.current_dir()
  match cwd {
    Some(path) => {
      // We have a current directory
      inspect(path.length() > 0, content="true")
      inspect(path.length() > 1, content="true") // Should be a meaningful path
    }
    None =>
      // Current directory unavailable (some platforms/environments)
      inspect(true, content="true") // This is also valid
  }
}
```

## Practical Usage Examples

### Command Line Tool Pattern

```moonbit
///|
test "command line tool pattern" {
  fn parse_command(args : Array[String]) -> Result[String, String] {
    if args.length() < 2 {
      Err("Usage: program <command> [args...]")
    } else {
      match args[1] {
        "help" => Ok("Showing help information")
        "version" => Ok("Version 1.0.0")
        "status" => Ok("System is running")
        cmd => Err("Unknown command: " + cmd)
      }
    }
  }

  // Test with mock arguments
  let test_args = ["program", "help"]
  let result = parse_command(test_args)
  inspect(result, content="Ok(\"Showing help information\")")
  let invalid_result = parse_command(["program", "invalid"])
  match invalid_result {
    Ok(_) => inspect(false, content="true")
    Err(msg) => inspect(msg.length() > 10, content="true") // Should have error message
  }
}
```

### Configuration Loading

```moonbit
///|
test "configuration loading" {
  fn load_config_path() -> String {
    match @env.current_dir() {
      Some(cwd) => cwd + "/config.json"
      None => "./config.json" // Fallback
    }
  }

  let config_path = load_config_path()
  inspect(config_path.length() > 10, content="true") // Should have path with config.json
}
```

### Logging with Timestamps

```moonbit
///|
test "logging with timestamps" {
  fn log_message(level : String, message : String) -> String {
    let timestamp = @env.now()
    "[" + timestamp.to_string() + "] " + level + ": " + message
  }

  let log_entry = log_message("INFO", "Application started")
  inspect(log_entry.length() > 20, content="true") // Should have timestamp and message
  inspect(log_entry.length() > 10, content="true") // Should have substantial content
}
```

### File Path Operations

```moonbit
///|
test "file path operations" {
  fn resolve_relative_path(relative : String) -> String {
    match @env.current_dir() {
      Some(base) => base + "/" + relative
      None => relative
    }
  }

  let resolved = resolve_relative_path("data/input.txt")
  inspect(resolved.length() > 10, content="true") // Should have resolved path
}
```

## Platform Differences

The env package behaves differently across platforms:

### JavaScript Environment
- `args()` returns arguments from the JavaScript environment
- `@env.now()` uses `Date.@env.now()` 
- `@env.current_dir()` may return `None` in browser environments

### WebAssembly Environment  
- `args()` behavior depends on the WASM host
- `@env.now()` provides millisecond precision timing
- `@env.current_dir()` availability depends on host capabilities

### Native Environment
- `args()` returns actual command line arguments
- `@env.now()` provides system time
- `@env.current_dir()` uses system calls to get working directory

## Error Handling

Handle cases where environment information is unavailable:

```moonbit
///|
test "error handling" {
  fn safe_get_cwd() -> String {
    match @env.current_dir() {
      Some(path) => path
      None =>
        // Fallback when current directory is unavailable
        "."
    }
  }

  let safe_cwd = safe_get_cwd()
  inspect(safe_cwd.length() > 0, content="true")
  fn validate_args(
    args : Array[String],
    min_count : Int,
  ) -> Result[Unit, String] {
    if args.length() < min_count {
      Err("Insufficient arguments: expected at least " + min_count.to_string())
    } else {
      Ok(())
    }
  }

  let validation = validate_args(["prog"], 2)
  match validation {
    Ok(_) => inspect(false, content="true")
    Err(msg) => inspect(msg.length() > 10, content="true") // Should have error message
  }
}
```

## Best Practices

### 1. Handle Missing Environment Data Gracefully

```moonbit
///|
test "graceful handling" {
  fn get_work_dir() -> String {
    match @env.current_dir() {
      Some(dir) => dir
      None => "~" // Fallback to home directory symbol
    }
  }

  let work_dir = get_work_dir()
  inspect(work_dir.length() > 0, content="true")
}
```

### 2. Validate Command Line Arguments

```moonbit
///|
test "argument validation" {
  fn validate_and_parse_args(
    args : Array[String],
  ) -> Result[(String, Array[String]), String] {
    if args.length() == 0 {
      Err("No program name available")
    } else if args.length() == 1 {
      Ok((args[0], [])) // Program name only, no arguments
    } else {
      let program = args[0]
      let arguments = Array::new()
      for i in 1..<args.length() {
        arguments.push(args[i])
      }
      Ok((program, arguments))
    }
  }

  let test_result = validate_and_parse_args(["myprogram", "arg1", "arg2"])
  match test_result {
    Ok((prog, args)) => {
      inspect(prog, content="myprogram")
      inspect(args.length(), content="2")
    }
    Err(_) => inspect(false, content="true")
  }
}
```

### 3. Use Timestamps for Unique Identifiers

```moonbit
///|
test "unique identifiers" {
  fn generate_unique_id(prefix : String) -> String {
    prefix + "_" + @env.now().to_string()
  }

  let id1 = generate_unique_id("task")
  let id2 = generate_unique_id("task")
  inspect(id1.length() > 10, content="true") // Should have task prefix and timestamp
  inspect(id2.length() > 10, content="true") // Should have task prefix and timestamp
  // IDs should be different (though they might be the same in fast tests)
}
```

## Common Use Cases

1. **Command Line Tools**: Parse arguments and provide help/usage information
2. **Configuration Management**: Load config files relative to current directory
3. **Logging Systems**: Add timestamps to log entries
4. **File Processing**: Resolve relative file paths
5. **Debugging**: Include environment information in error reports
6. **Build Tools**: Determine working directory for relative path operations

## Performance Considerations

- `args()` is typically called once at program startup
- `@env.now()` is lightweight but avoid calling in tight loops if high precision isn't needed
- `@env.current_dir()` may involve system calls, so cache the result if used frequently
- Environment functions are generally fast but platform-dependent

The env package provides essential runtime environment access for building robust MoonBit applications that interact with their execution environment.
