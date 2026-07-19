# ShellCrafter AI Inference

Run Qwen 3.5 0.8B locally on Android using Termux.

## Installation

```bash
apt update && apt full-upgrade -y
pkg install git -y

git clone https://github.com/ShellCrafter/ai-inference.git

cd ai-inference

chmod +x install.sh

bash install.sh
```

## Usage

```bash
runqwen
```

The first launch downloads the model automatically.

Future launches use the cached model.

No thinking mode is enabled by default.
