// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
/// Render short help text for a clap-style command.
fn render_help_short(cmd : Command) -> String {
  render_help_with_style(cmd, false)
}

///|
/// Render long help text for a clap-style command.
fn render_help_long(cmd : Command) -> String {
  render_help_with_style(cmd, true)
}

///|
fn render_help_with_style(cmd : Command, long_help : Bool) -> String {
  let lines = Array::new(capacity=16)
  lines.push("Usage: " + cmd.name + usage_tail(cmd, long_help))
  let about = command_about(cmd, long_help)
  if about != "" {
    lines.push("")
    lines.push(about)
  }
  lines.push("")
  let sub_entries = subcommand_entries(cmd, long_help)
  if sub_entries.length() > 0 {
    lines.push("Commands:")
    for entry in sub_entries {
      lines.push(entry)
    }
    lines.push("")
  }
  if has_positionals(cmd, long_help) {
    lines.push("Arguments:")
    for entry in positional_entries(cmd, long_help) {
      lines.push(entry)
    }
    lines.push("")
  }
  lines.push("Options:")
  for entry in option_entries(cmd, long_help) {
    lines.push(entry)
  }
  let groups = group_entries(cmd, long_help)
  if groups.length() > 0 {
    lines.push("")
    lines.push("Groups:")
    for entry in groups {
      lines.push(entry)
    }
  }
  lines.join("\n")
}

///|
fn usage_tail(cmd : Command, long_help : Bool) -> String {
  let mut tail = ""
  if has_options(cmd, long_help) {
    tail = tail + " [options]"
  }
  if has_subcommands_for_help(cmd, long_help) {
    tail = tail + " <command>"
  }
  let pos = positional_usage(cmd, long_help)
  if pos != "" {
    tail = tail + " " + pos
  }
  tail
}

///|
fn has_options(cmd : Command, long_help : Bool) -> Bool {
  for arg in command_args(cmd) {
    if arg_hidden_in_style(arg, long_help) {
      continue
    }
    if arg.long is Some(_) || arg.short is Some(_) {
      return true
    }
  }
  false
}

///|
fn positional_usage(cmd : Command, long_help : Bool) -> String {
  let parts = Array::new(capacity=command_args(cmd).length())
  for arg in positional_args(command_args(cmd)) {
    if arg_hidden_in_style(arg, long_help) {
      continue
    }
    let required = is_required_arg(arg)
    if arg.multiple {
      if required {
        parts.push("<" + arg.name + "...>")
      } else {
        parts.push("[" + arg.name + "...]")
      }
    } else if required {
      parts.push("<" + arg.name + ">")
    } else {
      parts.push("[" + arg.name + "]")
    }
  }
  parts.join(" ")
}

///|
fn has_positionals(cmd : Command, long_help : Bool) -> Bool {
  for arg in command_args(cmd) {
    if is_positional_arg(arg) && !arg_hidden_in_style(arg, long_help) {
      return true
    }
  }
  false
}

///|
fn option_entries(cmd : Command, long_help : Bool) -> Array[String] {
  let args = command_args(cmd)
  let entries = Array::new(capacity=args.length() + 2)
  let display = Array::new(capacity=args.length() + 2)
  let builtin_help_short = help_flag_enabled(cmd) &&
    !has_short_option(args, 'h')
  let builtin_help_long = help_flag_enabled(cmd) &&
    !has_long_option(args, "help")
  let builtin_version_short = version_flag_enabled(cmd) &&
    !has_short_option(args, 'V')
  let builtin_version_long = version_flag_enabled(cmd) &&
    !has_long_option(args, "version")
  let builtin_help_label = builtin_option_label(
    builtin_help_short, builtin_help_long, "-h", "--help",
  )
  if builtin_help_label is Some(label) {
    display.push((label, "Show help information."))
  }
  let builtin_version_label = builtin_option_label(
    builtin_version_short, builtin_version_long, "-V", "--version",
  )
  if builtin_version_label is Some(label) {
    display.push((label, "Show version information."))
  }
  for arg in args {
    if arg.long is None && arg.short is None {
      continue
    }
    if arg_hidden_in_style(arg, long_help) {
      continue
    }
    let mut name = arg_display(arg)
    if arg_takes_value(arg) {
      name = name + " <" + arg.name + ">"
    }
    let doc = arg_doc(arg, long_help)
    display.push((name, doc))
  }
  let mut max_len = 0
  for item in display {
    let (name, _) = item
    if name.length() > max_len {
      max_len = name.length()
    }
  }
  for item in display {
    let (name, doc) = item
    let padding = " ".repeat(max_len - name.length() + 2)
    entries.push("  " + name + padding + doc)
  }
  entries
}

///|
fn has_long_option(args : Array[Arg], name : String) -> Bool {
  for arg in args {
    if arg.long is Some(long) && long == name {
      return true
    }
  }
  false
}

///|
fn has_short_option(args : Array[Arg], value : Char) -> Bool {
  for arg in args {
    if arg.short is Some(short) && short == value {
      return true
    }
  }
  false
}

///|
fn builtin_option_label(
  has_short : Bool,
  has_long : Bool,
  short_label : String,
  long_label : String,
) -> String? {
  if has_short && has_long {
    Some(short_label + ", " + long_label)
  } else if has_short {
    Some(short_label)
  } else if has_long {
    Some(long_label)
  } else {
    None
  }
}

///|
fn positional_entries(cmd : Command, long_help : Bool) -> Array[String] {
  let entries = Array::new(capacity=command_args(cmd).length())
  let display = Array::new(capacity=command_args(cmd).length())
  for arg in positional_args(command_args(cmd)) {
    if arg_hidden_in_style(arg, long_help) {
      continue
    }
    let name = positional_display(arg)
    let doc = arg_doc(arg, long_help)
    display.push((name, doc))
  }
  let mut max_len = 0
  for item in display {
    let (name, _) = item
    if name.length() > max_len {
      max_len = name.length()
    }
  }
  for item in display {
    let (name, doc) = item
    let padding = " ".repeat(max_len - name.length() + 2)
    entries.push("  " + name + padding + doc)
  }
  entries
}

///|
fn subcommand_entries(cmd : Command, long_help : Bool) -> Array[String] {
  let display = Array::new(capacity=cmd.subcommands.length() + 1)
  for sub in cmd.subcommands {
    if command_hidden_in_style(sub, long_help) {
      continue
    }
    display.push((command_display(sub), command_about(sub, long_help)))
  }
  if help_subcommand_enabled(cmd) {
    display.push(("help", "Print help for the subcommand(s)."))
  }
  let mut max_len = 0
  for item in display {
    let (name, _) = item
    if name.length() > max_len {
      max_len = name.length()
    }
  }
  let entries = Array::new(capacity=display.length())
  for item in display {
    let (name, doc) = item
    let padding = " ".repeat(max_len - name.length() + 2)
    entries.push("  " + name + padding + doc)
  }
  entries
}

///|
fn group_entries(cmd : Command, long_help : Bool) -> Array[String] {
  let entries = Array::new(capacity=command_groups(cmd).length())
  let display = Array::new(capacity=command_groups(cmd).length())
  for group in command_groups(cmd) {
    let name = group_label(group)
    let members = group_members(cmd, group, long_help)
    if members == "" {
      continue
    }
    display.push((name, members))
  }
  let mut max_len = 0
  for item in display {
    let (name, _) = item
    if name.length() > max_len {
      max_len = name.length()
    }
  }
  for item in display {
    let (name, members) = item
    let padding = " ".repeat(max_len - name.length() + 2)
    entries.push("  " + name + padding + members)
  }
  entries
}

///|
fn command_display(cmd : Command) -> String {
  cmd.name
}

///|
fn arg_display(arg : Arg) -> String {
  let parts = Array::new(capacity=2)
  if arg.short is Some(short) {
    parts.push("-" + short.to_string())
  }
  if arg.long is Some(long) {
    if arg.negatable && !arg_takes_value(arg) {
      parts.push("--[no-]" + long)
    } else {
      parts.push("--" + long)
    }
  }
  if parts.length() == 0 {
    arg.name
  } else {
    parts.join(", ")
  }
}

///|
fn positional_display(arg : Arg) -> String {
  if arg.multiple {
    arg.name + "..."
  } else {
    arg.name
  }
}

///|
fn command_about(cmd : Command, long_help : Bool) -> String {
  let _ = long_help
  cmd.about.unwrap_or("")
}

///|
fn arg_help(arg : Arg, long_help : Bool) -> String {
  let _ = long_help
  arg.about.unwrap_or("")
}

///|
fn arg_doc(arg : Arg, long_help : Bool) -> String {
  let notes = []
  match arg.env {
    Some(env_name) => notes.push("env: " + env_name)
    None => ()
  }
  match arg.default_values {
    Some(values) if values.length() > 1 =>
      notes.push("defaults: " + values.join(", "))
    Some(values) if values.length() == 1 => notes.push("default: " + values[0])
    _ => ()
  }
  if is_required_arg(arg) {
    notes.push("required")
  }
  let help = arg_help(arg, long_help)
  if help == "" {
    notes.join(", ")
  } else if notes.length() > 0 {
    help + " (" + notes.join(", ") + ")"
  } else {
    help
  }
}

///|
fn arg_hidden_in_style(arg : Arg, long_help : Bool) -> Bool {
  let _ = long_help
  arg.hidden
}

///|
fn command_hidden_in_style(cmd : Command, _long_help : Bool) -> Bool {
  cmd.hidden
}

///|
fn has_subcommands_for_help(cmd : Command, long_help : Bool) -> Bool {
  if help_subcommand_enabled(cmd) {
    return true
  }
  for sub in cmd.subcommands {
    if !command_hidden_in_style(sub, long_help) {
      return true
    }
  }
  false
}

///|
fn is_required_arg(arg : Arg) -> Bool {
  if arg.required {
    true
  } else {
    let (min, _) = arg_min_max(arg)
    min > 0
  }
}

///|
fn group_label(group : ArgGroup) -> String {
  let flags = []
  if group.required {
    flags.push("required")
  }
  if !group.multiple {
    flags.push("exclusive")
  }
  if flags.length() == 0 {
    group.name
  } else {
    group.name + " (" + flags.join(", ") + ")"
  }
}

///|
fn group_members(cmd : Command, group : ArgGroup, long_help : Bool) -> String {
  let members = []
  for arg in command_args(cmd) {
    if arg_hidden_in_style(arg, long_help) {
      continue
    }
    if arg_in_group(arg, group) {
      members.push(group_member_display(arg))
    }
  }
  members.join(", ")
}

///|
fn group_member_display(arg : Arg) -> String {
  let base = arg_display(arg)
  if is_positional_arg(arg) {
    base
  } else if arg_takes_value(arg) {
    base + " <" + arg.name + ">"
  } else {
    base
  }
}
