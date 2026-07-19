# ShellCrafter / ai-inference

**Run a local LLM on your Android phone — fully offline, no cloud, no API keys.**

`ai-inference` turns any Android device into a private, self-contained AI machine using [Termux](https://termux.dev/) and [llama.cpp](https://github.com/ggml-org/llama.cpp). One install script downloads everything you need, including the model. After that, you can turn off Wi-Fi and mobile data forever and still chat with your local AI using a single command: `runqwen`.

---

## ✨ Features

- 🚀 **One-command install** — `bash install.sh` does everything
- 📴 **Truly offline after setup** — the model is downloaded once during installation, never at runtime
- 🧠 **Two inference modes** — Instant (fast, no reasoning) and Thinking (chain-of-thought reasoning)
- 🎨 **Beautiful colored terminal UI** — clean banners and status output
- 🔁 **Idempotent installer** — safe to re-run; won't re-download or break an existing setup
- 🛡️ **Robust error handling** — detects Termux, verifies storage permission, validates the model file (GGUF header + size check)
- 📦 **Small footprint model** — Qwen3.5 0.8B, quantized to Q4_K_M (~530 MB), tuned to run smoothly on phones
- 🧩 **No hardcoded paths** — built entirely around Termux's `$PREFIX` and `$HOME`

---

## 📥 Installation

```bash
apt update && apt full-upgrade -y
pkg install git -y
git clone https://github.com/ShellCrafter/ai-inference.git
cd ai-inference
chmod +x install.sh
bash install.sh
```

That's it. The installer will:

1. Detect Termux and verify your environment
2. Check/request storage permission
3. Install `llama-cpp` (via `pkg`) if it isn't already installed
4. Create `~/models` and download **Qwen3.5-0.8B-Q4_K_M.gguf** directly into it (not the llama.cpp cache)
5. Verify the downloaded file (size + GGUF magic header check)
6. Install the runtime into `~/.shellcrafter`
7. Create the `runqwen` command in `$PREFIX/bin`

Once it finishes, you're done — permanently. You can turn on airplane mode and the model will keep working.

---

## ▶️ Usage

From anywhere in Termux, just run:

```bash
runqwen
```

You'll see:

```
=====================================
      ShellCrafter AI
=====================================
Model : Qwen 3.5 0.8B
Engine: llama.cpp

Select Mode
1. Instant ⚡
2. Thinking 🧠

Choice:
```

- **Instant ⚡** — fast responses, thinking mode disabled (`--chat-template-kwargs '{"enable_thinking":false}'`)
- **Thinking 🧠** — full chain-of-thought reasoning mode

No internet connection is used or required at any point during `runqwen`.

---

## 📸 Screenshots

> _Add screenshots or a terminal recording (e.g. via [asciinema](https://asciinema.org/)) here to showcase the install process and chat session._

| Install | Chat |
|---|---|
| _(screenshot placeholder)_ | _(screenshot placeholder)_ |

---

## ✅ Requirements

- Android device with [Termux](https://termux.dev/) installed (F-Droid build recommended)
- ~1.5 GB of free storage (model + llama.cpp + overhead)
- Internet connection **only during installation**
- 64-bit ARM device (arm64-v8a) recommended for best llama.cpp performance

---

## 🗂️ Project Structure

```
ai-inference/
├── install.sh      # One-time installer (downloads model, sets up runqwen)
├── run_ai.sh        # Runtime script launched by `runqwen`
├── README.md
├── LICENSE
└── .gitignore
```

---

## 🔧 Troubleshooting

| Problem | Fix |
|---|---|
| `Termux was not detected` | Make sure you're running this inside the actual Termux app, not another shell |
| Download fails | Check your connection and re-run `bash install.sh` — it will resume/retry automatically |
| `runqwen` says model not found | Re-run `bash install.sh` to re-download the model |
| Storage permission warning | Run `termux-setup-storage` manually, then re-run `bash install.sh` |

---

## 📄 License

Released under the [MIT License](LICENSE).

---

<p align="center"><sub>Built with ❤️ by ShellCrafter</sub></p>
