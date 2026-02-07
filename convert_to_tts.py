
"""
This script converts an MP3 or MP4 file to a text-to-speech (TTS) file.

It performs the following steps:
1. Extracts audio from the input file (if it's an MP4).
2. Transcribes the audio to text using a speech-to-text (STT) service.
3. Converts the transcribed text to speech using a text-to-speech (TTS) service.

Requirements:
- Python 3.7+
- moviepy: for extracting audio from video files.
- google-generativeai: for speech-to-text.
- gtts: for text-to-speech.

Installation:
pip install moviepy google-generativeai gtts

You also need to have a Google API key with access to Gemini API set as an environment variable:
export GEMINI_API_KEY='your-api-key'
"""

import argparse
import os
from pathlib import Path
from moviepy.editor import VideoFileClip
import google.generativeai as genai
from gtts import gTTS

def extract_audio(file_path: Path) -> Path:
    """
    Extracts audio from a video file and saves it as a temporary MP3 file.
    If the input is already an audio file, it returns the same path.
    """
    if file_path.suffix.lower() == ".mp4":
        print(f"Extracting audio from {file_path}...")
        video = VideoFileClip(str(file_path))
        audio_path = file_path.with_suffix(".mp3")
        video.audio.write_audiofile(str(audio_path))
        print(f"Audio extracted to {audio_path}")
        return audio_path
    elif file_path.suffix.lower() == ".mp3":
        return file_path
    else:
        raise ValueError("Unsupported file format. Please provide an MP3 or MP4 file.")

def transcribe_audio(audio_path: Path) -> str:
    """
    Transcribes the given audio file to text using Google's Gemini model.
    """
    print(f"Transcribing {audio_path} with Gemini...")

    # Configure the Gemini API key
    gemini_api_key = os.environ.get("GEMINI_API_KEY")
    if not gemini_api_key:
        raise ValueError("GEMINI_API_KEY environment variable not set.")
    genai.configure(api_key=gemini_api_key)

    # Upload the audio file
    print("Uploading audio file...")
    audio_file = genai.upload_file(path=str(audio_path))
    print(f"Uploaded file '{audio_file.display_name}' as: {audio_file.uri}")

    # Create the Gemini model
    model = genai.GenerativeModel(model_name="gemini-1.5-flash")

    # Transcribe the audio
    print("Transcribing...")
    response = model.generate_content(["Please transcribe this audio.", audio_file])

    # Clean up the uploaded file
    print(f"Deleting uploaded file: {audio_file.uri}")
    genai.delete_file(audio_file.name)

    print("Transcription successful.")
    return response.text

def convert_text_to_speech(text: str, output_path: Path, lang: str = 'en'):

    """
    Converts the given text to speech and saves it as an MP3 file.
    """
    print(f"Converting text to speech and saving to {output_path}...")
    tts = gTTS(text=text, lang=lang)
    tts.save(str(output_path))
    print("TTS conversion successful.")

def main():
    parser = argparse.ArgumentParser(description="Convert an MP3 or MP4 file to a TTS file.")
    parser.add_argument("input_file", type=str, help="Path to the input MP3 or MP4 file.")
    parser.add_argument("output_file", type=str, help="Path to the output TTS file (e.g., output.mp3).")
    parser.add_argument("--lang", type=str, default="en", help="Language for the TTS output (e.g., 'en', 'zh-cn').")
    args = parser.parse_args()

    input_path = Path(args.input_file)
    output_path = Path(args.output_file)

    if not input_path.exists():
        print(f"Error: Input file not found at {input_path}")
        return

    try:
        # Step 1: Extract audio
        audio_path = extract_audio(input_path)

        # Step 2: Transcribe audio
        transcribed_text = transcribe_audio(audio_path)
        print("\nTranscribed Text:")
        print(transcribed_text)

        # Step 3: Convert text to speech
        convert_text_to_speech(transcribed_text, output_path, args.lang)

        # Clean up temporary audio file if created from MP4
        if input_path.suffix.lower() == ".mp4":
            os.remove(audio_path)

    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    main()
