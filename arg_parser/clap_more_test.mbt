///|
test "help plain" {
  let cmd = @arg_parser.Command::new("demo")
    .about("demo")
    .arg(@arg_parser.Arg::new("count").long("count").option())
    .arg(@arg_parser.Arg::new("name").index(0))
  let res : Result[@arg_parser.Matches, @arg_parser.CommandError] = try? cmd.parse(argv=[
      "--help",
    ],
  )
  let text = match res {
    Ok(_) => panic()
    Err(@arg_parser.CommandError::Help(t)) => t
    Err(_) => panic()
  }
  inspect(text.contains("Usage: demo"), content="true")
  inspect(text.contains("Options:"), content="true")
}

///|
test "help man" {
  let cmd = @arg_parser.Command::new("demo").about("demo")
  let res : Result[@arg_parser.Matches, @arg_parser.CommandError] = try? cmd.parse(argv=[
      "--help=man",
    ],
  )
  let text = match res {
    Ok(_) => panic()
    Err(@arg_parser.CommandError::Help(t)) => t
    Err(_) => panic()
  }
  inspect(text.contains("NAME"), content="true")
  inspect(text.contains("SYNOPSIS"), content="true")
  inspect(text.contains("OPTIONS"), content="true")
}

///|
test "user handles --version" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("version").long("version").help("show version"),
  )
  let matches = cmd.parse(argv=["--version"]) catch { _ => panic() }
  assert_true(matches.get_flag("version"))
}

///|
test "long inline value" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("count").long("count").option(),
  )
  let matches = cmd.parse(argv=["--count=3"]) catch { _ => panic() }
  assert_eq(matches.value_of("count").unwrap(), "3")
}

///|
test "missing value for option" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("count").long("count").option(),
  )
  let mut saw = false
  let _ = cmd.parse(argv=["--count"]) catch {
    @arg_parser.CommandError::Arg(@arg_parser.ArgumentError::MissingValue(opt)) => {
      saw = true
      assert_eq(opt, "--count")
      @arg_parser.Matches::new()
    }
    _ => panic()
  }
  assert_true(saw)
}

///|
test "unknown option" {
  let cmd = @arg_parser.Command::new("demo")
  let mut saw = false
  let _ = cmd.parse(argv=["--nope"]) catch {
    @arg_parser.CommandError::Arg(
      @arg_parser.ArgumentError::UnknownArgument(opt, _)
    ) => {
      saw = true
      assert_eq(opt, "--nope")
      @arg_parser.Matches::new()
    }
    _ => panic()
  }
  assert_true(saw)
}

///|
test "unknown option suggests closest" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("verbose").long("verbose"),
  )
  let mut saw = false
  let _ = cmd.parse(argv=["--verbsoe"]) catch {
    @arg_parser.CommandError::Arg(
      @arg_parser.ArgumentError::UnknownArgument(arg, hint)
    ) => {
      saw = true
      assert_eq(arg, "--verbsoe")
      assert_eq(hint.unwrap(), "--verbose")
      @arg_parser.Matches::new()
    }
    _ => panic()
  }
  assert_true(saw)
}

///|
test "env fallback for option" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("mode")
    .long("mode")
    .option()
    .env("MODE")
    .default_value("slow"),
  )
  let matches = cmd.parse(argv=[], env={ "MODE": "fast" }) catch {
    _ => panic()
  }
  assert_eq(matches.value_of("mode").unwrap(), "fast")
  assert_eq(matches.source_of("mode").unwrap().to_string(), "Env")
}

///|
test "argv overrides env" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("mode")
    .long("mode")
    .option()
    .env("MODE")
    .default_value("slow"),
  )
  let matches = cmd.parse(argv=["--mode", "slow"], env={ "MODE": "fast" }) catch {
    _ => panic()
  }
  assert_eq(matches.value_of("mode").unwrap(), "slow")
  assert_eq(matches.source_of("mode").unwrap().to_string(), "Argv")
}

///|
test "env flag enables boolean" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("verbose").long("verbose").env("VERBOSE"),
  )
  let matches = cmd.parse(argv=[], env={ "VERBOSE": "1" }) catch {
    _ => panic()
  }
  assert_true(matches.get_flag("verbose"))
  assert_eq(matches.source_of("verbose").unwrap().to_string(), "Env")
}

///|
test "default value for option" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("mode").long("mode").option().default_value("fast"),
  )
  let matches = cmd.parse(argv=[]) catch { _ => panic() }
  assert_eq(matches.value_of("mode").unwrap(), "fast")
  assert_eq(matches.source_of("mode").unwrap().to_string(), "Default")
}

///|
test "default value for positional" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("name").index(0).default_value("guest"),
  )
  let matches = cmd.parse(argv=[]) catch { _ => panic() }
  assert_eq(matches.value_of("name").unwrap(), "guest")
  assert_eq(matches.source_of("name").unwrap().to_string(), "Default")
}

///|
test "-- terminator treats following args as positional" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("name").index(0),
  )
  let matches = cmd.parse(argv=["--", "--count"]) catch { _ => panic() }
  assert_eq(matches.value_of("name").unwrap(), "--count")
}

///|
test "negative number positional parses without --" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("num").index(0),
  )
  let matches = cmd.parse(argv=["-12"]) catch { _ => panic() }
  assert_eq(matches.value_of("num").unwrap(), "-12")
}

///|
test "allow hyphen positional accepts dash values" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("name").index(0).allow_hyphen_values(),
  )
  let matches = cmd.parse(argv=["-file"]) catch { _ => panic() }
  assert_eq(matches.value_of("name").unwrap(), "-file")
}

///|
test "last positional captures option-like tokens" {
  let cmd = @arg_parser.Command::new("demo")
    .arg(@arg_parser.Arg::new("cmd").index(0))
    .arg(@arg_parser.Arg::new("args").index(1).multiple().last())
    .arg(@arg_parser.Arg::new("verbose").long("verbose"))
  let matches = cmd.parse(argv=["run", "--verbose", "-x"]) catch {
    _ => panic()
  }
  assert_eq(matches.value_of("cmd").unwrap(), "run")
  let rest = matches.values_of("args").unwrap()
  inspect(rest, content="[\"--verbose\", \"-x\"]")
  assert_false(matches.get_flag("verbose"))
}

///|
test "too many positional args" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("name").index(0),
  )
  let mut saw = false
  let _ = cmd.parse(argv=["a", "b"]) catch {
    @arg_parser.CommandError::Arg(@arg_parser.ArgumentError::TooManyPositionals) => {
      saw = true
      @arg_parser.Matches::new()
    }
    _ => panic()
  }
  assert_true(saw)
}

///|
test "multiple named values" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("tag").long("tag").option().multiple(),
  )
  let matches = cmd.parse(argv=["--tag", "a", "--tag", "b"]) catch {
    _ => panic()
  }
  let values = matches.values_of("tag").unwrap()
  inspect(values, content="[\"a\", \"b\"]")
}

///|
test "multiple positional captures rest" {
  let cmd = @arg_parser.Command::new("demo")
    .arg(@arg_parser.Arg::new("first").index(0))
    .arg(@arg_parser.Arg::new("rest").index(1).multiple())
  let matches = cmd.parse(argv=["x", "y", "z"]) catch { _ => panic() }
  assert_eq(matches.value_of("first").unwrap(), "x")
  let rest = matches.values_of("rest").unwrap()
  inspect(rest, content="[\"y\", \"z\"]")
}

///|
test "subcommand help and man" {
  let sub = @arg_parser.Command::new("echo")
    .about("echo help")
    .arg(@arg_parser.Arg::new("msg").index(0))
  let root = @arg_parser.Command::new("root").about("root help").subcommand(sub)
  let res_plain : Result[@arg_parser.Matches, @arg_parser.CommandError] = try? root.parse(argv=[
      "echo", "--help",
    ],
  )
  let text_plain = match res_plain {
    Ok(_) => panic()
    Err(@arg_parser.CommandError::Help(t)) => t
    Err(_) => panic()
  }
  inspect(text_plain.contains("Usage: echo"), content="true")
  let res_man : Result[@arg_parser.Matches, @arg_parser.CommandError] = try? root.parse(argv=[
      "echo", "--help=man",
    ],
  )
  let text_man = match res_man {
    Ok(_) => panic()
    Err(@arg_parser.CommandError::Help(t)) => t
    Err(_) => panic()
  }
  inspect(text_man.contains("NAME"), content="true")
  inspect(text_man.contains("echo - echo help"), content="true")
}

///|
test "help subcommand shows target help" {
  let echo = @arg_parser.Command::new("echo").about("echo help")
  let tools = @arg_parser.Command::new("tools")
    .about("tools help")
    .subcommand(echo)
  let root = @arg_parser.Command::new("root")
    .about("root help")
    .subcommand(tools)
  let res_root : Result[@arg_parser.Matches, @arg_parser.CommandError] = try? root.parse(argv=[
      "help",
    ],
  )
  let text_root = match res_root {
    Ok(_) => panic()
    Err(@arg_parser.CommandError::Help(t)) => t
    Err(_) => panic()
  }
  inspect(text_root.contains("Usage: root"), content="true")
  let res_nested : Result[@arg_parser.Matches, @arg_parser.CommandError] = try? root.parse(argv=[
      "help", "tools", "echo",
    ],
  )
  let text_nested = match res_nested {
    Ok(_) => panic()
    Err(@arg_parser.CommandError::Help(t)) => t
    Err(_) => panic()
  }
  inspect(text_nested.contains("Usage: echo"), content="true")
  let res_man : Result[@arg_parser.Matches, @arg_parser.CommandError] = try? root.parse(argv=[
      "help", "tools", "echo", "--help=man",
    ],
  )
  let text_man = match res_man {
    Ok(_) => panic()
    Err(@arg_parser.CommandError::Help(t)) => t
    Err(_) => panic()
  }
  inspect(text_man.contains("NAME"), content="true")
  inspect(
    root.render_help().contains("Print help for the subcommand(s)."),
    content="true",
  )
}

///|
test "disable help subcommand allows custom help" {
  let custom = @arg_parser.Command::new("help").about("custom help")
  let root = @arg_parser.Command::new("root")
    .subcommand(custom)
    .disable_help_subcommand()
  let matches = root.parse(argv=["help"]) catch { _ => panic() }
  assert_eq(matches.subcommand_name().unwrap(), "help")
}

///|
test "non-multiple keeps last option value" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("tag").long("tag").option(),
  )
  let matches = cmd.parse(argv=["--tag", "a", "--tag", "b"]) catch {
    _ => panic()
  }
  let values = matches.values_of("tag").unwrap()
  inspect(values, content="[\"b\"]")
}

///|
test "short option takes value" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("count").short('c').option(),
  )
  let matches = cmd.parse(argv=["-c", "3"]) catch { _ => panic() }
  assert_eq(matches.value_of("count").unwrap(), "3")
}

///|
test "short option attached value" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("count").short('c').option(),
  )
  let matches = cmd.parse(argv=["-c3"]) catch { _ => panic() }
  assert_eq(matches.value_of("count").unwrap(), "3")
}

///|
test "short group combines flags" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("verbose").short('v'),
  )
  let matches = cmd.parse(argv=["-vv"]) catch { _ => panic() }
  assert_true(matches.get_flag("verbose"))
}

///|
test "count action increments on repeats" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("verbose")
    .short('v')
    .long("verbose")
    .action(@arg_parser.ArgAction::Count),
  )
  let matches = cmd.parse(argv=["-vvv", "--verbose"]) catch { _ => panic() }
  assert_eq(matches.count_of("verbose"), 4)
  assert_true(matches.get_flag("verbose"))
}

///|
test "short group unknown flag errors" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("verbose").short('v'),
  )
  let mut saw = false
  let _ = cmd.parse(argv=["-vz"]) catch {
    @arg_parser.CommandError::Arg(
      @arg_parser.ArgumentError::UnknownArgument(arg, _)
    ) => {
      saw = true
      assert_eq(arg, "-z")
      @arg_parser.Matches::new()
    }
    _ => panic()
  }
  assert_true(saw)
}

///|
test "negatable flag" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("verbose").long("verbose").negatable(),
  )
  let matches = cmd.parse(argv=["--no-verbose"]) catch { _ => panic() }
  assert_false(matches.get_flag("verbose"))
}

///|
test "no- flag rejected when not negatable" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("verbose").long("verbose"),
  )
  let mut saw = false
  let _ = cmd.parse(argv=["--no-verbose"]) catch {
    @arg_parser.CommandError::Arg(
      @arg_parser.ArgumentError::UnknownArgument(arg, _)
    ) => {
      saw = true
      assert_eq(arg, "--no-verbose")
      @arg_parser.Matches::new()
    }
    _ => panic()
  }
  assert_true(saw)
}

///|
test "global arg usable after subcommand when marked global" {
  let sub = @arg_parser.Command::new("echo").arg(
    @arg_parser.Arg::new("msg").index(0),
  )
  let root = @arg_parser.Command::new("root")
    .arg(@arg_parser.Arg::new("verbose").long("verbose").global())
    .subcommand(sub)
  let matches = root.parse(argv=["echo", "--verbose", "hi"]) catch {
    _ => panic()
  }
  assert_true(matches.get_flag("verbose"))
  let subm = matches.subcommand_matches("echo").unwrap()
  assert_true(subm.get_flag("verbose"))
}

///|
test "root arg after subcommand errors when not global" {
  let sub = @arg_parser.Command::new("echo").arg(
    @arg_parser.Arg::new("msg").index(0),
  )
  let root = @arg_parser.Command::new("root")
    .arg(@arg_parser.Arg::new("verbose").long("verbose"))
    .subcommand(sub)
  let mut saw = false
  let _ = root.parse(argv=["echo", "--verbose", "hi"]) catch {
    @arg_parser.CommandError::Arg(
      @arg_parser.ArgumentError::UnknownArgument(arg, _)
    ) => {
      saw = true
      assert_eq(arg, "--verbose")
      @arg_parser.Matches::new()
    }
    _ => panic()
  }
  assert_true(saw)
}

///|
test "global arg propagates into subcommand matches" {
  let sub = @arg_parser.Command::new("echo").arg(
    @arg_parser.Arg::new("msg").index(0),
  )
  let root = @arg_parser.Command::new("root")
    .arg(@arg_parser.Arg::new("verbose").long("verbose").global())
    .subcommand(sub)
  let matches = root.parse(argv=["--verbose", "echo", "hi"]) catch {
    _ => panic()
  }
  let subm = matches.subcommand_matches("echo").unwrap()
  assert_true(subm.get_flag("verbose"))
}

///|
test "short option takes value with equals" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("count").short('c').option(),
  )
  let matches = cmd.parse(argv=["-c=3"]) catch { _ => panic() }
  assert_eq(matches.value_of("count").unwrap(), "3")
}

///|
test "short group with value attached" {
  let cmd = @arg_parser.Command::new("demo")
    .arg(@arg_parser.Arg::new("verbose").short('v'))
    .arg(@arg_parser.Arg::new("count").short('c').option())
  let matches = cmd.parse(argv=["-vc3"]) catch { _ => panic() }
  assert_true(matches.get_flag("verbose"))
  assert_eq(matches.value_of("count").unwrap(), "3")
}

///|
test "short group with value in next argv" {
  let cmd = @arg_parser.Command::new("demo")
    .arg(@arg_parser.Arg::new("verbose").short('v'))
    .arg(@arg_parser.Arg::new("count").short('c').option())
  let matches = cmd.parse(argv=["-vc", "3"]) catch { _ => panic() }
  assert_true(matches.get_flag("verbose"))
  assert_eq(matches.value_of("count").unwrap(), "3")
}

///|
test "negation rejects inline values" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("verbose").long("verbose").negatable(),
  )
  let mut saw = false
  let _ = cmd.parse(argv=["--no-verbose=true"]) catch {
    @arg_parser.CommandError::Arg(
      @arg_parser.ArgumentError::InvalidArgument(arg)
    ) => {
      saw = true
      assert_eq(arg, "--no-verbose=true")
      @arg_parser.Matches::new()
    }
    _ => panic()
  }
  assert_true(saw)
}

///|
test "global option last wins across subcommand boundary" {
  let sub = @arg_parser.Command::new("run")
  let root = @arg_parser.Command::new("root")
    .arg(@arg_parser.Arg::new("config").long("config").option().global())
    .subcommand(sub)
  let matches = root.parse(argv=["--config", "a", "run", "--config", "b"]) catch {
    _ => panic()
  }
  assert_eq(matches.value_of("config").unwrap(), "b")
  let subm = matches.subcommand_matches("run").unwrap()
  assert_eq(subm.value_of("config").unwrap(), "b")
}

///|
test "global option merges multiple values" {
  let sub = @arg_parser.Command::new("run")
  let root = @arg_parser.Command::new("root")
    .arg(@arg_parser.Arg::new("tag").long("tag").option().multiple().global())
    .subcommand(sub)
  let matches = root.parse(argv=["--tag", "a", "run", "--tag", "b"]) catch {
    _ => panic()
  }
  inspect(matches.values_of("tag").unwrap(), content="[\"a\", \"b\"]")
  let subm = matches.subcommand_matches("run").unwrap()
  inspect(subm.values_of("tag").unwrap(), content="[\"a\", \"b\"]")
}

///|
test "arg long alias parses" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("color").long("color").option().alias_name("colour"),
  )
  let matches = cmd.parse(argv=["--colour", "blue"]) catch { _ => panic() }
  assert_eq(matches.value_of("color").unwrap(), "blue")
}

///|
test "arg visible alias shows in help" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("color").long("color").visible_alias("colour"),
  )
  let text = cmd.render_help()
  assert_true(text.contains("--colour"))
}

///|
test "command alias parses" {
  let sub = @arg_parser.Command::new("run").alias_name("r")
  let root = @arg_parser.Command::new("root").subcommand(sub)
  let matches = root.parse(argv=["r"]) catch { _ => panic() }
  assert_eq(matches.subcommand_name().unwrap(), "run")
}

///|
test "command visible alias shows in help" {
  let sub = @arg_parser.Command::new("run").visible_alias("r")
  let root = @arg_parser.Command::new("root").subcommand(sub)
  let text = root.render_help()
  assert_true(text.contains("run, r"))
}

///|
test "required arg group errors when empty" {
  let cmd = @arg_parser.Command::new("demo")
    .group(@arg_parser.ArgGroup::new("mode").required())
    .arg(@arg_parser.Arg::new("fast").long("fast").group("mode"))
    .arg(@arg_parser.Arg::new("slow").long("slow").group("mode"))
  let mut saw = false
  let _ = cmd.parse(argv=[]) catch {
    @arg_parser.CommandError::Arg(@arg_parser.ArgumentError::MissingGroup(name)) => {
      saw = true
      assert_eq(name, "mode")
      @arg_parser.Matches::new()
    }
    _ => panic()
  }
  assert_true(saw)
}

///|
test "exclusive arg group rejects multiple" {
  let cmd = @arg_parser.Command::new("demo")
    .group(@arg_parser.ArgGroup::new("mode").multiple(value=false))
    .arg(@arg_parser.Arg::new("fast").long("fast").group("mode"))
    .arg(@arg_parser.Arg::new("slow").long("slow").group("mode"))
  let mut saw = false
  let _ = cmd.parse(argv=["--fast", "--slow"]) catch {
    @arg_parser.CommandError::Arg(
      @arg_parser.ArgumentError::GroupConflict(name)
    ) => {
      saw = true
      assert_eq(name, "mode")
      @arg_parser.Matches::new()
    }
    _ => panic()
  }
  assert_true(saw)
}

///|
test "group accepts one member when exclusive" {
  let cmd = @arg_parser.Command::new("demo")
    .group(@arg_parser.ArgGroup::new("mode").multiple(value=false))
    .arg(@arg_parser.Arg::new("fast").long("fast").group("mode"))
    .arg(@arg_parser.Arg::new("slow").long("slow").group("mode"))
  let matches = cmd.parse(argv=["--fast"]) catch { _ => panic() }
  assert_true(matches.get_flag("fast"))
  assert_false(matches.get_flag("slow"))
}

///|
test "required option missing" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("mode").long("mode").option().required(),
  )
  let mut saw = false
  let _ = cmd.parse(argv=[]) catch {
    @arg_parser.CommandError::Arg(
      @arg_parser.ArgumentError::MissingRequired(name)
    ) => {
      saw = true
      assert_eq(name, "mode")
      @arg_parser.Matches::new()
    }
    _ => panic()
  }
  assert_true(saw)
}

///|
test "min and max values enforced" {
  let cmd = @arg_parser.Command::new("demo").arg(
    @arg_parser.Arg::new("tag")
    .long("tag")
    .option()
    .multiple()
    .min_values(2)
    .max_values(3),
  )
  let mut saw_too_few = false
  let _ = cmd.parse(argv=["--tag", "a"]) catch {
    @arg_parser.CommandError::Arg(
      @arg_parser.ArgumentError::TooFewValues(name, got, min)
    ) => {
      saw_too_few = true
      assert_eq(name, "tag")
      assert_eq(got, 1)
      assert_eq(min, 2)
      @arg_parser.Matches::new()
    }
    _ => panic()
  }
  assert_true(saw_too_few)
  let mut saw_too_many = false
  let _ = cmd.parse(argv=[
    "--tag", "a", "--tag", "b", "--tag", "c", "--tag", "d",
  ]) catch {
    @arg_parser.CommandError::Arg(
      @arg_parser.ArgumentError::TooManyValues(name, got, max)
    ) => {
      saw_too_many = true
      assert_eq(name, "tag")
      assert_eq(got, 4)
      assert_eq(max, 3)
      @arg_parser.Matches::new()
    }
    _ => panic()
  }
  assert_true(saw_too_many)
}

///|
test "duplicate long option errors" {
  let cmd = @arg_parser.Command::new("demo")
    .arg(@arg_parser.Arg::new("one").long("dup"))
    .arg(@arg_parser.Arg::new("two").long("dup"))
  let mut saw = false
  let _ = cmd.parse(argv=[]) catch {
    @arg_parser.CommandError::Build(@arg_parser.ArgBuildError::Unsupported(msg)) => {
      saw = true
      assert_true(msg.contains("duplicate long option"))
      @arg_parser.Matches::new()
    }
    _ => panic()
  }
  assert_true(saw)
}

///|
test "duplicate subcommand alias errors" {
  let sub1 = @arg_parser.Command::new("run").alias_name("r")
  let sub2 = @arg_parser.Command::new("redo").alias_name("r")
  let cmd = @arg_parser.Command::new("root").subcommand(sub1).subcommand(sub2)
  let mut saw = false
  let _ = cmd.parse(argv=[]) catch {
    @arg_parser.CommandError::Build(@arg_parser.ArgBuildError::Unsupported(msg)) => {
      saw = true
      assert_true(msg.contains("duplicate subcommand"))
      @arg_parser.Matches::new()
    }
    _ => panic()
  }
  assert_true(saw)
}
