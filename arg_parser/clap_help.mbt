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
/// Help output format for rendering.
pub(all) enum HelpMode {
  Plain
  Man
} derive(Eq, Show)

///|
/// Render short help text for a clap-style command.
fn render_help_plain(cmd : Command) -> String {
  let lines = Array::new(capacity=16)
  lines.push("Usage: " + cmd.name + usage_tail(cmd))
  if cmd.about != "" {
    lines.push("")
    lines.push(cmd.about)
  }
  lines.push("")
  if cmd.subcommands.length() > 0 {
    lines.push("Commands:")
    for entry in subcommand_entries(cmd) {
      lines.push(entry)
    }
    lines.push("")
  }
  if has_positionals(cmd) {
    lines.push("Arguments:")
    for entry in positional_entries(cmd) {
      lines.push(entry)
    }
    lines.push("")
  }
  lines.push("Options:")
  for entry in option_entries(cmd) {
    lines.push(entry)
  }
  if cmd.groups.length() > 0 {
    lines.push("")
    lines.push("Groups:")
    for entry in group_entries(cmd) {
      lines.push(entry)
    }
  }
  lines.join("\n")
}

///|
/// Render a simple manpage-like text for a clap-style command.
fn render_help_man(cmd : Command) -> String {
  let lines = Array::new(capacity=20)
  lines.push("NAME")
  if cmd.about == "" {
    lines.push("  " + cmd.name)
  } else {
    lines.push("  " + cmd.name + " - " + cmd.about)
  }
  lines.push("")
  lines.push("SYNOPSIS")
  lines.push("  " + cmd.name + usage_tail(cmd))
  lines.push("")
  if cmd.about != "" {
    lines.push("DESCRIPTION")
    lines.push("  " + cmd.about)
    lines.push("")
  }
  if cmd.subcommands.length() > 0 {
    lines.push("COMMANDS")
    for entry in subcommand_entries(cmd) {
      lines.push(entry)
    }
    lines.push("")
  }
  if has_positionals(cmd) {
    lines.push("ARGUMENTS")
    for entry in positional_entries(cmd) {
      lines.push(entry)
    }
    lines.push("")
  }
  lines.push("OPTIONS")
  for entry in option_entries(cmd) {
    lines.push(entry)
  }
  if cmd.groups.length() > 0 {
    lines.push("")
    lines.push("GROUPS")
    for entry in group_entries(cmd) {
      lines.push(entry)
    }
  }
  lines.join("\n")
}

///|
fn render_help_with_mode(cmd : Command, mode : HelpMode) -> String {
  match mode {
    HelpMode::Man => render_help_man(cmd)
    HelpMode::Plain => render_help_plain(cmd)
  }
}

///|
fn usage_tail(cmd : Command) -> String {
  let mut tail = ""
  if has_options(cmd) {
    tail = tail + " [options]"
  }
  if cmd.subcommands.length() > 0 {
    tail = tail + " <command>"
  }
  let pos = positional_usage(cmd)
  if pos != "" {
    tail = tail + " " + pos
  }
  tail
}

///|
fn has_options(cmd : Command) -> Bool {
  for arg in cmd.args {
    if arg.long is Some(_) || arg.short is Some(_) {
      return true
    }
  }
  false
}

///|
fn positional_usage(cmd : Command) -> String {
  let parts = Array::new(capacity=cmd.args.length())
  for arg in positional_args(cmd.args) {
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
fn has_positionals(cmd : Command) -> Bool {
  for arg in cmd.args {
    if is_positional_arg(arg) {
      return true
    }
  }
  false
}

///|
fn option_entries(cmd : Command) -> Array[String] {
  let entries = Array::new(capacity=cmd.args.length() + 1)
  let display = Array::new(capacity=cmd.args.length() + 1)
  display.push(("-h, --help[=plain|man]", "Show help information."))
  for arg in cmd.args {
    if arg.long is None && arg.short is None {
      continue
    }
    let mut name = arg_display(arg)
    if arg.takes_value {
      name = name + " <" + arg.name + ">"
    }
    let doc = arg_doc(arg)
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
fn positional_entries(cmd : Command) -> Array[String] {
  let entries = Array::new(capacity=cmd.args.length())
  let display = Array::new(capacity=cmd.args.length())
  for arg in positional_args(cmd.args) {
    let name = positional_display(arg)
    let doc = arg_doc(arg)
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
fn subcommand_entries(cmd : Command) -> Array[String] {
  let display = Array::new(capacity=cmd.subcommands.length() + 1)
  for sub in cmd.subcommands {
    display.push((command_display(sub), sub.about))
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
fn group_entries(cmd : Command) -> Array[String] {
  let entries = Array::new(capacity=cmd.groups.length())
  let display = Array::new(capacity=cmd.groups.length())
  for group in cmd.groups {
    let name = group_label(group)
    let members = group_members(cmd, group)
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
  if cmd.visible_aliases.length() == 0 {
    cmd.name
  } else {
    let items = [cmd.name]
    for alias_name in cmd.visible_aliases {
      items.push(alias_name)
    }
    items.join(", ")
  }
}

///|
fn arg_display(arg : Arg) -> String {
  let parts = Array::new(capacity=2)
  if arg.short is Some(short) {
    parts.push("-" + short.to_string())
  }
  for alias_name in arg.visible_short_aliases {
    parts.push("-" + alias_name.to_string())
  }
  if arg.long is Some(long) {
    if arg.negatable && !arg.takes_value {
      parts.push("--[no-]" + long)
    } else {
      parts.push("--" + long)
    }
  }
  for alias_name in arg.visible_aliases {
    parts.push("--" + alias_name)
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
fn arg_doc(arg : Arg) -> String {
  let notes = []
  match arg.env {
    Some(env_name) => notes.push("env: " + env_name)
    None => ()
  }
  match arg.default_values {
    Some(values) if values.length() > 0 =>
      notes.push("defaults: " + values.join(", "))
    _ =>
      match arg.default_value {
        Some(value) => notes.push("default: " + value)
        None => ()
      }
  }
  if is_required_arg(arg) {
    notes.push("required")
  }
  if arg.help == "" {
    notes.join(", ")
  } else if notes.length() > 0 {
    arg.help + " (" + notes.join(", ") + ")"
  } else {
    arg.help
  }
}

///|
fn is_required_arg(arg : Arg) -> Bool {
  if arg.required {
    true
  } else {
    match arg.min_values {
      Some(min) => min > 0
      None => false
    }
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
fn group_members(cmd : Command, group : ArgGroup) -> String {
  let members = []
  for arg in cmd.args {
    if arg.groups.contains(group.name) {
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
  } else if arg.takes_value {
    base + " <" + arg.name + ">"
  } else {
    base
  }
}
