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
/// Render help text for a clap-style command.
fn render_help(cmd : Command) -> String {
  let usage_line = "Usage: \{cmd.name}\{usage_tail(cmd)}"
  let about = cmd.about.unwrap_or("")
  let about_section = if about == "" {
    ""
  } else {
    (
      $|
      $|
      $|\{about}
    )
  }
  let commands_section = render_section("Commands:", subcommand_entries(cmd))
  let arguments_section = render_section("Arguments:", positional_entries(cmd))
  let options_section = render_section(
    "Options:",
    option_entries(cmd),
    keep_empty=true,
  )
  let groups_section = render_section("Groups:", group_entries(cmd))
  (
    $|\{usage_line}\{about_section}\{commands_section}\{arguments_section}\{options_section}\{groups_section}
    $|
  )
}

///|
fn usage_tail(cmd : Command) -> String {
  let mut tail = ""
  if has_options(cmd) {
    tail = "\{tail} [options]"
  }
  let pos = positional_usage(cmd)
  if pos != "" {
    tail = "\{tail} \{pos}"
  }
  let sub = subcommand_usage(cmd)
  if sub != "" {
    tail = "\{tail} \{sub}"
  }
  tail
}

///|
fn subcommand_usage(cmd : Command) -> String {
  if !has_subcommands_for_help(cmd) {
    return ""
  }
  if cmd.subcommand_required {
    "<command>"
  } else {
    "[command]"
  }
}

///|
fn has_options(cmd : Command) -> Bool {
  for arg in cmd.args {
    if arg.hidden {
      continue
    }
    if arg.info is (Option(long~, short~, ..) | Flag(long~, short~, ..)) &&
      (long is Some(_) || short is Some(_)) {
      return true
    }
  }
  false
}

///|
fn positional_usage(cmd : Command) -> String {
  let parts = Array::new(capacity=cmd.args.length())
  for arg in positional_args(cmd.args) {
    if arg.hidden {
      continue
    }
    let required = is_required_arg(arg)
    if arg.multiple {
      if required {
        parts.push("<\{arg.name}...>")
      } else {
        parts.push("[\{arg.name}...]")
      }
    } else if required {
      parts.push("<\{arg.name}>")
    } else {
      parts.push("[\{arg.name}]")
    }
  }
  parts.join(" ")
}

///|
fn option_entries(cmd : Command) -> Array[String] {
  let args = cmd.args
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
    if !(arg.info is (Option(long~, short~, ..) | Flag(long~, short~, ..)) &&
      (long is Some(_) || short is Some(_))) {
      continue
    }
    if arg.hidden {
      continue
    }
    let name = if arg_takes_value(arg) {
      "\{arg_display(arg)} <\{arg.name}>"
    } else {
      arg_display(arg)
    }
    display.push((name, arg_doc(arg)))
  }
  format_entries(display)
}

///|
fn has_long_option(args : Array[Arg], name : String) -> Bool {
  for arg in args {
    if arg.info is (Option(long~, ..) | Flag(long~, ..)) &&
      long is Some(long) &&
      long == name {
      return true
    }
  }
  false
}

///|
fn has_short_option(args : Array[Arg], value : Char) -> Bool {
  for arg in args {
    if arg.info is (Option(short~, ..) | Flag(short~, ..)) &&
      short is Some(short) &&
      short == value {
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
    Some("\{short_label}, \{long_label}")
  } else if has_short {
    Some(short_label)
  } else if has_long {
    Some(long_label)
  } else {
    None
  }
}

///|
fn positional_entries(cmd : Command) -> Array[String] {
  let display = Array::new(capacity=cmd.args.length())
  for arg in positional_args(cmd.args) {
    if arg.hidden {
      continue
    }
    display.push((positional_display(arg), arg_doc(arg)))
  }
  format_entries(display)
}

///|
fn subcommand_entries(cmd : Command) -> Array[String] {
  let display = Array::new(capacity=cmd.subcommands.length() + 1)
  for sub in cmd.subcommands {
    if sub.hidden {
      continue
    }
    display.push((sub.name, sub.about.unwrap_or("")))
  }
  if help_subcommand_enabled(cmd) {
    display.push(("help", "Print help for the subcommand(s)."))
  }
  format_entries(display)
}

///|
fn group_entries(cmd : Command) -> Array[String] {
  let display = Array::new(capacity=cmd.groups.length())
  for group in cmd.groups {
    let members = group_members(cmd, group)
    if members == "" {
      continue
    }
    display.push((group_label(group), members))
  }
  format_entries(display)
}

///|
fn render_section(
  header : String,
  lines : Array[String],
  keep_empty? : Bool = false,
) -> String {
  if lines.length() == 0 {
    if keep_empty {
      (
        $|
        $|
        $|\{header}
      )
    } else {
      ""
    }
  } else {
    let body = lines.join("\n")
    (
      $|
      $|
      $|\{header}
      $|\{body}
    )
  }
}

///|
fn format_entries(display : Array[(String, String)]) -> Array[String] {
  let entries = Array::new(capacity=display.length())
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
    entries.push("  \{name}\{padding}\{doc}")
  }
  entries
}

///|
fn arg_display(arg : Arg) -> String {
  let parts = Array::new(capacity=2)
  let (short, long) = match arg.info {
    Option(short~, long~, ..) => (short, long)
    Flag(short~, long~, ..) => (short, long)
    Positional(_) => (None, None)
  }
  if short is Some(short) {
    parts.push("-\{short}")
  }
  if long is Some(long) {
    if arg.info is Flag(negatable=true, ..) {
      parts.push("--[no-]\{long}")
    } else {
      parts.push("--\{long}")
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
    "\{arg.name}..."
  } else {
    arg.name
  }
}

///|
fn arg_doc(arg : Arg) -> String {
  let notes = []
  match arg.env {
    Some(env_name) => notes.push("env: \{env_name}")
    None => ()
  }
  if arg.info is (Option(default_values~, ..) | Positional(default_values~, ..)) &&
    default_values is Some(values) {
    if values.length() > 1 {
      let defaults = values.join(", ")
      notes.push("defaults: \{defaults}")
    } else if values.length() == 1 {
      notes.push("default: \{values[0]}")
    }
  }
  if is_required_arg(arg) {
    notes.push("required")
  }
  let help = arg.about.unwrap_or("")
  if help == "" {
    notes.join(", ")
  } else if notes.length() > 0 {
    let notes_text = notes.join(", ")
    "\{help} (\{notes_text})"
  } else {
    help
  }
}

///|
fn has_subcommands_for_help(cmd : Command) -> Bool {
  if help_subcommand_enabled(cmd) {
    return true
  }
  for sub in cmd.subcommands {
    if !sub.hidden {
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
    let flags_text = flags.join(", ")
    "\{group.name} (\{flags_text})"
  }
}

///|
fn group_members(cmd : Command, group : ArgGroup) -> String {
  let members = []
  for arg in cmd.args {
    if arg.hidden {
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
    "\{base} <\{arg.name}>"
  } else {
    base
  }
}
