# Sourced by interactive Bash/Zsh. Keep the loop in the calling shell, not a
# pipeline subshell. Records are NUL-delimited data, never shell source.
[[ $- == *i* && $- != *x* ]] || return 0

_hm_doppler_import() {
  local _hm_key _hm_value
  while IFS= read -r -d "" _hm_key && IFS= read -r -d "" _hm_value; do
    export "$_hm_key=$_hm_value"
  done < <("$@")
}
_hm_doppler_import "$@"
unset -f _hm_doppler_import
