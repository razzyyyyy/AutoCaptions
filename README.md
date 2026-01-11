# 🎬 AutoCaptions

**Free AI-powered automatic subtitles for DaVinci Resolve**

[![Download](https://img.shields.io/badge/Download-Latest%20Release-22c55e?style=for-the-badge)](https://github.com/razzyyyyy/AutoCaptions/releases/latest)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)

---

## ✨ Features

- **🧠 Whisper AI** - Uses OpenAI's state-of-the-art speech recognition
- **🎤 Speaker Detection** - Automatically detect and color-code different speakers
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
- [FFmpeg](https://www.gyan.dev/ffmpeg/builds/) (for audio processing - installer tries to auto-install)
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
   - **Speakers** - Number of speakers (1, 2, 3, 4, or Auto)
   - **Words/line** - How many words per subtitle
   - **Output** - Subtitle track or video track
   - **Template** - Your styled Text+ (optional)
5. Click **START**
6. Subtitles appear on your timeline!

---

## 🎤 Speaker Detection

AutoCaptions can automatically detect and distinguish between multiple speakers!

### How It Works
1. Toggle **"Detect multiple speakers"** ON
2. Optionally set the max number of speakers
3. Click **START** - AI transcribes and detects speakers
4. A popup appears showing detected speakers
5. **Customize each speaker's style** (name, color)
6. Click "Add Subtitles" - done!

### Speaker Styles
- **Text+ Output**: Each speaker's subtitles appear in their assigned color
- **Subtitle Track**: Speaker names are added as prefixes like `[Host] Hello!`

### Tips
- For best results, use audio where speakers take turns (interviews, podcasts)
- The "Auto" setting tries to detect the number of speakers automatically
- Rename speakers to real names (e.g., "Alex", "Jordan") for clearer subtitles

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

### "FileNotFoundError: The system cannot find the file specified" during transcription
**FFmpeg is not installed.** Whisper needs FFmpeg to decode audio files.

**Fix:**
1. Download FFmpeg from [gyan.dev](https://www.gyan.dev/ffmpeg/builds/) (get "ffmpeg-release-essentials.zip")
2. Extract to `C:\ffmpeg`
3. Add `C:\ffmpeg\bin` to your system PATH:
   - Search "Environment Variables" in Windows
   - Click "Environment Variables"
   - Under "System variables", find "Path" and click Edit
   - Click "New" and add `C:\ffmpeg\bin`
   - Click OK, restart your computer
4. Run `install.bat` again

**Alternative:** Run `winget install ffmpeg` in Command Prompt (Windows 10/11)

### "AutoCaptions installation not found"
Run `install.bat` again. Don't move the folder after installing.

### "Python is not installed"
Download Python from [python.org](https://python.org/downloads). Make sure to check **"Add Python to PATH"**.

### Subtitles are misaligned
- Use the **turbo** or **medium** model for better timing
- Set a lower **Words/line** value

### Script doesn't appear in Workspace → Scripts
Run `install.bat` as Administrator.

### Something else not working?
Check the `logs/` folder in your AutoCaptions directory! Share the `.log` files when reporting issues.

---

## 📁 Files

```
AutoCaptions/
├── install.bat           # Run this first!
├── AutoCaptions.lua      # Main script (copied to Resolve)
├── autocaptions_gui.py   # GUI application
├── whisper_transcribe.py # Whisper integration
├── README.md             # This file
├── CHANGELOG.md          # Version history
├── logs/                 # Debug logs (check here for errors!)
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
