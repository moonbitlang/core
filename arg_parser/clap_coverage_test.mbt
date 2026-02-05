///|
test "arg builders and defaults" {
  let arg = @arg_parser.Arg::new("verbose")
    .short('v')
    .short_alias('q')
    .visible_short_alias('w')
    .flag()
  let cmd = @arg_parser.Command::new("demo").arg(arg)
  let m = cmd.parse(argv=["-w"]) catch { _ => panic() }
  assert_true(m.get_flag("verbose"))
  let cmd2 = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("mode")
    .long("mode")
    .option()
    .multiple()
    .default_values(["a", "b"]),
  )
  let m2 = cmd2.parse(argv=[]) catch { _ => panic() }
  inspect(m2.values_of("mode").unwrap(), content="[\"a\", \"b\"]")
  let cmd3 = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("tag").long("tag").option().multiple().num_values(1, 2),
  )
  let m3 = cmd3.parse(argv=["--tag", "x"]) catch { _ => panic() }
  assert_eq(m3.value_of("tag").unwrap(), "x")
}

///|
test "help and man include groups and defaults" {
  let sub = @arg_parser.Command::new("sub").visible_alias("s")
  let cmd = @arg_parser.Command::new("demo")
    .subcommand(sub)
    .group(@arg_parser.ArgGroup::new("mode").required())
    .group(@arg_parser.ArgGroup::new("color").multiple(value=false))
    .group(@arg_parser.ArgGroup::new("misc"))
    .arg(@arg_parser.Arg::new("req").index(0).required())
    .arg(@arg_parser.Arg::new("rest").index(1).multiple().required())
    .arg(@arg_parser.Arg::new("extra").index(2).multiple())
    .arg(
      @arg_parser.Arg::new("flag")
      .short('f')
      .visible_short_alias('g')
      .long("flag")
      .negatable(),
    )
    .arg(
      @arg_parser.Arg::new("opt")
      .long("opt")
      .option()
      .default_value("v")
      .env("OPT")
      .help("optional value"),
    )
    .arg(
      @arg_parser.Arg::new("size")
      .long("size")
      .option()
      .default_values(["s", "m"])
      .group("misc"),
    )
    .arg(@arg_parser.Arg::new("pos").group("mode"))
    .arg(@arg_parser.Arg::new("fast").long("fast").group("mode"))
    .arg(@arg_parser.Arg::new("slow").long("slow").group("mode"))
    .arg(@arg_parser.Arg::new("red").long("red").group("color"))
    .arg(@arg_parser.Arg::new("blue").long("blue").group("color"))
  let help = cmd.render_help()
  assert_true(help.contains("Groups:"))
  assert_true(help.contains("Arguments:"))
  assert_true(help.contains("Commands:"))
  assert_true(help.contains("default: v"))
  assert_true(help.contains("required"))
  assert_true(help.contains("--[no-]flag"))
  let man = cmd.render_help(mode=@arg_parser.HelpMode::Man)
  assert_true(man.contains("GROUPS"))
  assert_true(man.contains("ARGUMENTS"))
  assert_true(man.contains("COMMANDS"))
}

///|
test "parse branches and env errors" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("verbose").short('v'),
  )
  let res : Result[@arg_parser.Matches, @arg_parser.CommandError] = try? cmd.parse(argv=[
      "-vh",
    ],
  )
  match res {
    Err(@arg_parser.CommandError::Help(text)) =>
      assert_true(text.contains("Usage:"))
    _ => panic()
  }
  let cmd2 = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("count").short('c').option(),
  )
  let mut saw_missing = false
  let _ = cmd2.parse(argv=["-c"]) catch {
    @arg_parser.CommandError::Arg(@arg_parser.ArgumentError::MissingValue(opt)) => {
      saw_missing = true
      assert_eq(opt, "-c")
      @arg_parser.Matches::new()
    }
    _ => panic()
  }
  assert_true(saw_missing)
  let cmd3 = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("flag")
    .long("flag")
    .negatable()
    .action(@arg_parser.ArgAction::SetFalse),
  )
  let m3 = cmd3.parse(argv=["--no-flag"]) catch { _ => panic() }
  assert_true(m3.get_flag("flag"))
  let cmd4 = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("flag")
    .long("flag")
    .option()
    .action(@arg_parser.ArgAction::SetTrue),
  )
  let mut saw_invalid = false
  let _ = cmd4.parse(argv=["--flag", "maybe"]) catch {
    @arg_parser.CommandError::Arg(@arg_parser.ArgumentError::InvalidValue(msg)) => {
      saw_invalid = true
      assert_true(msg.contains("invalid bool"))
      @arg_parser.Matches::new()
    }
    _ => panic()
  }
  assert_true(saw_invalid)
  let cmd5 = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("verbose").long("verbose").env("VERBOSE"),
  )
  let mut saw_env_invalid = false
  let _ = cmd5.parse(argv=[], env={ "VERBOSE": "nope" }) catch {
    @arg_parser.CommandError::Arg(@arg_parser.ArgumentError::InvalidValue(msg)) => {
      saw_env_invalid = true
      assert_true(msg.contains("invalid bool"))
      @arg_parser.Matches::new()
    }
    _ => panic()
  }
  assert_true(saw_env_invalid)
  let cmd6 = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("mode").long("mode").option().env("MODE"),
  )
  let m6 = cmd6.parse(argv=[], env={}) catch { _ => panic() }
  match m6.value_of("mode") {
    None => ()
    Some(_) => panic()
  }
}

///|
test "global aliases and merge semantics" {
  let sub = @arg_parser.Command::new("run")
  let root = @arg_parser.Command::new("root")
    .arg(
      @arg_parser.Arg::new("color")
      .long("color")
      .alias_name("colour")
      .visible_alias("hue")
      .short('c')
      .short_alias('C')
      .visible_short_alias('H')
      .global(),
    )
    .arg(@arg_parser.Arg::new("config").long("config").option().global())
    .arg(
      @arg_parser.Arg::new("verbose")
      .short('v')
      .action(@arg_parser.ArgAction::Count)
      .global(),
    )
    .subcommand(sub)
  let matches = root.parse(argv=[
    "--hue", "--config", "a", "-v", "run", "-v", "-v",
  ]) catch {
    _ => panic()
  }
  assert_true(matches.get_flag("color"))
  assert_eq(matches.value_of("config").unwrap(), "a")
  assert_eq(matches.count_of("verbose"), 3)
  let subm = matches.subcommand_matches("run").unwrap()
  assert_true(subm.get_flag("color"))
  assert_eq(subm.value_of("config").unwrap(), "a")
  assert_eq(subm.count_of("verbose"), 3)
}

///|
test "unknown short without hint" {
  let cmd = @arg_parser.Command::new("demo")
  let mut saw = false
  let _ = cmd.parse(argv=["-z"]) catch {
    @arg_parser.CommandError::Arg(
      @arg_parser.ArgumentError::UnknownArgument(arg, hint)
    ) => {
      saw = true
      assert_eq(arg, "-z")
      match hint {
        None => ()
        Some(_) => panic()
      }
      @arg_parser.Matches::new()
    }
    _ => panic()
  }
  assert_true(saw)
}

///|
test "positionals ordering and hyphen values" {
  let cmd = @arg_parser.Command::new("demo")
    .arg(@arg_parser.Arg::new("b").index(1))
    .arg(@arg_parser.Arg::new("a").index(0))
    .arg(@arg_parser.Arg::new("rest").multiple())
  let m = cmd.parse(argv=["x", "y", "z"]) catch { _ => panic() }
  assert_eq(m.value_of("a").unwrap(), "x")
  assert_eq(m.value_of("b").unwrap(), "y")
  inspect(m.values_of("rest").unwrap(), content="[\"z\"]")
  let cmd2 = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("name").index(0).allow_hyphen_values(),
  )
  let m2 = cmd2.parse(argv=["--file"]) catch { _ => panic() }
  assert_eq(m2.value_of("name").unwrap(), "--file")
}

///|
test "matches helpers" {
  let m = @arg_parser.Matches::new()
  match m.value_of("x") {
    None => ()
    Some(_) => panic()
  }
  match m.source_of("x") {
    None => ()
    Some(_) => panic()
  }
  match m.value_sources_of("x") {
    None => ()
    Some(_) => panic()
  }
  match m.subcommand_name() {
    None => ()
    Some(_) => panic()
  }
  match m.subcommand_matches("x") {
    None => ()
    Some(_) => panic()
  }
  let mut saw_missing = false
  let _ : String = m.get_one("x") catch {
    @arg_parser.ArgumentError::InvalidValue(_) => {
      saw_missing = true
      ""
    }
    _ => panic()
  }
  assert_true(saw_missing)
  let opt : String? = m.get_option("x") catch { _ => None }
  match opt {
    None => ()
    Some(_) => panic()
  }
  let arr : Array[String] = m.get_array("x")
  inspect(arr, content="[]")
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("tag").long("tag").option().multiple(),
  )
  let m2 = cmd.parse(argv=["--tag", "1", "--tag", "2"]) catch { _ => panic() }
  let mut saw_count = false
  let _opt : String? = m2.get_option("tag") catch {
    @arg_parser.ArgumentError::InvalidValueCount(_) => {
      saw_count = true
      None
    }
    _ => panic()
  }
  assert_true(saw_count)
  let mut saw_one = false
  let _one : String = m2.get_one("tag") catch {
    @arg_parser.ArgumentError::InvalidValueCount(_) => {
      saw_one = true
      ""
    }
    _ => panic()
  }
  assert_true(saw_one)
  let tags : Array[String] = m2.get_array("tag")
  inspect(tags, content="[\"1\", \"2\"]")
  let cmd2 = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("flag").long("flag").option(),
  )
  let m3 = cmd2.parse(argv=["--flag", "maybe"]) catch { _ => panic() }
  assert_eq(m3.get_one("flag") catch { _ => "" }, "maybe")
  let m_true = cmd2.parse(argv=["--flag", "true"]) catch { _ => panic() }
  assert_eq(m_true.get_one("flag") catch { _ => "" }, "true")
  let m_false = cmd2.parse(argv=["--flag", "false"]) catch { _ => panic() }
  assert_eq(m_false.get_one("flag") catch { _ => "" }, "false")
}

///|
test "command args builder" {
  let cmd = @arg_parser.Command::new("demo").args([
    @arg_parser.Arg::new("a").long("a"),
    @arg_parser.Arg::new("b").long("b"),
  ])
  let m = cmd.parse(argv=["--a", "--b"]) catch { _ => panic() }
  assert_true(m.get_flag("a"))
  assert_true(m.get_flag("b"))
}
