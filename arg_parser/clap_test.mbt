///|
test "clap builder parsing" {
  let cmd = @arg_parser.Command::new("demo")
    .about("demo")
    .arg(
      @arg_parser.Arg::new("verbose")
      .short('v')
      .long("verbose")
      .action(@arg_parser.ArgAction::SetTrue),
    )
    .arg(@arg_parser.Arg::new("count").long("count").option())
    .arg(@arg_parser.Arg::new("name").index(0))
  let matches = cmd.parse(argv=["-v", "--count", "3", "alice"]) catch {
    _ => panic()
  }
  assert_true(matches.get_flag("verbose"))
  assert_eq(matches.value_of("count").unwrap(), "3")
  assert_eq(matches.value_of("name").unwrap(), "alice")
}

///|
test "clap subcommand" {
  let sub = @arg_parser.Command::new("echo").arg(
    @arg_parser.Arg::new("msg").index(0),
  )
  let cmd = @arg_parser.Command::new("root").subcommand(sub)
  let matches = cmd.parse(argv=["echo", "hi"]) catch { _ => panic() }
  assert_eq(matches.subcommand_name().unwrap(), "echo")
  let subm = matches.subcommand_matches("echo").unwrap()
  assert_eq(subm.value_of("msg").unwrap(), "hi")
}
