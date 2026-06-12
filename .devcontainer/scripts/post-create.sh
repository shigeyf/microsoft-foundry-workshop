#!/usr/bin/env bash
# -----------------------------------------------------------
# post-create.sh
#
# Runs once after the dev container is created.
# Called from devcontainer.json postCreateCommand.
# -----------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "==> [1/5] pip → uv wrapper"
WRAPPER_CONTENT='#!/usr/bin/env bash
# Auto-generated wrapper — redirects pip to uv pip.
# To restore the original pip, re-create the devcontainer.
echo "⚠️  This project uses uv. Redirecting \"pip $*\" → \"uv pip $*\"" >&2
exec uv pip "$@"
'
for bin in pip pip3; do
  target="/usr/local/bin/${bin}"
  if [[ -f "$target" ]]; then
    sudo tee "$target" > /dev/null <<< "$WRAPPER_CONTENT"
    sudo chmod +x "$target"
    echo "    replaced: ${target}"
  fi
done

echo "==> [2/5] Python venv & dependencies"
uv venv --clear --prompt .venv
uv sync --extra dev
uv run poe setup

echo "==> [3/5] direnv: hook + whitelist"
grep -q 'direnv hook bash' ~/.bashrc \
    || echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
# Trust all .envrc files under /workspaces/ automatically (no direnv allow needed)
mkdir -p ~/.config/direnv
cat > ~/.config/direnv/direnv.toml << 'EOF'
[whitelist]
prefix = ["/workspaces/"]
EOF

echo "==> [4/5] Install azd extension: microsoft.foundry"
azd extension install microsoft.foundry

echo "==> [5/5] Tool versions"
terraform version
az bicep upgrade
az version

echo "==> post-create complete"
