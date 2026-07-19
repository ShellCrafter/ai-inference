#!/data/data/com.termux/files/usr/bin/bash
#
# ShellCrafter :: ai-inference
# run_ai.sh — launched via the `runqwen` command.
# Runs the locally-installed Qwen3.5 0.8B GGUF model with llama.cpp.
# 100% offline. No downloads, no network calls, ever.

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
    C_CYAN="\033[38;5;80m"
    C_MAGENTA="\033[38;5;170m"
    C_GRAY="\033[38;5;245m"
else
    C_RESET=""; C_BOLD=""; C_DIM=""; C_RED=""; C_GREEN=""
    C_YELLOW=""; C_CYAN=""; C_MAGENTA=""; C_GRAY=""
fi

# --------------------------------------------------------------------------
# Constants
# --------------------------------------------------------------------------
readonly MODELS_DIR="${HOME}/models"
readonly MODEL_FILE="Qwen3.5-0.8B-Q4_K_M.gguf"
readonly MODEL_PATH="${MODELS_DIR}/${MODEL_FILE}"

# --------------------------------------------------------------------------
# Banner
# --------------------------------------------------------------------------
print_banner() {
    printf "${C_CYAN}${C_BOLD}"
    printf "  =====================================\n"
    printf "        ShellCrafter AI\n"
    printf "  =====================================\n"
    printf "${C_RESET}"
    printf "  ${C_GRAY}Model :${C_RESET} Qwen 3.5 0.8B\n"
    printf "  ${C_GRAY}Engine:${C_RESET} llama.cpp\n\n"
}

# --------------------------------------------------------------------------
# Pre-flight checks
# --------------------------------------------------------------------------
check_model() {
    if [ ! -f "$MODEL_PATH" ]; then
        printf "${C_RED}${C_BOLD}✘ Model not found:${C_RESET} %s\n\n" "$MODEL_PATH"
        printf "  It looks like the model was never downloaded, or was moved/deleted.\n"
        printf "  Please re-run the installer to fetch it again:\n\n"
        printf "      ${C_CYAN}bash install.sh${C_RESET}\n\n"
        exit 1
    fi

    if ! command -v llama-cli >/dev/null 2>&1; then
        printf "${C_RED}${C_BOLD}✘ llama-cli not found.${C_RESET}\n\n"
        printf "  Please re-run the installer:\n\n"
        printf "      ${C_CYAN}bash install.sh${C_RESET}\n\n"
        exit 1
    fi
}

# --------------------------------------------------------------------------
# Mode selection
# --------------------------------------------------------------------------
select_mode() {
    printf "  ${C_BOLD}Select Mode${C_RESET}\n"
    printf "  ${C_GREEN}1.${C_RESET} Instant ⚡\n"
    printf "  ${C_MAGENTA}2.${C_RESET} Thinking 🧠\n\n"
    printf "  ${C_BOLD}Choice:${C_RESET} "
    read -r choice

    case "$choice" in
        1)
            printf "\n${C_GREEN}➤ Launching in Instant mode...${C_RESET}\n\n"
            exec llama-cli -m "$MODEL_PATH" \
                --chat-template-kwargs '{"enable_thinking":false}'
            ;;
        2)
            printf "\n${C_MAGENTA}➤ Launching in Thinking mode...${C_RESET}\n\n"
            exec llama-cli -m "$MODEL_PATH"
            ;;
        *)
            printf "\n${C_YELLOW}⚠ Invalid choice '%s'. Defaulting to Instant ⚡${C_RESET}\n\n" "$choice"
            exec llama-cli -m "$MODEL_PATH" \
                --chat-template-kwargs '{"enable_thinking":false}'
            ;;
    esac
}

# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------
main() {
    print_banner
    check_model
    select_mode
}

main "$@"
