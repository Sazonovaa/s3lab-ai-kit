# Safe symlink helpers for sync-ai-kit
# Sourced by bin/sync-ai-kit. Do not run directly.

# Create a symlink, safely handling existing files/dirs.
# Usage: safe_symlink <relative-target> <link-path>
safe_symlink() {
    local target="$1"
    local link="$2"

    if [ -L "$link" ]; then
        # Already a symlink — check if target matches
        local current
        current=$(readlink "$link")
        if [ "$current" = "$target" ]; then
            echo "  = $link → $target (unchanged)"
            return 0
        fi
        rm "$link"
    elif [ -e "$link" ]; then
        # Real file/dir exists — back it up
        echo "  ! $link is not a symlink; backing up to $link.bak"
        mv "$link" "$link.bak"
    fi

    mkdir -p "$(dirname "$link")"
    ln -s "$target" "$link"
    echo "  ✓ $link → $target"
}

# Copy a template if missing. Never overwrites.
# Usage: copy_if_missing <source> <destination>
copy_if_missing() {
    local src="$1"
    local dst="$2"

    if [ -e "$dst" ]; then
        echo "  = $dst (exists, skipped)"
        return 0
    fi

    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "  + $dst (created)"
}

# Render a template with simple variable substitution. Never overwrites.
# Usage: render_template <source> <destination> VAR1=value1 VAR2=value2 ...
render_template() {
    local src="$1"
    local dst="$2"
    shift 2

    if [ -e "$dst" ]; then
        echo "  = $dst (exists, skipped)"
        return 0
    fi

    mkdir -p "$(dirname "$dst")"

    local content
    content=$(cat "$src")
    for assignment in "$@"; do
        local key="${assignment%%=*}"
        local value="${assignment#*=}"
        content="${content//\{\{$key\}\}/$value}"
    done

    printf '%s\n' "$content" > "$dst"
    echo "  + $dst (rendered)"
}
