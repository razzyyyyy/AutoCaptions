#!/usr/bin/env python3
"""
Whisper Transcription Script
Called by AutoCaptions Lua script to transcribe audio files.
Outputs JSON with timestamps and text.
"""

import sys
import json
import os

def main():
    if len(sys.argv) < 3:
        print("Usage: python whisper_transcribe.py <audio_file> <output_json> [model] [language]")
        sys.exit(1)
    
    audio_path = sys.argv[1]
    output_path = sys.argv[2]
    model_name = sys.argv[3] if len(sys.argv) > 3 else "base"
    language = sys.argv[4] if len(sys.argv) > 4 else "auto"
    
    # Check audio file exists
    if not os.path.exists(audio_path):
        print(f"ERROR: Audio file not found: {audio_path}")
        sys.exit(1)
    
    # Import whisper
    try:
        import whisper
    except ImportError:
        print("Installing Whisper...")
        os.system("pip install openai-whisper")
        import whisper
    
    print(f"Loading Whisper model: {model_name}")
    model = whisper.load_model(model_name)
    
    print(f"Transcribing: {audio_path}")
    
    # Use word-level timestamps for better accuracy
    options = {
        "verbose": False,
        "word_timestamps": True  # Get precise word timing!
    }
    if language != "auto":
        options["language"] = language
    
    result = model.transcribe(audio_path, **options)
    
    # Format output - use WORD-level timestamps for better accuracy
    output = {
        "text": result["text"],
        "segments": []
    }
    
    # Extract word-level timestamps when available
    for seg in result["segments"]:
        if "words" in seg and seg["words"]:
            # Use individual word timestamps for precise timing
            for word_info in seg["words"]:
                word_text = word_info.get("word", "").strip()
                if word_text:
                    output["segments"].append({
                        "start": round(word_info["start"], 3),
                        "end": round(word_info["end"], 3),
                        "text": word_text
                    })
        else:
            # Fallback to segment-level
            output["segments"].append({
                "start": round(seg["start"], 3),
                "end": round(seg["end"], 3),
                "text": seg["text"].strip()
            })
    
    # Write JSON
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(output, f, indent=2, ensure_ascii=False)
    
    print(f"SUCCESS: {len(output['segments'])} segments saved to {output_path}")

if __name__ == "__main__":
    main()

