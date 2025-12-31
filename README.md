# 🎬 AutoCaptions

**Free AI-powered automatic subtitles for DaVinci Resolve**

[![Download](https://img.shields.io/badge/Download-Latest%20Release-22c55e?style=for-the-badge)](https://github.com/razzyyyyy/AutoCaptions/releases/latest)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)

---

## ✨ Features

- **🧠 Whisper AI** - Uses OpenAI's state-of-the-art speech recognition
- **💻 Runs Locally** - No internet required, your videos stay private
- **🎨 Custom Styling** - Use your own Text+ templates for branding
- **⚡ One-Click** - Select settings, click Start, done
- **🆓 100% Free** - No subscriptions, no limits, open source forever
- **🌍 99+ Languages** - Transcribe in almost any language

---

## 📥 Installation

### Requirements
- Windows 10/11
- [Python 3.8+](https://www.python.org/downloads/) (check "Add to PATH" during install)
- DaVinci Resolve 18+ (Free or Studio)
- ~2GB free disk space (for AI models)

### Steps

1. **Download** the [latest release](https://github.com/razzyyyyy/AutoCaptions/releases/latest)
2. **Extract** the ZIP to any folder (e.g., `Downloads\AutoCaptions`)
3. **Run** `install.bat` (double-click it)
4. **Done!** Open DaVinci Resolve

---

## 🚀 Usage

1. Open your project in DaVinci Resolve
2. Select the timeline you want to caption
3. Go to **Workspace → Scripts → AutoCaptions**
4. Configure your settings:
   - **Audio Track** - Which audio to transcribe
   - **Model** - AI accuracy (tiny=fast, large=accurate, turbo=balanced)
   - **Language** - Audio language or "auto" to detect
   - **Words/line** - How many words per subtitle
   - **Output** - Subtitle track or video track
   - **Template** - Your styled Text+ (optional)
5. Click **START**
6. Subtitles appear on your timeline!

---

## 🎨 Using Custom Styles

Want your own font, colors, and animations?

1. Create a **Text+** on your timeline
2. Style it however you want (font, size, color, stroke, shadow, position, animation)
3. Drag it into the **Media Pool**
4. Run AutoCaptions and select it as the **Template**
5. All subtitles will use your styling!

---

## 🤖 Whisper Models

| Model | Speed | Accuracy | VRAM | Best For |
|-------|-------|----------|------|----------|
| tiny | ⚡⚡⚡⚡ | ★★☆☆☆ | ~1GB | Quick drafts |
| base | ⚡⚡⚡ | ★★★☆☆ | ~1GB | General use |
| small | ⚡⚡ | ★★★★☆ | ~2GB | Good balance |
| medium | ⚡ | ★★★★☆ | ~5GB | High accuracy |
| large-v3 | 🐢 | ★★★★★ | ~10GB | Best quality |
| turbo | ⚡⚡⚡ | ★★★★☆ | ~6GB | Fast + accurate |

`.en` variants (e.g., `base.en`) are optimized for English only.

---

## 🔧 Troubleshooting

### "AutoCaptions installation not found"
Run `install.bat` again. Don't move the folder after installing.

### "Python is not installed"
Download Python from [python.org](https://python.org/downloads). Make sure to check **"Add Python to PATH"**.

### Subtitles are misaligned
- Use the **turbo** or **medium** model for better timing
- Set a lower **Words/line** value

### Script doesn't appear in Workspace → Scripts
Run `install.bat` as Administrator.

---

## 📁 Files

```
AutoCaptions/
├── install.bat           # Run this first!
├── AutoCaptions.lua      # Main script (copied to Resolve)
├── autocaptions_gui.py   # GUI application
├── whisper_transcribe.py # Whisper integration
├── README.md             # This file
└── docs/                 # Website files
    └── index.html
```

**⚠️ Don't delete this folder after installing!** The scripts reference files here.

---

## 🤝 Contributing

Pull requests welcome! Feel free to:
- Report bugs
- Suggest features
- Improve documentation
- Add translations

---

## 📄 License

MIT License - Use it however you want!

---

## 💖 Credits

- [OpenAI Whisper](https://github.com/openai/whisper) - Amazing speech recognition
- [DaVinci Resolve](https://www.blackmagicdesign.com/products/davinciresolve) - Incredible free video editor
- [CustomTkinter](https://github.com/TomSchimansky/CustomTkinter) - Modern Python GUI

---

<p align="center">
  Made with ❤️ for the video editing community
</p>
