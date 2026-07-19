#!/data/data/com.termux/files/usr/bin/bash
#
# ShellCrafter :: ai-inference
# install.sh — one-shot installer for fully offline local LLM inference on Android/Termux
#
# Repository : https://github.com/ShellCrafter/ai-inference
# License    : MIT
#
# This script:
#   1. Verifies it is running inside Termux
#   2. Requests/verifies storage permission
#   3. Installs llama.cpp (llama-cli) if missing
#   4. Downloads the Qwen3.5-0.8B-Q4_K_M GGUF model directly into ~/models
#   5. Verifies the downloaded model file
#   6. Installs run_ai.sh into ~/.shellcrafter
#   7. Creates the "runqwen" command in $PREFIX/bin
#
# Safe to re-run at any time — idempotent.

set -u
set -o pipefail

# --------------------------------------------------------------------------
# Colors
# --------------------------------------------------------------------------
if [ -t 1 ]; then
    C_RESET="\033[0m"
    C_BOLD="\033[1m"
    C_DIM="\033[2m"
    C_RED="\033[38;5;203m"
    C_GREEN="\033[38;5;114m"
    C_YELLOW="\033[38;5;221m"
    C_BLUE="\033[38;5;75m"
    C_CYAN="\033[38;5;80m"
    C_MAGENTA="\033[38;5;170m"
    C_GRAY="\033[38;5;245m"
else
    C_RESET=""; C_BOLD=""; C_DIM=""; C_RED=""; C_GREEN=""
    C_YELLOW=""; C_BLUE=""; C_CYAN=""; C_MAGENTA=""; C_GRAY=""
fi

# --------------------------------------------------------------------------
# Constants
# --------------------------------------------------------------------------
readonly REPO_NAME="ShellCrafter/ai-inference"
readonly MODELS_DIR="${HOME}/models"
readonly CONFIG_DIR="${HOME}/.shellcrafter"
readonly MODEL_FILE="Qwen3.5-0.8B-Q4_K_M.gguf"
readonly MODEL_PATH="${MODELS_DIR}/${MODEL_FILE}"
readonly MODEL_URL="https://huggingface.co/unsloth/Qwen3.5-0.8B-GGUF/resolve/main/Qwen3.5-0.8B-Q4_K_M.gguf?download=true"
# Approximate expected size in bytes (533 MB). Used as a sanity floor, not an exact match,
# since HF may serve slightly different byte counts across mirrors/CDN nodes.
readonly MODEL_MIN_BYTES=400000000
readonly BIN_NAME="runqwen"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# --------------------------------------------------------------------------
# Logging helpers
# --------------------------------------------------------------------------
step()    { printf "\n${C_BOLD}${C_BLUE}➤ %s${C_RESET}\n" "$1"; }
ok()      { printf "  ${C_GREEN}✔ %s${C_RESET}\n" "$1"; }
warn()    { printf "  ${C_YELLOW}⚠ %s${C_RESET}\n" "$1"; }
err()     { printf "  ${C_RED}✘ %s${C_RESET}\n" "$1" >&2; }
info()    { printf "  ${C_GRAY}• %s${C_RESET}\n" "$1"; }

die() {
    err "$1"
    printf "\n${C_RED}${C_BOLD}Installation aborted.${C_RESET}\n\n"
    exit 1
}

# --------------------------------------------------------------------------
# Banner
# --------------------------------------------------------------------------
print_banner() {
    printf "${C_CYAN}"
    cat <<'EOF'

   _____ __         ____   ______           ______          
  / ___// /_  ___  / / /  / ____/________ _/ __/ /____  _____
  \__ \/ __ \/ _ \/ / /  / /   / ___/ __ `/ /_/ __/ _ \/ ___/
 ___/ / / / /  __/ / /  / /___/ /  / /_/ / __/ /_/  __/ /    
/____/_/ /_/\___/_/_/   \____/_/   \__,_/_/  \__/\___/_/     

EOF
    printf "${C_RESET}"
    printf "${C_BOLD}${C_MAGENTA}            Local AI Inference for Android · Termux${C_RESET}\n"
    printf "${C_DIM}                 https://github.com/%s${C_RESET}\n" "$REPO_NAME"
    printf "${C_GRAY}  ────────────────────────────────────────────────────────${C_RESET}\n"
}

# --------------------------------------------------------------------------
# Step 1: Detect Termux
# --------------------------------------------------------------------------
check_termux() {
    step "Detecting Termux environment"

    if [ -z "${PREFIX:-}" ] || [[ "$PREFIX" != *"com.termux"* ]]; then
        die "Termux was not detected (\$PREFIX is not set to a com.termux path). This installer only supports Termux on Android."
    fi

    if ! command -v pkg >/dev/null 2>&1; then
        die "'pkg' command not found. Please run this inside Termux."
    fi

    ok "Termux detected (PREFIX=${PREFIX})"
}

# --------------------------------------------------------------------------
# Step 2: Storage permission
# --------------------------------------------------------------------------
check_storage_permission() {
    step "Checking storage permission"

    if [ -d "${HOME}/storage" ] && [ "$(ls -A "${HOME}/storage" 2>/dev/null)" ]; then
        ok "Storage permission already granted"
        return 0
    fi

    warn "Shared storage not yet set up. Requesting permission..."
    if command -v termux-setup-storage >/dev/null 2>&1; then
        termux-setup-storage
        sleep 2
    fi

    if [ -d "${HOME}/storage" ]; then
        ok "Storage permission granted"
    else
        warn "Storage permission could not be verified. This is only needed for accessing shared/external files."
        info "Model files are stored in Termux's private home (~/models), so installation will continue."
    fi
}

# --------------------------------------------------------------------------
# Step 3: Install llama.cpp
# --------------------------------------------------------------------------
install_llama_cpp() {
    step "Checking llama.cpp installation"

    if command -v llama-cli >/dev/null 2>&1; then
        ok "llama-cli already installed ($(command -v llama-cli))"
        return 0
    fi

    info "llama-cli not found. Installing 'llama-cpp' package..."

    if ! pkg update -y >/dev/null 2>&1; then
        warn "pkg update reported issues, continuing anyway..."
    fi

    if pkg install llama-cpp -y; then
        ok "llama-cpp installed successfully"
    else
        die "Failed to install llama-cpp via pkg. Check your internet connection and try: pkg install llama-cpp -y"
    fi

    if ! command -v llama-cli >/dev/null 2>&1; then
        die "llama-cli still not found after installation. Something went wrong with the llama-cpp package."
    fi
}

# --------------------------------------------------------------------------
# Step 4: Create ~/models directory
# --------------------------------------------------------------------------
create_models_dir() {
    step "Preparing model directory"

    if mkdir -p "$MODELS_DIR"; then
        ok "Directory ready: ${MODELS_DIR}"
    else
        die "Could not create directory: ${MODELS_DIR}"
    fi
}

# --------------------------------------------------------------------------
# Step 5: Download the model (skips if already present & valid)
# --------------------------------------------------------------------------
download_model() {
    step "Downloading Qwen3.5 0.8B (Q4_K_M) model"

    if verify_model_file "silent"; then
        ok "Model already present and verified: ${MODEL_PATH}"
        info "Skipping download (re-run detected existing valid file)"
        return 0
    fi

    info "Source: unsloth/Qwen3.5-0.8B-GGUF"
    info "Target: ${MODEL_PATH}"
    info "This is a one-time download (~530 MB). The model will be stored"
    info "locally and used for ALL future runs — no internet required afterwards."
    printf "\n"

    local tmp_file="${MODEL_PATH}.part"
    rm -f "$tmp_file"

    if command -v curl >/dev/null 2>&1; then
        if ! curl -L --fail --retry 3 --retry-delay 3 -C - \
            -o "$tmp_file" \
            --progress-bar \
            "$MODEL_URL"; then
            rm -f "$tmp_file"
            die "Download failed. Check your internet connection and re-run: bash install.sh"
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -O "$tmp_file" -c "$MODEL_URL"; then
            rm -f "$tmp_file"
            die "Download failed. Check your internet connection and re-run: bash install.sh"
        fi
    else
        die "Neither curl nor wget is available. Install one with: pkg install curl -y"
    fi

    mv "$tmp_file" "$MODEL_PATH"
    ok "Download complete"
}

# --------------------------------------------------------------------------
# Step 6: Verify the downloaded model
# --------------------------------------------------------------------------
verify_model_file() {
    local silent="${1:-}"

    [ -f "$MODEL_PATH" ] || return 1

    local size
    size=$(stat -c%s "$MODEL_PATH" 2>/dev/null || wc -c < "$MODEL_PATH" 2>/dev/null)
    size=${size:-0}

    if [ "$size" -lt "$MODEL_MIN_BYTES" ]; then
        [ "$silent" != "silent" ] && warn "Model file exists but looks incomplete/corrupt (size: ${size} bytes)."
        rm -f "$MODEL_PATH"
        return 1
    fi

    # Verify GGUF magic header ("GGUF")
    local magic
    magic=$(head -c 4 "$MODEL_PATH" 2>/dev/null)
    if [ "$magic" != "GGUF" ]; then
        [ "$silent" != "silent" ] && warn "Model file failed magic-header verification."
        rm -f "$MODEL_PATH"
        return 1
    fi

    return 0
}

verify_model_or_die() {
    step "Verifying downloaded model"

    if verify_model_file; then
        local size_mb
        size_mb=$(( $(stat -c%s "$MODEL_PATH" 2>/dev/null || wc -c < "$MODEL_PATH") / 1000000 ))
        ok "Model verified (GGUF header OK, size ≈ ${size_mb} MB)"
    else
        die "Model verification failed. Please re-run: bash install.sh"
    fi
}

# --------------------------------------------------------------------------
# Step 7: Install run_ai.sh into ~/.shellcrafter
# --------------------------------------------------------------------------
install_config_dir() {
    step "Installing ShellCrafter runtime files"

    mkdir -p "$CONFIG_DIR" || die "Could not create ${CONFIG_DIR}"

    local src="${SCRIPT_DIR}/run_ai.sh"
    if [ ! -f "$src" ]; then
        die "run_ai.sh not found next to install.sh (expected at ${src})."
    fi

    cp -f "$src" "${CONFIG_DIR}/run_ai.sh" || die "Failed to copy run_ai.sh into ${CONFIG_DIR}"
    chmod +x "${CONFIG_DIR}/run_ai.sh"

    ok "Installed ${CONFIG_DIR}/run_ai.sh"
}

# --------------------------------------------------------------------------
# Step 8: Create the `runqwen` launcher command
# --------------------------------------------------------------------------
create_launcher_command() {
    step "Creating '${BIN_NAME}' command"

    local bin_dir="${PREFIX}/bin"
    local target="${bin_dir}/${BIN_NAME}"

    mkdir -p "$bin_dir" || die "Could not access ${bin_dir}"

    cat > "$target" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
exec "${CONFIG_DIR}/run_ai.sh" "\$@"
EOF

    chmod +x "$target" || die "Failed to make ${BIN_NAME} executable"

    if command -v "$BIN_NAME" >/dev/null 2>&1; then
        ok "Command '${BIN_NAME}' is ready at ${target}"
    else
        die "Command '${BIN_NAME}' was created but is not on PATH (${bin_dir} should be in \$PATH by default in Termux)."
    fi
}

# --------------------------------------------------------------------------
# Success message
# --------------------------------------------------------------------------
print_success() {
    printf "\n${C_GREEN}${C_BOLD}"
    printf "  ╔═══════════════════════════════════════════════════════╗\n"
    printf "  ║           ✔  INSTALLATION COMPLETE                     ║\n"
    printf "  ╚═══════════════════════════════════════════════════════╝\n"
    printf "${C_RESET}\n"
    printf "  ${C_BOLD}Model:${C_RESET}   Qwen3.5 0.8B (Q4_K_M)\n"
    printf "  ${C_BOLD}Path:${C_RESET}    %s\n" "$MODEL_PATH"
    printf "  ${C_BOLD}Engine:${C_RESET}  llama.cpp\n\n"
    printf "  You can now disconnect from the internet permanently.\n"
    printf "  Start chatting anytime with:\n\n"
    printf "      ${C_CYAN}${C_BOLD}%s${C_RESET}\n\n" "$BIN_NAME"
    printf "  ${C_GRAY}Powered by ShellCrafter — https://github.com/%s${C_RESET}\n\n" "$REPO_NAME"
}

# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------
main() {
    print_banner
    check_termux
    check_storage_permission
    install_llama_cpp
    create_models_dir
    download_model
    verify_model_or_die
    install_config_dir
    create_launcher_command
    print_success
}

main "$@"
