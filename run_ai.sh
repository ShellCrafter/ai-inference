#!/data/data/com.termux/files/usr/bin/bash

clear

echo "=========================================="
echo "           ShellCrafter AI"
echo "=========================================="
echo "Model  : Qwen 3.5 0.8B Q4_K_M"
echo "Engine : llama.cpp"
echo

echo "Select Mode:"
echo
echo "  1) Instant ⚡ (No Thinking)"
echo "  2) Thinking 🧠"
echo

read -p "Choice [1-2]: " MODE

mkdir -p "$HOME/models"
cd "$HOME/models" || exit 1

case "$MODE" in
    1)
        echo
        echo "Launching Instant Mode..."
        sleep 1
        clear
        llama-cli \
        -hf unsloth/Qwen3.5-0.8B-GGUF:Q4_K_M \
        --chat-template-kwargs '{"enable_thinking":false}'
        ;;
    2)
        echo
        echo "Launching Thinking Mode..."
        sleep 1
        clear
        llama-cli \
        -hf unsloth/Qwen3.5-0.8B-GGUF:Q4_K_M
        ;;
    *)
        echo
        echo "Invalid choice."
        exit 1
        ;;
esac
