# Voice Transcription Setup

Open Yapper uses Google's Gemini API to transcribe voice recordings to text. This guide explains how to configure and use the feature.

## Obtaining a Gemini API Key

1. Go to [Google AI Studio](https://aistudio.google.com/apikey)
2. Sign in with your Google account
3. Click **Create API key**
4. Copy the generated key

## Configuring the API Key in the App

1. Open the **Customization** screen (tune icon in the sidebar)
2. Scroll to the **API** section
3. Paste your Gemini API key into the text field
4. Click **Save**

The key is stored locally on your device. Transcription will work for new recordings after the key is saved.

## Supported Audio Format

Recordings are saved as `.m4a` (AAC) files, which the Gemini API supports via the `audio/mp4` MIME type. No conversion is required.

## Privacy

Audio files are sent to Google's servers for transcription. Do not use this feature for sensitive or confidential content unless you are comfortable with Google processing it. Review [Google's AI terms of service](https://ai.google.dev/terms) for details.

## Troubleshooting

### No transcription appears

- **API key not set**: Ensure you have entered and saved your Gemini API key in the Customization screen
- **Network error**: Check your internet connection; the app must reach `generativelanguage.googleapis.com`
- **Invalid key**: Verify the key is correct and has not been revoked in Google AI Studio

### "No transcription" in History

For older recordings created before transcription was enabled, or if transcription failed, the History screen will show "No transcription". New recordings should transcribe automatically when the API key is configured.

### Transcription takes a long time

Transcription runs asynchronously after you stop recording. For longer recordings, it may take several seconds. The Home screen shows "Transcribing..." until the result is ready.
