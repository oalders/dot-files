# Temp files

When creating temporary files or directories, default to `$TMPDIR` if it is set
in the environment, falling back to `/tmp` only when it is unset. Do not
hardcode `/tmp`. This applies to `mktemp`, scratch files, test fixtures, and
anything else that lands in a temp location.
