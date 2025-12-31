"""
AutoCaptions GUI
"""

import sys
import json
import os
import time
import threading

def setup_gui():
    try:
        import customtkinter as ctk
        ctk.set_appearance_mode("dark")
        ctk.set_default_color_theme("green")
        return ctk
    except ImportError:
        os.system("pip install customtkinter")
        import customtkinter as ctk
        ctk.set_appearance_mode("dark")
        ctk.set_default_color_theme("green")
        return ctk

try:
    ctk = setup_gui()
except Exception as e:
    print(f"ERROR: {e}")
    sys.exit(1)


class AutoCaptionsGUI(ctk.CTk):
    def __init__(self, config: dict, control_path: str, status_path: str):
        super().__init__()
        
        self.config = config
        self.control_path = control_path
        self.status_path = status_path
        self.is_running = False
        
        self.title("AutoCaptions")
        self.geometry("440x720")
        self.minsize(440, 720)
        self.resizable(False, False)
        
        self.update_idletasks()
        x = (self.winfo_screenwidth() - 440) // 2
        y = (self.winfo_screenheight() - 720) // 2 - 30
        self.geometry(f"440x720+{x}+{y}")
        
        self.create_ui()
        self.protocol("WM_DELETE_WINDOW", self.on_close)
    
    def create_ui(self):
        main = ctk.CTkScrollableFrame(self, fg_color="transparent")
        main.pack(fill="both", expand=True, padx=20, pady=15)
        
        # Header
        ctk.CTkLabel(main, text="🎬 AutoCaptions", font=ctk.CTkFont(size=26, weight="bold")).pack(pady=(0, 5))
        
        # Connection badge
        badge = ctk.CTkFrame(main, fg_color="#143d2a", corner_radius=15)
        badge.pack(pady=(5, 15), padx=20)
        ctk.CTkLabel(
            badge,
            text=f"● {self.config.get('project', 'Project')} → {self.config.get('current_timeline', 'Timeline')}",
            font=ctk.CTkFont(size=11), text_color="#4ade80"
        ).pack(padx=15, pady=6)
        
        # === AUDIO SETTINGS ===
        ctk.CTkLabel(main, text="Audio", font=ctk.CTkFont(size=13, weight="bold"), anchor="w").pack(fill="x", pady=(10, 5))
        
        audio_frame = ctk.CTkFrame(main, corner_radius=10)
        audio_frame.pack(fill="x")
        
        row1 = ctk.CTkFrame(audio_frame, fg_color="transparent")
        row1.pack(fill="x", padx=15, pady=10)
        ctk.CTkLabel(row1, text="Track:", width=80, anchor="w").pack(side="left")
        audio_tracks = self.config.get("audio_tracks", ["All Audio"])
        self.audio_var = ctk.StringVar(value=audio_tracks[0])
        ctk.CTkComboBox(row1, variable=self.audio_var, values=audio_tracks, width=260).pack(side="left", padx=(10,0))
        
        # === AI SETTINGS ===
        ctk.CTkLabel(main, text="AI Settings", font=ctk.CTkFont(size=13, weight="bold"), anchor="w").pack(fill="x", pady=(15, 5))
        
        ai_frame = ctk.CTkFrame(main, corner_radius=10)
        ai_frame.pack(fill="x")
        
        row2 = ctk.CTkFrame(ai_frame, fg_color="transparent")
        row2.pack(fill="x", padx=15, pady=10)
        ctk.CTkLabel(row2, text="Model:", width=80, anchor="w").pack(side="left")
        self.model_var = ctk.StringVar(value="base")
        # All Whisper models - faster to slower, better quality
        models = [
            "tiny",      # ~1GB VRAM, fastest
            "tiny.en",   # English-only tiny
            "base",      # ~1GB VRAM, good balance
            "base.en",   # English-only base
            "small",     # ~2GB VRAM
            "small.en",  # English-only small
            "medium",    # ~5GB VRAM
            "medium.en", # English-only medium
            "large-v3",  # ~10GB VRAM, best quality
            "large-v2",  # Previous large
            "large",     # Original large
            "turbo"      # Fast + high quality
        ]
        ctk.CTkComboBox(row2, variable=self.model_var, values=models, width=260).pack(side="left", padx=(10,0))
        
        # Model info label
        ctk.CTkLabel(ai_frame, text="tiny/base=fast, medium/large=accurate, turbo=balanced", font=ctk.CTkFont(size=10), text_color="#666").pack(pady=(0, 5))
        
        row3 = ctk.CTkFrame(ai_frame, fg_color="transparent")
        row3.pack(fill="x", padx=15, pady=10)
        ctk.CTkLabel(row3, text="Language:", width=80, anchor="w").pack(side="left")
        self.language_var = ctk.StringVar(value="auto")
        languages = [
            "auto",       # Auto-detect
            "en",         # English
            "es",         # Spanish
            "fr",         # French
            "de",         # German
            "it",         # Italian
            "pt",         # Portuguese
            "nl",         # Dutch
            "pl",         # Polish
            "ru",         # Russian
            "ja",         # Japanese
            "ko",         # Korean
            "zh",         # Chinese
            "ar",         # Arabic
            "hi",         # Hindi
            "tr",         # Turkish
            "vi",         # Vietnamese
            "th",         # Thai
            "id",         # Indonesian
            "sv"          # Swedish
        ]
        ctk.CTkComboBox(row3, variable=self.language_var, values=languages, width=260).pack(side="left", padx=(10,0))
        
        # === SUBTITLE SETTINGS ===
        ctk.CTkLabel(main, text="Subtitle Settings", font=ctk.CTkFont(size=13, weight="bold"), anchor="w").pack(fill="x", pady=(15, 5))
        
        sub_frame = ctk.CTkFrame(main, corner_radius=10)
        sub_frame.pack(fill="x")
        
        # Words per subtitle
        row4 = ctk.CTkFrame(sub_frame, fg_color="transparent")
        row4.pack(fill="x", padx=15, pady=10)
        ctk.CTkLabel(row4, text="Words/line:", width=80, anchor="w").pack(side="left")
        self.words_var = ctk.StringVar(value="8")
        ctk.CTkComboBox(row4, variable=self.words_var, values=["3", "5", "8", "10", "15", "20", "No limit"], width=260).pack(side="left", padx=(10,0))
        
        # Output track
        row5 = ctk.CTkFrame(sub_frame, fg_color="transparent")
        row5.pack(fill="x", padx=15, pady=10)
        ctk.CTkLabel(row5, text="Output:", width=80, anchor="w").pack(side="left")
        self.output_var = ctk.StringVar(value="Video 1")
        video_tracks = ["Subtitle Track"] + [f"Video {i}" for i in range(1, 10)]
        ctk.CTkComboBox(row5, variable=self.output_var, values=video_tracks, width=260).pack(side="left", padx=(10,0))
        
        # Text+ Template
        row6 = ctk.CTkFrame(sub_frame, fg_color="transparent")
        row6.pack(fill="x", padx=15, pady=10)
        ctk.CTkLabel(row6, text="Template:", width=80, anchor="w").pack(side="left")
        templates = self.config.get("templates", ["(None - Use Subtitles)"])
        if not templates:
            templates = ["(None - Use Subtitles)"]
        self.template_var = ctk.StringVar(value=templates[0])
        ctk.CTkComboBox(row6, variable=self.template_var, values=templates, width=260).pack(side="left", padx=(10,0))
        
        ctk.CTkLabel(sub_frame, text="Drag a styled Text+ to Media Pool to use as template", font=ctk.CTkFont(size=10), text_color="#666").pack(pady=(0, 10))
        
        # === PROGRESS ===
        progress_frame = ctk.CTkFrame(main, corner_radius=10)
        progress_frame.pack(fill="x", pady=(15, 10))
        
        self.status_icon = ctk.CTkLabel(progress_frame, text="⏸️", font=ctk.CTkFont(size=20))
        self.status_icon.pack(pady=(15, 5))
        
        self.progress_title = ctk.CTkLabel(progress_frame, text="Ready", font=ctk.CTkFont(size=14, weight="bold"))
        self.progress_title.pack()
        
        self.progress_bar = ctk.CTkProgressBar(progress_frame, width=340, height=14)
        self.progress_bar.pack(pady=10)
        self.progress_bar.set(0)
        
        self.progress_label = ctk.CTkLabel(progress_frame, text="Click Start to begin", font=ctk.CTkFont(size=11), text_color="#888")
        self.progress_label.pack(pady=(0, 15))
        
        # === BUTTONS ===
        self.start_btn = ctk.CTkButton(
            main, text="▶  START",
            font=ctk.CTkFont(size=18, weight="bold"),
            height=55, corner_radius=10,
            fg_color="#22c55e", hover_color="#16a34a",
            text_color="#000000", command=self.on_start
        )
        self.start_btn.pack(fill="x", pady=(10, 5))
        
        ctk.CTkButton(
            main, text="Close",
            font=ctk.CTkFont(size=13), height=40, corner_radius=8,
            fg_color="#374151", hover_color="#4b5563",
            command=self.on_close
        ).pack(fill="x", pady=(5, 10))
    
    def on_start(self):
        if self.is_running:
            return
        
        self.is_running = True
        self.start_btn.configure(state="disabled", text="Processing...", fg_color="#374151")
        self.status_icon.configure(text="⏳")
        self.progress_title.configure(text="Exporting audio...")
        self.progress_label.configure(text="Please wait...", text_color="#888")
        self.progress_bar.set(0)
        
        # Parse words per line
        words = self.words_var.get()
        if words == "No limit":
            words_per_line = 999
        else:
            words_per_line = int(words)
        
        settings = {
            "command": "start",
            "audio_track": self.audio_var.get(),
            "output_track": self.output_var.get(),
            "template": self.template_var.get(),
            "model": self.model_var.get(),
            "language": self.language_var.get(),
            "words_per_line": words_per_line
        }
        
        with open(self.control_path, "w") as f:
            json.dump(settings, f)
        
        threading.Thread(target=self.monitor_status, daemon=True).start()
    
    def monitor_status(self):
        while self.is_running:
            try:
                if os.path.exists(self.status_path):
                    with open(self.status_path, "r") as f:
                        status = json.load(f)
                    
                    phase = status.get("phase", "exporting")
                    progress = status.get("progress", 0) / 100
                    message = status.get("message", "")
                    
                    icons = {"exporting": "📦", "transcribing": "🎙️", "adding": "📝"}
                    titles = {"exporting": "Exporting audio...", "transcribing": "Transcribing...", "adding": "Adding subtitles..."}
                    
                    self.after(0, lambda i=icons.get(phase, "⏳"), t=titles.get(phase, "Processing..."), p=progress, m=message: self.update_ui(i, t, p, m))
                    
                    if status.get("done"):
                        self.after(0, lambda r=status.get("result", "Complete!"): self.on_complete(r))
                        break
                    
                    if status.get("error"):
                        self.after(0, lambda e=status.get("error_message", "Error"): self.on_error(e))
                        break
            except:
                pass
            time.sleep(0.2)
    
    def update_ui(self, icon, title, progress, message):
        self.status_icon.configure(text=icon)
        self.progress_title.configure(text=title)
        self.progress_bar.set(progress)
        self.progress_label.configure(text=message)
    
    def on_complete(self, result):
        self.is_running = False
        self.start_btn.configure(state="normal", text="▶  START", fg_color="#22c55e")
        self.status_icon.configure(text="✅")
        self.progress_title.configure(text="Complete!")
        self.progress_label.configure(text=result, text_color="#4ade80")
        self.progress_bar.set(1)
    
    def on_error(self, error):
        self.is_running = False
        self.start_btn.configure(state="normal", text="▶  START", fg_color="#22c55e")
        self.status_icon.configure(text="❌")
        self.progress_title.configure(text="Error")
        self.progress_label.configure(text=error, text_color="#f87171")
    
    def on_close(self):
        try:
            with open(self.control_path, "w") as f:
                json.dump({"command": "cancel"}, f)
        except:
            pass
        self.destroy()


def main():
    if len(sys.argv) < 4:
        sys.exit(1)
    try:
        with open(sys.argv[1], "r", encoding="utf-8") as f:
            config = json.load(f)
    except:
        config = {}
    
    app = AutoCaptionsGUI(config, sys.argv[2], sys.argv[3])
    app.mainloop()


if __name__ == "__main__":
    main()
