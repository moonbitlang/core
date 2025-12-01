# Error Package Documentation

This package provides utilities for working with MoonBit's error handling system, including implementations of `Show` and `ToJson` traits for the built-in `Error` type.

## Basic Error Usage

MoonBit uses a structured error system with `raise` and `try` constructs:

```moonbit
///|
test "basic error handling" {
  fn divide(a : Int, b : Int) -> Int raise {
    if b == 0 {
      raise Failure("Division by zero")
    } else {
      a / b
    }
  }

  // Successful operation
  let result1 = try! divide(10, 2)
  inspect(result1, content="5")

  // Handle error with try?
  let result2 = try? divide(10, 0)
  inspect(result2, content="Err(Failure(\"Division by zero\"))")
}
```

## Custom Error Types

Define custom error types using `suberror`:

```moonbit
///|
suberror ValidationError String

///|
suberror NetworkError String

///|
test "custom errors" {
  fn validate_email(email : String) -> String raise ValidationError {
    if email.length() > 5 { // Simple validation without string methods
      email
    } else {
      raise ValidationError("Invalid email format")
    }
  }

  fn fetch_data(url : String) -> String raise NetworkError {
    if url.length() > 10 { // Simple validation
      "data"
    } else {
      raise NetworkError("Invalid URL")
    }
  }

  // Test validation error
  let email_result = try? validate_email("short")
  match email_result {
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect(true, content="true")
  }

  // Test network error  
  let data_result = try? fetch_data("short")
  match data_result {
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect(true, content="true")
  }
}
```

## Error Display and JSON Conversion

The error package provides `Show` and `ToJson` implementations:

```moonbit
///|
suberror MyError Int derive(ToJson)

///|
test "error display and json" {
  let error : Error = MyError(42)

  // Error can be displayed as string
  let error_string = error.to_string()
  inspect(error_string.length() > 0, content="true")

  // Error can be converted to JSON
  let error_json = error.to_json()
  inspect(error_json, content="Array([String(\"MyError\"), Number(42)])")
}
```

## Error Propagation and Handling

Handle errors at different levels of your application:

```moonbit
///|
suberror ParseError String

///|
suberror FileError String

///|
test "error propagation" {
  fn parse_number(s : String) -> Int raise ParseError {
    if s == "42" {
      42
    } else {
      raise ParseError("Invalid number: " + s)
    }
  }

  fn read_and_parse(content : String) -> Int raise {
    parse_number(content) catch {
      ParseError(msg) => raise FileError("Parse failed: " + msg)
    }
  }

  // Success case
  let result1 = try! read_and_parse("42")
  inspect(result1, content="42")

  // Error propagation
  let result2 = try? read_and_parse("invalid")
  match result2 {
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect(true, content="true")
  }
}
```

## Resource Management with Finally

Use `protect` functions for resource cleanup:

```moonbit
///|
suberror ResourceError String

///|
test "resource management" {
  fn risky_operation() -> String raise ResourceError {
    raise ResourceError("Something went wrong")
  }

  // Simple resource management pattern
  fn use_resource() -> String raise {
    // Acquire resource (simulated)
    risky_operation() catch {
      ResourceError(_) =>
        // Cleanup happens here
        raise Failure("Operation failed after cleanup")
    }
  }

  let result = try? use_resource()
  match result {
    Ok(_) => inspect(false, content="true")
    Err(_) => inspect(true, content="true")
  }
}
```

## Error Composition

Combine multiple error-producing operations:

```moonbit
///|
suberror ConfigError String

///|
suberror DatabaseError String

///|
test "error composition" {
  fn load_config() -> String raise ConfigError {
    if true {
      "config_data"
    } else {
      raise ConfigError("Config not found")
    }
  }

  fn connect_database(config : String) -> String raise DatabaseError {
    if config == "config_data" {
      "connected"
    } else {
      raise DatabaseError("Invalid config")
    }
  }

  fn initialize_app() -> String raise {
    let config = load_config() catch {
      ConfigError(msg) => raise Failure("Config error: " + msg)
    }
    let db = connect_database(config) catch {
      DatabaseError(msg) => raise Failure("Database error: " + msg)
    }
    "App initialized with " + db
  }

  let app_result = try! initialize_app()
  inspect(app_result, content="App initialized with connected")
}
```

## Best Practices

1. **Use specific error types**: Create custom `suberror` types for different error categories
2. **Provide meaningful messages**: Include context and actionable information in error messages
3. **Handle errors at appropriate levels**: Don't catch errors too early; let them propagate to where they can be properly handled
4. **Use `try!` for operations that should not fail**: This will panic if an error occurs, making failures visible during development
5. **Use `try?` for recoverable errors**: This returns a `Result` type that can be pattern matched
6. **Implement proper cleanup**: Use the `protect` pattern or similar constructs for resource management

## Performance Notes

- Error handling in MoonBit is zero-cost when no errors occur
- Error propagation is efficient and doesn't require heap allocation for the error path
- Custom error types with `derive(ToJson)` automatically generate efficient JSON serialization
