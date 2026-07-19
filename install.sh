#!/data/data/com.termux/files/usr/bin/bash

clear

echo "==============================================="
echo "        ShellCrafter AI Installer v1.0"
echo "==============================================="
echo

PREFIX=${PREFIX:-/data/data/com.termux/files/usr}

echo "[1/5] Setting up storage..."
termux-setup-storage

echo
echo "[2/5] Checking llama-cpp..."

if ! command -v llama-cli >/dev/null 2>&1; then
    echo "Installing llama-cpp..."
    pkg install -y llama-cpp
else
    echo "llama-cpp already installed."
fi

echo
echo "[3/5] Creating ShellCrafter directory..."

mkdir -p "$HOME/.shellcrafter"

cp run_ai.sh "$HOME/.shellcrafter/run_ai.sh"

chmod +x "$HOME/.shellcrafter/run_ai.sh"

echo
echo "[4/5] Creating runqwen command..."

cat > "$PREFIX/bin/runqwen" << EOF
#!/data/data/com.termux/files/usr/bin/bash
bash \$HOME/.shellcrafter/run_ai.sh
EOF

chmod +x "$PREFIX/bin/runqwen"

echo
echo "[5/5] Cleaning up..."

echo
echo "==============================================="
echo " Installation Complete!"
echo
echo " Type:"
echo
echo "     runqwen"
echo
echo "==============================================="
