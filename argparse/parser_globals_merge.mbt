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
fn source_priority(source : ValueSource?) -> Int {
  match source {
    Some(ValueSource::Argv) => 3
    Some(ValueSource::Env) => 2
    Some(ValueSource::Default) => 1
    None => 0
  }
}

///|
fn prefer_child_source(
  parent_source : ValueSource?,
  child_source : ValueSource?,
) -> Bool {
  let parent_priority = source_priority(parent_source)
  let child_priority = source_priority(child_source)
  if child_priority > parent_priority {
    true
  } else if child_priority < parent_priority {
    false
  } else {
    child_source is Some(ValueSource::Argv)
  }
}

///|
fn strongest_source(
  parent_source : ValueSource?,
  child_source : ValueSource?,
) -> ValueSource? {
  if prefer_child_source(parent_source, child_source) {
    child_source
  } else {
    match parent_source {
      Some(source) => Some(source)
      None => child_source
    }
  }
}

///|
fn merge_global_value_from_child(
  parent : Matches,
  child : Matches,
  arg : Arg,
  name : String,
) -> Unit {
  let parent_vals = parent.values.get(name)
  let child_vals = child.values.get(name)
  let parent_source = parent.value_sources.get(name)
  let child_source = child.value_sources.get(name)
  let has_parent = parent_vals is Some(pv) && pv.length() > 0
  let has_child = child_vals is Some(cv) && cv.length() > 0
  if !has_parent && !has_child {
    return
  }
  if arg.multiple || arg.info is Option(action=Append, ..) {
    let both_argv = parent_source is Some(ValueSource::Argv) &&
      child_source is Some(ValueSource::Argv)
    if both_argv {
      let merged = []
      if parent_vals is Some(pv) {
        for v in pv {
          merged.push(v)
        }
      }
      if child_vals is Some(cv) {
        for v in cv {
          merged.push(v)
        }
      }
      if merged.length() > 0 {
        parent.values[name] = merged
        parent.value_sources[name] = ValueSource::Argv
      }
    } else {
      let choose_child = has_child &&
        (!has_parent || prefer_child_source(parent_source, child_source))
      if choose_child {
        if child_vals is Some(cv) && cv.length() > 0 {
          parent.values[name] = cv.copy()
        }
        match child_source {
          Some(src) => parent.value_sources[name] = src
          None => ()
        }
      } else if parent_vals is Some(pv) && pv.length() > 0 {
        parent.values[name] = pv.copy()
        match parent_source {
          Some(src) => parent.value_sources[name] = src
          None => ()
        }
      }
    }
  } else {
    let choose_child = has_child &&
      (!has_parent || prefer_child_source(parent_source, child_source))
    if choose_child {
      if child_vals is Some(cv) && cv.length() > 0 {
        parent.values[name] = cv.copy()
      }
      match child_source {
        Some(src) => parent.value_sources[name] = src
        None => ()
      }
    } else if parent_vals is Some(pv) && pv.length() > 0 {
      parent.values[name] = pv.copy()
      match parent_source {
        Some(src) => parent.value_sources[name] = src
        None => ()
      }
    }
  }
}

///|
fn merge_global_flag_from_child(
  parent : Matches,
  child : Matches,
  arg : Arg,
  name : String,
) -> Unit {
  match child.flags.get(name) {
    Some(v) =>
      if arg.info is Flag(action=Count, ..) {
        let has_parent = parent.flags.get(name) is Some(_)
        let parent_source = parent.flag_sources.get(name)
        let child_source = child.flag_sources.get(name)
        let both_argv = parent_source is Some(ValueSource::Argv) &&
          child_source is Some(ValueSource::Argv)
        if both_argv {
          let parent_count = parent.counts.get(name).unwrap_or(0)
          let child_count = child.counts.get(name).unwrap_or(0)
          let total = parent_count + child_count
          parent.counts[name] = total
          parent.flags[name] = total > 0
          match strongest_source(parent_source, child_source) {
            Some(src) => parent.flag_sources[name] = src
            None => ()
          }
        } else {
          let choose_child = !has_parent ||
            prefer_child_source(parent_source, child_source)
          if choose_child {
            let child_count = child.counts.get(name).unwrap_or(0)
            parent.counts[name] = child_count
            parent.flags[name] = child_count > 0
            match child_source {
              Some(src) => parent.flag_sources[name] = src
              None => ()
            }
          }
        }
      } else {
        let has_parent = parent.flags.get(name) is Some(_)
        let parent_source = parent.flag_sources.get(name)
        let child_source = child.flag_sources.get(name)
        let choose_child = !has_parent ||
          prefer_child_source(parent_source, child_source)
        if choose_child {
          parent.flags[name] = v
          match child_source {
            Some(src) => parent.flag_sources[name] = src
            None => ()
          }
        }
      }
    None => ()
  }
}

///|
fn merge_globals_from_child(
  parent : Matches,
  child : Matches,
  globals : Array[Arg],
  child_local_non_globals : @set.Set[String],
) -> Unit {
  for arg in globals {
    let name = arg.name
    if child_local_non_globals.contains(name) {
      continue
    }
    match arg.info {
      Option(_) | Positional(_) =>
        merge_global_value_from_child(parent, child, arg, name)
      Flag(_) => merge_global_flag_from_child(parent, child, arg, name)
    }
  }
}

///|
fn propagate_globals_to_child(
  parent : Matches,
  child : Matches,
  globals : Array[Arg],
  child_local_non_globals : @set.Set[String],
) -> Unit {
  for arg in globals {
    let name = arg.name
    if child_local_non_globals.contains(name) {
      continue
    }
    if arg.info is (Option(_) | Positional(_)) {
      match parent.values.get(name) {
        Some(values) => {
          child.values[name] = values.copy()
          match parent.value_sources.get(name) {
            Some(src) => child.value_sources[name] = src
            None => ()
          }
        }
        None => ()
      }
    } else {
      match parent.flags.get(name) {
        Some(v) => {
          child.flags[name] = v
          match parent.flag_sources.get(name) {
            Some(src) => child.flag_sources[name] = src
            None => ()
          }
          if arg.info is Flag(action=Count, ..) {
            match parent.counts.get(name) {
              Some(c) => child.counts[name] = c
              None => ()
            }
          }
        }
        None => ()
      }
    }
  }
}
