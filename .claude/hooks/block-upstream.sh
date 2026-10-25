#!/usr/bin/env bash
# PreToolUse hook (Bash): fork 元 (juichi50iii/KobitoKey_QWERTY) への一切の操作をブロックする。
# 自分の fork は itouuuuuuuuu/KobitoKey_QWERTY のみ許可。
set -u

UPSTREAM_OWNER="juichi50iii"
UPSTREAM_REPO_ID="R_kgDOP4pspg"
OWN_REPO="itouuuuuuuuu/KobitoKey_QWERTY"

input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty')"
[ -z "$cmd" ] && exit 0

deny() {
  echo "BLOCKED by .claude/hooks/block-upstream.sh: $1" >&2
  echo "fork 元 (${UPSTREAM_OWNER}) への操作は禁止されています。対象は ${OWN_REPO} のみ使用してください。" >&2
  exit 2
}

lc="$(printf '%s' "$cmd" | tr '[:upper:]' '[:lower:]')"

# 1. fork 元のオーナー名 / リポジトリ ID を含むコマンドはすべて拒否
case "$lc" in
  *"$UPSTREAM_OWNER"*) deny "コマンドに '${UPSTREAM_OWNER}' が含まれています" ;;
esac
case "$cmd" in
  *"$UPSTREAM_REPO_ID"*) deny "コマンドに fork 元のリポジトリ ID が含まれています" ;;
esac

# 2. URL が fork 元を指す git remote への push / fetch 等を拒否
if printf '%s' "$lc" | grep -qE '(^|[;&|[:space:]])git[[:space:]]'; then
  while read -r name url _; do
    [ -z "${name:-}" ] && continue
    case "$(printf '%s' "$url" | tr '[:upper:]' '[:lower:]')" in
      *"$UPSTREAM_OWNER"*)
        if printf '%s' "$cmd" | grep -qE "(^|[[:space:]])${name}([[:space:]/:]|\$)"; then
          deny "remote '${name}' は fork 元を指しています"
        fi ;;
    esac
  done < <(git remote -v 2>/dev/null | awk '{print $1, $2}' | sort -u)
fi

# 3. gh コマンド: PR 作成 / issue 作成 / default repo 変更 は自分の fork 以外を拒否
if printf '%s' "$lc" | grep -qE '(^|[;&|[:space:]])gh[[:space:]]'; then
  if printf '%s' "$lc" | grep -qE 'gh[[:space:]]+(pr|issue)[[:space:]]+(create|comment|edit|merge|close|review|ready|reopen)|gh[[:space:]]+repo[[:space:]]+set-default|gh[[:space:]]+api'; then
    target=""
    if printf '%s' "$cmd" | grep -qE '(-R|--repo)[[:space:]=]'; then
      target="$(printf '%s' "$cmd" | grep -oE '(-R|--repo)[[:space:]=]+[^[:space:]]+' | head -1 | sed -E 's/^(-R|--repo)[[:space:]=]+//; s#^https?://github.com/##')"
    elif printf '%s' "$lc" | grep -qE 'gh[[:space:]]+repo[[:space:]]+set-default'; then
      target="$(printf '%s' "$cmd" | grep -oE 'set-default[[:space:]]+[^-][^[:space:]]*' | head -1 | sed -E 's/^set-default[[:space:]]+//; s#^https?://github.com/##')"
      [ -z "$target" ] && deny "gh repo set-default は '${OWN_REPO}' を明示してください"
    elif printf '%s' "$lc" | grep -qE 'gh[[:space:]]+api'; then
      target="$(printf '%s' "$cmd" | grep -oE 'repos/[^/[:space:]]+/[^/[:space:]]+' | head -1 | sed 's#^repos/##')"
    else
      target="$(gh repo set-default --view 2>/dev/null || true)"
      [ -z "$target" ] && deny "gh のデフォルトリポジトリが未設定です (gh repo set-default ${OWN_REPO} を実行してください)"
    fi
    if [ -n "$target" ]; then
      target="${target%.git}"
      case "$target" in
        "$OWN_REPO"|"$OWN_REPO"/*|"https://github.com/$OWN_REPO"*) ;;
        *) deny "対象リポジトリ '${target}' は自分の fork (${OWN_REPO}) ではありません" ;;
      esac
    fi
  fi
fi

exit 0
