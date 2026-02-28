# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`cvm` (Claude VM) is a single bash script that runs `claude --dangerously-skip-permissions -p` inside a Docker container, providing an isolated sandbox for fully autonomous Claude Code task execution.

## Usage

```bash
./cvm "task description"
./cvm --dir ./src "refactor this codebase"
echo "fix all TypeScript errors" | ./cvm --dir .
./cvm --out ./results --budget 2.00 "analyze this dataset"
```

Key flags: `-d/--dir` (copy dir into workspace), `-o/--out` (copy results out), `-b/--budget` (USD cap), `-k/--keep` (retain workspace after run), `-v/--verbose` (stream-json output), `--build` (force Docker rebuild).

## Architecture

The entire tool is `cvm` (bash) + `Dockerfile`. There is no build system, no package manager, no tests.

**Execution flow** (`main()`):
1. `parse_args` — parse flags and task string (or read from stdin)
2. `setup_colors` — disable ANSI if `NO_COLOR` or non-TTY
3. `check_docker` — verify docker is in PATH and running
4. `check_auth` — require `~/.claude/.credentials.json` or `ANTHROPIC_API_KEY`
5. `ensure_image` — build Docker image tagged `cvm:<sha256-of-Dockerfile[:12]>` (content-addressed; skips build if tag exists)
6. `create_workspace` — `mktemp -d /tmp/cvm-workspace-XXXXXX` (chmod 777 for container write access); copies `--dir` contents in; creates a separate `mktemp -d /tmp/cvm-claude-XXXXXX` and copies only `~/.claude/.credentials.json` and `~/.claude/settings.json` into it (the full `~/.claude` can't be mounted read-only because Claude writes `todos/`, `debug/`, `history.jsonl`, etc.)
7. `run_claude` — runs `docker run --rm --name cvm-$$ ...` mounting workspace and ephemeral claude dir, then runs `claude --dangerously-skip-permissions --no-session-persistence -p "$TASK" --model "$MODEL"`
8. `show_file_summary` — lists files created in workspace
9. `cleanup` (EXIT trap) — optionally copies workspace to `--out`, removes workspace and temp files

**Verbose mode** writes a Python script to a tempfile (`/tmp/cvm-parser-XXXXXX.py`) and pipes `--output-format stream-json --verbose` docker output through `python3 -u` for pretty-printing. The tempfile approach is required so stdin remains connected to the docker pipe (a heredoc would consume it).

**Docker image** runs as the `ubuntu` user (UID 1000) — `--dangerously-skip-permissions` is blocked when running as root.

## Auth

- **OAuth**: Run `claude auth login` on the host. Credentials at `~/.claude/.credentials.json` are copied into the ephemeral container claude dir.
- **API key**: Set `ANTHROPIC_API_KEY` in the environment; it is passed to the container via `-e ANTHROPIC_API_KEY`.

## Modifying the Docker image

Edit `Dockerfile`. The image tag is derived from a SHA256 of the Dockerfile, so any change automatically triggers a rebuild on next `cvm` invocation. Force a rebuild manually with `--build`.
