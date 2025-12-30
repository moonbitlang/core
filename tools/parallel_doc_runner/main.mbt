struct Job {
  package_path : String
  prompt : String
  output_path : String
}

fn should_skip_dir(name : String, rel_prefix : String) -> Bool {
  if name == "target" || name == ".git" || name == ".mooncakes" {
    true
  } else if rel_prefix.is_empty() && name == "tools" {
    true
  } else {
    false
  }
}

fn collect_packages(root : String) -> Array[String] {
  let packages : Array[String] = []
  fn visit(dir_path : String, rel_prefix : String) -> Unit raise {
    let entries = @fs.read_dir(dir_path)
    let mut has_pkg = false
    for entry in entries {
      if entry == "moon.pkg.json" {
        has_pkg = true
      }
    }
    if has_pkg {
      let label = if rel_prefix.is_empty() { "." } else { rel_prefix }
      packages.push(label)
    }
    for entry in entries {
      if should_skip_dir(entry, rel_prefix) {
        continue
      }
      let full_path = "\{dir_path}/\{entry}"
      let is_dir = @fs.is_dir(full_path) catch { _ => false }
      if is_dir {
          let next_prefix = if rel_prefix.is_empty() {
            entry
          } else {
            "\{rel_prefix}/\{entry}"
          }
          visit(full_path, next_prefix)
      }
    }
  }

  visit(root, "") catch { _ => () }
  packages
}

fn parse_int_env(env : Map[String, String], key : String, default : Int) -> Int {
  match env.get(key) {
    Some(value) => {
      let parsed : Result[Int, @strconv.StrConvError] =
        try? @strconv.parse_int(value)
      match parsed {
        Ok(v) => v
        Err(_) => default
      }
    }
    None => default
  }
}

fn build_prompt(
  package_path : String,
  target_dir : String,
  workdir : String,
) -> String {
    let prompt =
      $|You are updating inline documentation for MoonBit standard library package: \{package_path}
      $|
      $|Goal:
      $|- Every function and type in this package has accurate docstrings.
      $|- Add docstring tests (mbt check) for public APIs; prefer inspect/@json.inspect.
      $|
      $|Constraints:
      $|- Keep block structure with ///| separators.
      $|- Keep deprecated blocks in deprecated.mbt.
      $|- Skip adding docs for items marked #doc(hidden) or #deprecated.
      $|- Still add docs for items marked #alias(deprecated).
      $|- Avoid editing other packages unless required for correctness.
      $|
      $|Verification (run from repo root and use -C):
      $|- moon -C \{workdir} fmt
      $|- moon -C \{workdir} info
      $|- moon -C \{workdir} check --target-dir \{target_dir}
      $|- moon -C \{workdir} test --target-dir \{target_dir} (use --update if snapshots change)
      $|
      $|Output:
      $|- Summarize changes and list files touched.
  prompt
}

fn is_abs_path(path : String) -> Bool {
  path is ['/', ..]
}

fn ensure_dir(path : String) -> Unit {
  if path.is_empty() {
    return
  }
  let parts = path.split("/").collect()
  let mut current = if is_abs_path(path) { "/" } else { "" }
  let start_index = if is_abs_path(path) { 1 } else { 0 }
  for i in start_index..<parts.length() {
    let part = parts[i].to_string()
    if part.is_empty() {
      continue
    }
    current = if current.is_empty() || current == "/" {
      if current == "/" { "/\{part}" } else { part }
    } else {
      "\{current}/\{part}"
    }
    if @fs.path_exists(current) {
      continue
    }
    @fs.create_dir(current) catch { _ => () }
  }
}

fn parent_dir(path : String) -> String {
  let parts = path.split("/").collect()
  if parts.length() <= 1 {
    return "."
  }
  let dirs : Array[String] = []
  let start_index = if parts[0].is_empty() { 1 } else { 0 }
  let end_index = parts.length() - 1
  if start_index < end_index {
    for i in start_index..<end_index {
      dirs.push(parts[i].to_string())
    }
  }
  let base = dirs.join("/")
  if parts[0].is_empty() {
    if base.is_empty() { "/" } else { "/\{base}" }
  } else {
    if base.is_empty() { "." } else { base }
  }
}

fn write_output(path : String, content : String) -> Unit {
  let dir = parent_dir(path)
  ensure_dir(dir)
  @fs.write_string_to_file(path, content) catch { _ => () }
}

fn package_id(package_path : String) -> String {
  if package_path == "." { "_root" } else { package_path }
}

fn progress_marker_path(output_root : String, package_path : String) -> String {
  let id = package_id(package_path)
  "\{output_root}/_progress/\{id}.done"
}

fn write_progress(output_root : String, package_path : String) -> Unit {
  let marker = progress_marker_path(output_root, package_path)
  write_output(marker, "done\n")
}

fn slice_packages(
  packages : Array[String],
  offset : Int,
  limit : Int,
) -> Array[String] {
  let total = packages.length()
  let start = if offset < 0 { 0 } else { offset }
  let end = if limit <= 0 { total } else { start + limit }
  let safe_end = if end > total { total } else { end }
  let subset : Array[String] = []
  if start >= safe_end {
    return subset
  }
  for i in start..<safe_end {
    subset.push(packages[i])
  }
  subset
}

fn write_manifest(
  output_root : String,
  run_id : String,
  offset : Int,
  limit : Int,
  packages : Array[String],
) -> Unit {
  let lines : Array[String] = []
  lines.push("run_id: \{run_id}")
  lines.push("offset: \{offset}")
  lines.push("limit: \{limit}")
  lines.push("selected: \{packages.length()}")
  lines.push("next_offset: \{offset + packages.length()}")
  lines.push("packages:")
  for pkg in packages {
    lines.push("- \{pkg}")
  }
  let content = lines.join("\n") + "\n"
  write_output("\{output_root}/run_manifest.txt", content)
}

async fn run_job(
  codex : @codex.Codex,
  workdir : String,
  job : Job,
  output_root : String,
) -> String {
  if @fs.path_exists(job.output_path) {
    let content = "== \{job.package_path}\nSKIP: output exists\n"
    write_progress(output_root, job.package_path)
    return content
  }
  let thread = codex.start_thread(
    options=@codex.ThreadOptions::new(
      model?=@sys.get_env_vars().get("MODEL"),
      sandbox_mode=@codex.SandboxMode::WorkspaceWrite,
      working_directory=workdir,
      skip_git_repo_check=true,
    ),
  )
  let turn = thread.run(job.prompt) catch {
    e => {
      let content = "== \{job.package_path}\nERROR: \{e}\n"
      write_output(job.output_path, content)
      write_progress(output_root, job.package_path)
      return content
    }
  }
  let content = "== \{job.package_path}\n\{turn.final_response}\n"
  write_output(job.output_path, content)
  write_progress(output_root, job.package_path)
  content
}

async fn main {
  let env = @sys.get_env_vars()
  let workdir = env.get("CODEX_WORKDIR").unwrap_or("../..")
  let is_dir = @fs.is_dir(workdir) catch { _ => false }
  if !is_dir {
    @stdio.stderr.write("workdir is not a directory: \{workdir}\n")
    return
  }

  let parallelism = parse_int_env(env, "DOC_PARALLELISM", 4)
  let offset = parse_int_env(env, "DOC_OFFSET", 0)
  let limit = parse_int_env(env, "DOC_LIMIT", 0)
  let rand = @random.Rand::new()
  let run_id =
    env.get("DOC_RUN_ID").unwrap_or("\{rand.int(limit=1000000)}")
  let output_root = env.get("DOC_OUTPUT_DIR").unwrap_or(
    "\{workdir}/target/doc_runner/results/\{run_id}",
  )
  ensure_dir(output_root)
  let packages = collect_packages(workdir)
  if packages.is_empty() {
    @stdio.stderr.write("no moon.pkg.json files found under \{workdir}\n")
    return
  }
  packages.sort()
  let selected = slice_packages(packages, offset, limit)
  write_manifest(output_root, run_id, offset, limit, selected)
  if selected.is_empty() {
    @stdio.stderr.write(
      "no packages selected (offset=\{offset}, limit=\{limit})\n",
    )
    return
  }
  let jobs : Array[Job] = []
  let mut index = 0
  for package_path in selected {
    let target_dir =
      "target/doc_runner/\{run_id}/\{index}_\{rand.int(limit=1000000)}"
    let prompt = build_prompt(package_path, target_dir, workdir)
    let output_path = if package_path == "." {
      "\{output_root}/_root.md"
    } else {
      "\{output_root}/\{package_path}.md"
    }
    jobs.push({ package_path, prompt, output_path })
    index = index + 1
  }

  let codex = @codex.Codex::new()
  let results : Array[String] = []
  @async.with_task_group(fn(task_group) {
    let semaphore = @semaphore.Semaphore::new(parallelism)
    for job in jobs {
      task_group.spawn_bg(allow_failure=true, fn() {
        semaphore.acquire()
        defer semaphore.release()
        let output = run_job(codex, workdir, job, output_root) catch {
          e => "== \{job.package_path}\nERROR: \{e}\n"
        }
        results.push(output)
      })
    }
  })

  for item in results {
    @stdio.stdout.write("\{item}\n")
  }
}
