# gh Wrapper Visibility Guard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stop a Claude session working in a private repository from accidentally writing to a public one (e.g. an embargoed CVE leaking into a public issue or a pushed branch).

**Architecture:** `bin/gh` (Perl) already intercepts every `gh` call in a Claude session and classifies writes. We add one rule on top: if the session's repo is private, every write must target a repo that is private/internal or listed in a human-owned allowlist; anything else — including a target we can't determine — is refused. Visibility is looked up through the real `gh` at write time. `bin/nn` is changed so `git push` (which under nono goes through `gh auth git-credential`) reveals its target repo, and so the wrapper knows the directory the session started in.

**Tech Stack:** Perl 5 (core modules only), bats, bash.

## Global Constraints

- Threat model is accidents, not a hostile agent. Keep it simple.
- Only writes are checked; reads always pass through untouched and trigger no lookups.
- Outside a Claude session (`$CLAUDECODE` unset) the wrapper must keep passing everything through unchanged, and must print nothing extra to stderr.
- A session is **private** if any GitHub remote of cwd's repo or of `$NN_SESSION_DIR`'s repo is not `public` (failed lookup counts as private). No GitHub remotes → not private → no restriction (documented gap).
- In a private session a write is allowed only if every target repo is `private` or `internal`, or is listed in `~/.config/gh/wrapper-allow-public`. Unknown target or failed lookup → refuse.
- Without an explicit target (`-R`, URL arg), the targets are `$GH_REPO` if set, else **all** GitHub remotes of cwd plus any non-`base` `gh repo set-default` choice.
- Refusals go through the existing `block()` (`gh-wrapper: refusing to post — …`, exit 1). Each message says what to do: "pass -R owner/repo" when targets came from remotes, "ask the user" when the agent named a public target, "retry" when a lookup failed. Messages must not mention the allowlist path.
- Git exports `GIT_DIR` to credential helpers; every git call the wrapper makes must clear `GIT_DIR`, `GIT_WORK_TREE`, `GIT_COMMON_DIR`, `GIT_INDEX_FILE`, `GIT_PREFIX`.
- The allowlist lives in `~/.config/gh/`, which nono already mounts read-only (`nono/oalders-core.json`); no profile change.
- Comments and docs follow CLAUDE.md: minimal, rationale in `docs/gh-wrapper-visibility.md`.
- Commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Run tests with `node_modules/.bin/bats test/gh-wrapper.bats`; lint with `precious lint bin/gh` (and `bin/nn` in Task 3).

---

## File Structure

- Modify `bin/gh` — visibility helpers, target resolution, guard calls at each write path.
- Modify `test/gh-wrapper.bats` — hermetic setup, stub answers visibility lookups, new tests.
- Modify `bin/nn` — `credential.useHttpPath=true`, `GIT_TERMINAL_PROMPT=0`, export `NN_SESSION_DIR`.
- Modify `test/nn.bats` — assert the new env entries.
- Create `docs/gh-wrapper-visibility.md` — the why, coverage, and known gaps.
- Modify `nono/CLAUDE.md` — one bullet for the new `nn` env.

Before Task 1: `git switch -c gh-wrapper-visibility-guard`.

---

### Task 1: Core guard; issue/pr/release, transfer, upload, gists

**Files:**
- Modify: `bin/gh` (header comment; `use` block; helpers after `check()`; `cmd_targets` after `my @argv = @ARGV;`; main flow at the `if ($cmd)` block)
- Modify: `test/gh-wrapper.bats` (setup + new tests)
- Create: `docs/gh-wrapper-visibility.md`

**Interfaces:**
- Produces (used by Tasks 2–3):
  - `$PRIVATE`, `$ASK`, `$NAME_IT` — message fragments
  - `cmd_output(@cmd)` → stdout, `''` on failure; child stdin/stderr are /dev/null
  - `gh_output(@args)` → `cmd_output(real_gh(), @args)`
  - `repo_name($s)` → lowercase `"owner/repo"` or `undef`
  - `repo_visibility($repo)` → lowercase visibility, `''` if the lookup failed
  - `git_config_values($dir, $regexp)` → list of values, GIT_* env cleared
  - `github_remotes($dir)` → list of `owner/repo` (may contain `undef`)
  - `default_targets()` → `$GH_REPO`, else cwd remotes + set-default
  - `private_context()` → 1/0, cached
  - `guard_targets($hint, @repos)` → returns, or `block()`s; empty `@repos` or any `undef` means "unknown target"
  - `cmd_targets($start, $spec)` → `($hint, @repos)`
- Test helpers (used by Tasks 2–3): `$VIS` table, `vis()`, `private_repo()`, `refute_lookups()`

- [ ] **Step 1: Make the test setup hermetic and teach the stub to answer lookups**

Today `test/gh-wrapper.bats` runs with cwd = wherever bats was invoked, which may be this repo (a GitHub remote). Replace `setup()` and add helpers:

```bash
setup() {
    setup_sandbox
    GH="$BIN_DIR/gh"
    OUT="$BATS_TEST_TMPDIR/gh-argv"
    # `owner/repo visibility` lines the stub answers `gh repo view` from.
    VIS="$BATS_TEST_TMPDIR/visibility"
    : >"$VIS"
    export CLAUDECODE=1 OUT VIS
    export CLAUDE_CODE_SESSION_ID=0f8e2a1c-test-session
    export TMPDIR="$BATS_TEST_TMPDIR/tmp"
    export HOME="$BATS_TEST_TMPDIR/home"
    export GIT_CEILING_DIRECTORIES="$BATS_TEST_TMPDIR"
    unset NN_SESSION_DIR GH_REPO
    mkdir -p "$TMPDIR" "$HOME/.config/gh" "$BATS_TEST_TMPDIR/work"
    cd "$BATS_TEST_TMPDIR/work"
    # Fake real gh. Visibility lookups are answered from $VIS and recorded in
    # $OUT.lookups, never $OUT; anything else logs each arg, and the contents
    # of any body file it points at (the wrapper deletes its temp files once
    # gh exits). `gh auth` also records its stdin.
    stub_command gh '
if [[ $1 == repo && $2 == view && $4 == --json ]]; then
    echo "$3" >>"$OUT.lookups"
    while read -r k v; do
        if [[ $k == "$3" ]]; then echo "${v^^}"; exit 0; fi
    done <"$VIS"
    exit 1
fi
[[ $1 == auth ]] && cat >"$OUT.stdin"
for a in "$@"; do
    printf "ARG:%s\n" "$a"
    case $a in
        body=@*) f=${a#body=@} ;;
        --body-file=*) f=${a#--body-file=} ;;
        --input=*) f=${a#--input=} ;;
        *) f=$a ;;
    esac
    if [[ -f $f ]]; then printf "FILE:%s\n" "$(cat "$f")"; fi
done >"$OUT"'
    ANCHOR='[Claude Code](https://claude.com/claude-code)'
    GEN=$'hi\n\n---\n🤖 Generated with '"$ANCHOR · Opus 5.5"
    REV=$'lgtm\n\n---\n🤖 Review by '"$ANCHOR · Opus 5.5"
    BODY_FILE="$BATS_TEST_TMPDIR/body.md"
    printf '%s\n' "$GEN" >"$BODY_FILE"
}

# Record a visibility for the stub: vis owner/repo public|private|internal
vis() { printf '%s %s\n' "$1" "$2" >>"$VIS"; }

# cd into a repo whose only remote is the private me/secret.
private_repo() {
    setup_git_repo
    git remote add origin git@github.com:me/secret.git
    vis me/secret private
}

# No visibility lookup reached gh.
refute_lookups() { [ ! -e "$OUT.lookups" ]; }
```

Also make `gh_run` clear the lookup log, so `refute_lookups` sees only the last call:

```bash
gh_run() {
    rm -f "$OUT" "$OUT.lookups"
    run "$GH" "$@"
}
```

`assert_refused` checks `[ ! -e "$OUT" ]`; lookups never write `$OUT`, so it still means "nothing was posted".

- [ ] **Step 2: Run the existing suite to confirm the setup change is neutral**

Run: `node_modules/.bin/bats test/gh-wrapper.bats`
Expected: all 43 existing tests PASS.

- [ ] **Step 3: Write the failing tests**

Append to `test/gh-wrapper.bats`:

```bash
@test "a private session may not post to a named public repo" {
    private_repo
    vis org/proj public
    gh_run issue create -R org/proj --title t --body "$GEN"
    assert_refused
    [[ "$output" == *"org/proj is public; ask the user"* ]]
    [[ "$output" != *"wrapper-allow-public"* ]]
}

@test "a private session may write to private and internal repos" {
    private_repo
    vis me/other private
    vis corp/tool internal
    gh_run pr comment 1 -R me/other --body "$GEN"
    assert_passed
    gh_run pr comment 1 -R corp/tool --body "$GEN"
    assert_passed
}

@test "a failed visibility lookup is refused and says so" {
    private_repo
    gh_run issue comment 1 -R ghost/repo --body "$GEN"
    assert_refused
    [[ "$output" == *"looking up ghost/repo failed; retry"* ]]
}

@test "without -R every github remote of cwd is a target" {
    private_repo
    git remote add upstream https://github.com/org/proj
    vis org/proj public
    gh_run issue comment 1 --body "$GEN"
    assert_refused
    [[ "$output" == *"org/proj is public; pass -R owner/repo"* ]]
    gh_run issue comment 1 -R me/secret --body "$GEN"
    assert_passed
}

@test "a gh repo set-default choice is a target" {
    private_repo
    vis org/proj public
    git config remote.origin.gh-resolved org/proj
    gh_run issue comment 1 --body "$GEN"
    assert_refused
    git config remote.origin.gh-resolved base
    gh_run issue comment 1 --body "$GEN"
    assert_passed
}

@test "global -R, URL arguments and GH_REPO are targets" {
    private_repo
    vis org/proj public
    gh_run -R org/proj issue comment 1 --body "$GEN"
    assert_refused
    gh_run --repo=org/proj issue comment 1 --body "$GEN"
    assert_refused
    gh_run pr comment https://github.com/org/proj/pull/1 --body "$GEN"
    assert_refused
    GH_REPO=org/proj gh_run issue comment 1 --body "$GEN"
    assert_refused
}

@test "public sessions and non-repos are unrestricted" {
    vis org/proj public
    gh_run issue comment 1 -R org/proj --body "$GEN"
    assert_passed
    refute_lookups
    setup_git_repo
    git remote add origin https://github.com/me/pub.git
    vis me/pub public
    gh_run issue comment 1 -R org/proj --body "$GEN"
    assert_passed
}

@test "an unknown session remote makes the session private" {
    setup_git_repo
    git remote add origin git@github.com:me/mystery.git
    vis org/proj public
    gh_run issue comment 1 -R org/proj --body "$GEN"
    assert_refused
}

@test "NN_SESSION_DIR keeps the session private after cd" {
    private_repo
    export NN_SESSION_DIR="$REPO_DIR"
    cd "$BATS_TEST_TMPDIR/work"
    vis org/proj public
    gh_run issue comment 1 -R org/proj --body "$GEN"
    assert_refused
}

@test "allowlisted public repos may be written to" {
    private_repo
    vis org/proj public
    printf '# embargo lifted\nOrg/Proj\n' >"$HOME/.config/gh/wrapper-allow-public"
    gh_run issue comment 1 -R org/proj --body "$GEN"
    assert_passed
}

@test "reads are never checked" {
    private_repo
    vis org/proj public
    gh_run issue view 1 -R org/proj
    assert_passed
    refute_lookups
}

@test "issue transfer checks the destination" {
    private_repo
    vis org/proj public
    gh_run issue transfer 1 org/proj
    assert_refused
    vis me/other private
    gh_run issue transfer 1 me/other
    assert_passed
}

@test "release create and upload are checked" {
    private_repo
    vis org/proj public
    gh_run release create v1 -R org/proj --notes x
    assert_refused
    gh_run release upload v1 secret.txt -R org/proj
    assert_refused
    gh_run release upload v1 secret.txt
    assert_passed
}

@test "a private session may not create or edit gists" {
    private_repo
    gh_run gist create notes.md
    assert_refused
    [[ "$output" == *"gists are readable by anyone"* ]]
    gh_run gist edit abc123
    assert_refused
    gh_run gist view abc123
    assert_passed
}

@test "a public session may create gists" {
    setup_git_repo
    git remote add origin https://github.com/me/pub.git
    vis me/pub public
    gh_run gist create notes.md
    assert_passed
}

@test "lookups print nothing to stderr" {
    private_repo
    vis me/other private
    bats_require_minimum_version 1.5.0
    run --separate-stderr "$GH" pr comment 1 -R me/other --body "$GEN"
    [ "$status" -eq 0 ]
    [ -z "$stderr" ]
}
```

- [ ] **Step 4: Run them to verify they fail**

Run: `node_modules/.bin/bats test/gh-wrapper.bats`
Expected: the refusal tests FAIL (gh was called); some pass-through tests may already pass.

- [ ] **Step 5: Implement the helpers in `bin/gh`**

Add to the `use` block:

```perl
use File::Spec ();
use POSIX      ();
```

Insert after the `check` sub (before `read_body`):

```perl
# A session in a private repo may only write to private/internal repos or
# allowlisted ones. Why, and what it does not cover: docs/gh-wrapper-visibility.md.
my $ALLOW_PUBLIC = "$ENV{HOME}/.config/gh/wrapper-allow-public";
my $PRIVATE      = 'this session works in a private repository';
my $ASK          = 'ask the user before writing there';
my $NAME_IT      = 'pass -R owner/repo naming the repository you mean';
my %visibility;    # owner/repo => lowercase visibility, '' if lookup failed
my $private_context;

# Output of @cmd, or '' if it fails. stdin/stderr are /dev/null so a lookup
# neither eats a body piped to us nor clutters the agent's output.
sub cmd_output {
    my @cmd = @_;
    my $pid = open my $fh, '-|';
    return q{} if !defined $pid;
    if ( !$pid ) {
        open STDIN,  '<', File::Spec->devnull;
        open STDERR, '>', File::Spec->devnull;

        # _exit: END would unlink the parent's temp files.
        exec { $cmd[0] } @cmd or POSIX::_exit(127);
    }
    my $out = do { local $/; <$fh> } // q{};
    close $fh;
    return $? ? q{} : $out;
}

sub gh_output { cmd_output( real_gh(), @_ ) }

# Lowercase "owner/repo" from a -R value, URL, remote or credential path;
# undef if it names no github.com repository.
sub repo_name {
    my ($s) = @_;
    return undef if !defined $s;
    $s =~ s{^[a-z+]+://}{}i;
    $s =~ s{^[^@/]+@}{};
    if ( $s =~ s{^([^/:]*\.[^/:]*)[:/]}{} ) {
        return undef if lc $1 ne 'github.com';
    }
    $s =~ s{[?#].*}{}s;
    my ( $owner, $repo ) = split m{/}, $s;
    return undef if !defined $repo || $owner eq q{} || $repo eq q{};
    $repo =~ s/\.git\z//;
    return lc "$owner/$repo";
}

sub repo_visibility {
    my ($repo) = @_;
    return $visibility{$repo} //= do {
        my $v = lc gh_output( 'repo', 'view', $repo, '--json', 'visibility',
            '--jq', '.visibility' );
        $v =~ s/\s+\z//;
        $v;
    };
}

# Git exports GIT_DIR to credential helpers, which would override -C.
sub git_config_values {
    my ( $dir, $regexp ) = @_;
    local %ENV = %ENV;
    delete @ENV{
        qw( GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE GIT_PREFIX )};
    my $out = cmd_output( 'git', '-C', $dir, 'config', '--get-regexp',
        $regexp );
    return map { ( split q{ }, $_, 2 )[1] // q{} } split /\n/, $out;
}

sub github_remotes {
    my ($dir) = @_;
    return map { repo_name($_) }
        grep { m{github\.com[:/]}i }
        git_config_values( $dir, '^remote\..*\.url$' );
}

# Where a write goes when nothing names a repo. gh would pick one remote;
# checking all of them is the conservative reading.
sub default_targets {
    return repo_name( $ENV{GH_REPO} ) if $ENV{GH_REPO};
    return (
        github_remotes(q{.}),
        map  { repo_name($_) }
        grep { $_ ne 'base' }
            git_config_values( q{.}, '^remote\..*\.gh-resolved$' )
    );
}

sub private_context {
    return $private_context //= do {
        my %seen;
        my @remotes = grep { !$seen{ $_ // q{} }++ }
            map { github_remotes($_) }
            grep { defined && length } q{.}, $ENV{NN_SESSION_DIR};
        ( grep { !defined || repo_visibility($_) ne 'public' } @remotes )
            ? 1
            : 0;
    };
}

sub allowed_public {
    my ($repo) = @_;
    open my $fh, '<', $ALLOW_PUBLIC or return 0;
    while ( my $line = <$fh> ) {
        $line =~ s/#.*//s;
        $line =~ s/\s+//g;
        return 1 if lc $line eq $repo;
    }
    return 0;
}

# Refuse unless every target is private, internal or allowlisted. No targets,
# or an undef one, means the target couldn't be determined. $hint says what
# to do instead.
sub guard_targets {
    my ( $hint, @targets ) = @_;
    return if !private_context();
    block("$PRIVATE and the repository this writes to can't be determined;"
            . " $hint" )
        if !@targets || grep { !defined } @targets;
    for my $repo (@targets) {
        next if allowed_public($repo);
        my $vis = repo_visibility($repo);
        next if $vis eq 'private' || $vis eq 'internal';
        block("$PRIVATE and looking up $repo failed; retry, or $ASK")
            if $vis eq q{};
        block("$PRIVATE and $repo is $vis; $hint");
    }
}
```

Insert directly after `my @argv = @ARGV;` (it reads `@argv`, so it must come after that line):

```perl
# A subcommand's targets: -R (before or after the subcommand) and URL
# arguments, else default_targets(). Returns ( $hint, @repos ).
sub cmd_targets {
    my ( $start, $spec ) = @_;
    my ( $found, $positional ) = parse_flags( \@argv, $start, $spec );
    my @t = map { repo_name( value_of( \@argv, $_ ) ) }
        grep { $_->{name} eq 'repo' } @$found;
    push @t, map { repo_name($_) } grep { m{github\.com/}i } @$positional;
    for ( my $j = 0 ; $j < $start - 1 ; $j++ ) {
        if ( $argv[$j] =~ /^(?:-R|--repo)\z/ ) {
            push @t, repo_name( $argv[ ++$j ] );
        }
        elsif ( $argv[$j] =~ /^(?:--repo=|-R=?)(.+)/s ) {
            push @t, repo_name($1);
        }
    }
    return ( $ASK, @t ) if @t;
    return ( $NAME_IT, default_targets() );
}
```

- [ ] **Step 6: Call the guard from the subcommand paths**

Replace:

```perl
if ($cmd) {
    check_flags( \@argv, $i + 1, @$cmd );
    run_real(@argv);
}
```

with:

```perl
if ($cmd) {
    check_flags( \@argv, $i + 1, @$cmd );
    guard_targets( cmd_targets( $i + 1, $cmd->[0] ) );
    run_real(@argv);
}
if ( $sub eq 'issue' && $action eq 'transfer' ) {
    my ( undef, $positional ) = parse_flags( \@argv, $i + 1, \%REPO );
    my ( undef, @from ) = cmd_targets( $i + 1, \%REPO );
    guard_targets( $ASK, @from, repo_name( $positional->[2] ) );
    run_real(@argv);
}
if ( $sub eq 'release' && $action eq 'upload' ) {
    guard_targets( cmd_targets( $i + 1, \%REPO ) );
    run_real(@argv);
}
if ( $sub eq 'gist' && $action =~ /^(?:create|new|edit)\z/ ) {
    block("$PRIVATE and gists are readable by anyone with the link")
        if private_context();
    run_real(@argv);
}
```

(The trailer check runs first: it is local and fails fast without network.)

- [ ] **Step 7: Run tests to verify they pass**

Run: `node_modules/.bin/bats test/gh-wrapper.bats`
Expected: all PASS.

- [ ] **Step 8: Header comment and explainer doc**

In the `bin/gh` header comment, after the "Scope:" paragraph, add:

```perl
# Also, in a session whose repo is private, writes to any repo that is not
# private/internal (or listed in ~/.config/gh/wrapper-allow-public) are
# refused: docs/gh-wrapper-visibility.md.
```

Create `docs/gh-wrapper-visibility.md`:

```markdown
# gh wrapper: private-to-public guard

`bin/gh` refuses, inside a Claude session, any write that would carry content
from a private context to a non-private repository. The threat is accidents
(an embargoed CVE posted as a public issue, or a fix branch pushed upstream),
not a hostile agent.

## Rule

- The session is private if any GitHub remote of cwd's repo, or of
  `$NN_SESSION_DIR`'s repo (exported by `bin/nn`), is not public. A failed
  lookup counts as private.
- In a private session, every target of a write must be `private`, `internal`,
  or listed in `~/.config/gh/wrapper-allow-public` (one `owner/repo` per line,
  `#` comments). Unknown targets and failed lookups are refused.
- Without `-R` or a URL, the targets are `$GH_REPO`, else every GitHub remote
  of cwd plus any `gh repo set-default` choice. gh would pick one, preferring
  `upstream`, so a private repo with a public `upstream` remote is exactly the
  risky setup; there the agent must pass `-R`.

## Overrides

The allowlist is the only override. Nono mounts `~/.config/gh` read-only, so
the agent can't add to it. There is no env-var escape hatch: an agent that hits
a block would set it.

## Covered

issue/pr/release writes, `issue transfer`, `release upload`, gists, `gh api`
REST writes, GraphQL mutations (judged by cwd's repo), and `git push` under
`nn` (via `gh auth git-credential` with `credential.useHttpPath`; git only
asks for credentials after a 401, so public fetches never reach it).

## Not covered

- A session in a repo with no GitHub remote (or none yet) is unrestricted.
- GraphQL mutations name their target only by node ID; they are judged by
  cwd's repo, so a mutation aimed at a public repo from a private checkout
  passes.
- Making a repo public (`repo edit --visibility`, `gh api -X PATCH
  repos/o/r`): deliberate, not an accident.
- Content-carrying subcommands the wrapper doesn't classify:
  `workflow run -f`, `repo edit --description`, `project item-create`,
  labels, and the like.
- Calling `/usr/bin/gh` directly, `curl` with a token, or `gh auth token`.
- Hosts other than github.com.

Visibility comes from the real `gh` at write time, a few API calls per write.
```

- [ ] **Step 9: Lint and commit**

Run: `precious lint bin/gh` (fix anything reported with `precious tidy bin/gh`).

```bash
git add bin/gh test/gh-wrapper.bats docs/gh-wrapper-visibility.md
git commit -m "gh wrapper: refuse public writes from private sessions

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: `gh api` REST writes and GraphQL mutations

**Files:**
- Modify: `bin/gh` (helper next to `cmd_targets`; api section after `$graphql` is computed; graphql section after the "not a mutation" `run_real`)
- Test: `test/gh-wrapper.bats`

**Interfaces:**
- Consumes: `guard_targets`, `repo_name`, `default_targets`, `$ASK` (Task 1); `$endpoint`, `$method`, `$graphql` (existing api section)
- Produces: `api_targets($endpoint)` → `($hint, @repos)`, or empty list for an exempt endpoint

- [ ] **Step 1: Write the failing tests**

```bash
@test "a private session's api writes are checked by repo path" {
    private_repo
    vis org/proj public
    gh_run api repos/org/proj/issues -f title=t -f body="$GEN"
    assert_refused
    [[ "$output" == *"org/proj is public; ask the user"* ]]
    gh_run api -X DELETE /repos/org/proj/labels/x
    assert_refused
    gh_run api https://api.github.com/repos/org/proj/issues/1/comments -f body="$GEN"
    assert_refused
    gh_run api repos/me/secret/issues -f title=t -f body="$GEN"
    assert_passed
}

@test "api {owner}/{repo} placeholders resolve to cwd's remotes" {
    private_repo
    gh_run api 'repos/{owner}/{repo}/issues/1/comments' -f body="$GEN"
    assert_passed
    git remote add upstream git@github.com:org/proj.git
    vis org/proj public
    gh_run api 'repos/{owner}/{repo}/issues/1/comments' -f body="$GEN"
    assert_refused
    [[ "$output" == *"instead of {owner}/{repo}"* ]]
}

@test "api writes outside repos/ are refused unless exempt" {
    private_repo
    gh_run api gists -f description=x
    assert_refused
    [[ "$output" == *"can't be determined"* ]]
    [[ "$output" != *"-R"* ]]
    gh_run api markdown -f text=hi
    assert_passed
    gh_run api -X PATCH notifications/threads/1
    assert_passed
    gh_run api -X PUT user/starred/org/proj
    assert_passed
}

@test "api reads are never checked" {
    private_repo
    vis org/proj public
    gh_run api repos/org/proj/issues
    assert_passed
    gh_run api -X GET repos/org/proj/issues -f state=open
    assert_passed
    refute_lookups
}

@test "a private session's graphql mutations are judged by cwd's repo" {
    private_repo
    q='mutation { resolveReviewThread(input: {threadId: "PRRT_x"}) { clientMutationId } }'
    gh_run api graphql -f "query=$q"
    assert_passed
    git remote add upstream https://github.com/org/proj
    vis org/proj public
    gh_run api graphql -f "query=$q"
    assert_refused
    [[ "$output" == *"run it from a checkout"* ]]
    gh_run api graphql -f 'query={ viewer { login } }'
    assert_passed
}

@test "public sessions' graphql mutations need no lookup of a target" {
    q='mutation { resolveReviewThread(input: {threadId: "PRRT_x"}) { clientMutationId } }'
    gh_run api graphql -f "query=$q"
    assert_passed
    refute_lookups
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `node_modules/.bin/bats test/gh-wrapper.bats -f 'api|graphql'`
Expected: the new refusal cases FAIL.

- [ ] **Step 3: Implement**

Add next to `cmd_targets`:

```perl
# gh api fills {owner}/{repo} from cwd. Rendering markdown, marking
# notifications read and starring post nothing, so they are exempt.
sub api_targets {
    my ($endpoint) = @_;
    ( my $e = $endpoint // q{} ) =~ s{^(?:https?://[^/]+)?/*}{};
    return if $e =~ m{^(?:markdown|notifications|user/starred)(?:[/?#]|\z)};
    return ( $ASK, undef ) if $e !~ m{^repos/([^/]+)/([^/?#]+)};
    my ( $owner, $repo ) = ( $1, $2 );
    return ( 'name the repository instead of {owner}/{repo}',
        default_targets() )
        if $owner eq '{owner}';
    return ( $ASK, repo_name("$owner/$repo") );
}
```

In the api section, directly after the `my $graphql = ...;` line, add:

```perl
if ( !$graphql
    && defined $method
    && uc($method) =~ /^(?:POST|PATCH|PUT|DELETE)$/ ) {
    my @targets = api_targets($endpoint);
    guard_targets(@targets) if @targets;
}
```

In the graphql section, directly after:

```perl
run_real(@argv) if !defined $query || $query !~ /\bmutation\b/;
```

add:

```perl
# Mutations name their target only by node ID; judge them by cwd's repo.
guard_targets( "run it from a checkout of the repository it writes to, or $ASK",
    default_targets() );
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `node_modules/.bin/bats test/gh-wrapper.bats`
Expected: all PASS.

- [ ] **Step 5: Lint and commit**

```bash
precious lint bin/gh
git add bin/gh test/gh-wrapper.bats
git commit -m "gh wrapper: guard api writes and graphql mutations

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: `git push` via the credential helper, and `nn` wiring

**Files:**
- Modify: `bin/gh` (main flow, before the `if ($cmd)` block)
- Modify: `bin/nn:551-575` (comment + env lines)
- Test: `test/gh-wrapper.bats`, `test/nn.bats`
- Modify: `nono/CLAUDE.md` (bullet after the `GIT_CONFIG_*` one, ~line 143)

**Interfaces:**
- Consumes: `read_body`, `guard_targets`, `repo_name`, `private_context`, `block`, `$PRIVATE`, `$ASK` (Task 1)

Git asks the credential helper only after a 401, so fetches of public repos never reach it; pushes and private fetches do. With `credential.useHttpPath=true` git sends `path=owner/repo.git`. When git calls the helper it exports `GIT_DIR`; Task 1's `git_config_values` already clears it.

- [ ] **Step 1: Write the failing wrapper tests**

```bash
cred() {
    run env "$@" bash -c "printf '%b' \"\$REQ\" | '$GH' auth git-credential \"\$VERB\""
}

@test "a private session's git pushes to public repos get no credentials" {
    private_repo
    vis org/proj public
    REQ='protocol=https\nhost=github.com\npath=org/proj.git\n\n' VERB=get cred
    [ "$status" -eq 1 ]
    [[ "$output" == *"org/proj is public"* ]]
    [ ! -e "$OUT" ]
    rm -f "$OUT.stdin"
    REQ='protocol=https\nhost=github.com\npath=me/secret.git\n\n' VERB=get cred
    [ "$status" -eq 0 ]
    grep -qx 'path=me/secret.git' "$OUT.stdin"
}

@test "the push guard reads the session repo despite git's GIT_DIR" {
    private_repo
    export NN_SESSION_DIR="$REPO_DIR"
    mkdir "$BATS_TEST_TMPDIR/pub"
    cd "$BATS_TEST_TMPDIR/pub"
    git init -q
    git remote add origin https://github.com/org/proj.git
    vis org/proj public
    REQ='protocol=https\nhost=github.com\npath=org/proj.git\n\n' VERB=get \
        cred GIT_DIR="$BATS_TEST_TMPDIR/pub/.git"
    [ "$status" -eq 1 ]
    [[ "$output" == *"org/proj is public"* ]]
}

@test "a credential request without a path is refused in a private session" {
    private_repo
    REQ='protocol=https\nhost=github.com\n\n' VERB=get cred
    [ "$status" -eq 1 ]
    [[ "$output" == *"useHttpPath"* ]]
}

@test "credential store and erase pass through in a private session" {
    private_repo
    for verb in store erase; do
        rm -f "$OUT.stdin"
        REQ='protocol=https\nhost=github.com\nusername=x\npassword=y\n\n' VERB=$verb cred
        [ "$status" -eq 0 ]
        grep -qx 'password=y' "$OUT.stdin"
    done
}

@test "public sessions' credential requests pass through without lookups" {
    REQ='protocol=https\nhost=github.com\npath=org/proj.git\n\n' VERB=get cred
    [ "$status" -eq 0 ]
    [ ! -e "$OUT.lookups" ]
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `node_modules/.bin/bats test/gh-wrapper.bats -f 'credential|push'`
Expected: the refusal cases FAIL. (The `GIT_DIR` test must fail too if `git_config_values` is temporarily changed not to clear `GIT_DIR` — check this once, then restore.)

- [ ] **Step 3: Implement in `bin/gh`**

Insert immediately before `if ($cmd) {`:

```perl
if (   $sub eq 'auth'
    && $action eq 'git-credential'
    && $argv[-1] eq 'get'
    && private_context() ) {
    my ( $request, $path ) = read_body(q{-});
    my %kv = $request =~ /^(\w+)=(.*)$/mg;
    if ( lc( $kv{host} // q{} ) eq 'github.com' ) {
        block(    "$PRIVATE and git did not say which repository it wants"
                . ' credentials for; set credential.useHttpPath=true' )
            if !defined $kv{path};
        guard_targets( $ASK, repo_name( $kv{path} ) );
    }
    open STDIN, '<', $path or block('cannot replay the credential request');
    run_real(@argv);
}
```

(`read_body('-')` copies stdin to a temp file; `run_real` forks because a temp file exists, and the child inherits the reopened STDIN.)

- [ ] **Step 4: Run wrapper tests to verify they pass**

Run: `node_modules/.bin/bats test/gh-wrapper.bats`
Expected: all PASS.

- [ ] **Step 5: Write the failing `nn` test**

Append to `test/nn.bats`:

```bash
@test "nn wires the gh wrapper's private-to-public guard" {
    run "$NN"
    [ "$status" -eq 0 ]
    grep -Fxq -- "GIT_CONFIG_COUNT=5" "$BATS_TEST_TMPDIR/nono-argv"
    grep -Fxq -- "GIT_CONFIG_KEY_4=credential.https://github.com.useHttpPath" "$BATS_TEST_TMPDIR/nono-argv"
    grep -Fxq -- "GIT_CONFIG_VALUE_4=true" "$BATS_TEST_TMPDIR/nono-argv"
    grep -Fxq -- "GIT_TERMINAL_PROMPT=0" "$BATS_TEST_TMPDIR/nono-argv"
    grep -Fxq -- "NN_SESSION_DIR=$PWD" "$BATS_TEST_TMPDIR/nono-argv"
}
```

Run: `node_modules/.bin/bats test/nn.bats -f 'private-to-public'`
Expected: FAIL.

- [ ] **Step 6: Implement in `bin/nn`**

Extend the comment above the `exec` (after the "GIT_CONFIG_* rewrites ..." paragraph):

```bash
# useHttpPath and NN_SESSION_DIR feed bin/gh's private-to-public guard: which
# repo a push targets, and which repo the session belongs to after a cd.
# GIT_TERMINAL_PROMPT=0 keeps a refused push from ending in a username prompt
# that buries the refusal. See docs/gh-wrapper-visibility.md.
```

Change the env lines:

```bash
    GIT_CONFIG_COUNT=5 \
    GIT_CONFIG_KEY_0=url.https://github.com/.insteadOf GIT_CONFIG_VALUE_0=git@github.com: \
    GIT_CONFIG_KEY_1=url.https://github.com/.insteadOf GIT_CONFIG_VALUE_1=ssh://git@github.com/ \
    GIT_CONFIG_KEY_2=credential.https://github.com.helper GIT_CONFIG_VALUE_2= \
    GIT_CONFIG_KEY_3=credential.https://github.com.helper \
    GIT_CONFIG_VALUE_3='!gh auth git-credential' \
    GIT_CONFIG_KEY_4=credential.https://github.com.useHttpPath GIT_CONFIG_VALUE_4=true \
    GIT_TERMINAL_PROMPT=0 \
    NN_SESSION_DIR="$PWD" \
```

- [ ] **Step 7: Run both suites**

Run: `node_modules/.bin/bats test/nn.bats test/gh-wrapper.bats`
Expected: all PASS.

- [ ] **Step 8: Document in `nono/CLAUDE.md`**

After the `GIT_CONFIG_*` bullet, add:

```markdown
- `nn` also sets `credential.https://github.com.useHttpPath=true`, `GIT_TERMINAL_PROMPT=0` and `NN_SESSION_DIR=$PWD` for `bin/gh`'s private-to-public guard: [docs/gh-wrapper-visibility.md](../docs/gh-wrapper-visibility.md).
```

- [ ] **Step 9: Lint and commit**

```bash
precious lint bin/gh bin/nn
markdownlint-cli nono/CLAUDE.md docs/gh-wrapper-visibility.md
git add bin/gh bin/nn test/gh-wrapper.bats test/nn.bats nono/CLAUDE.md
git commit -m "Guard git pushes from private nn sessions via the gh credential helper

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 10: REQUIRED before merging — manual check in a real `nn` session**

No automated test covers git → credential helper → wrapper end to end. Ask the user to run, on the host:

1. Start `nn` in a private repo. `git push` to its own origin succeeds.
2. In the same session, `cd` into a worktree or clone of a public repo they own and `git push` a throwaway branch. It must fail with the `gh-wrapper: refusing to post` message, not a username prompt.
3. `gh issue create -R <public repo> --title t --body …` from the private repo is refused.

Do not open the PR as ready until the user confirms all three.
