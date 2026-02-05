///|
/// Errors raised during parsing or decoding of arguments.
pub(all) suberror ArgumentError {
  UnknownArgument(String, String?)
  InvalidArgument(String)
  MissingValue(String)
  MissingRequired(String)
  TooFewValues(String, Int, Int)
  TooManyValues(String, Int, Int)
  TooManyPositionals
  InvalidValue(String)
  InvalidValueCount(String)
  MissingGroup(String)
  GroupConflict(String)
} derive(Show)

///|
/// Errors raised when building argument specifications.
pub suberror ArgBuildError {
  Unsupported(String)
} derive(Show)

///|
/// Errors raised when parsing command lines.
pub suberror CommandError {
  Arg(ArgumentError)
  Build(ArgBuildError)
  Help(String)
} derive(Show)
