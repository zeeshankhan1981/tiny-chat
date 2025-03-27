# Tiny Llama Chat App

An iOS app that runs Tiny Llama 1.1B Chat model locally on your device for text-based conversations.

## Features

- Local AI Chat using Tiny Llama 1.1B Chat model
- All processing runs entirely on-device without internet connection
- Optimized for mobile performance
- Maintains chat history
- Modern, intuitive UI with improved message display
- Enhanced app icon set for all device sizes

## UI Improvements

- Redesigned chat interface with better message layout
- Optimized message bubbles for better readability
- Improved app icon set for all device sizes
- Enhanced visual feedback during model loading

## Model

### Tiny Llama 1.1B Chat
- Model: `tinyllama-1.1b-chat-v1.0-q2_k.gguf`
- Quantization: 2-bit (q2_k)
- Size: ~410MB
- Optimized for mobile devices
- Chat-specific fine-tuning

## Model Configuration

### Tiny Llama
- Context window: 2048 tokens
- Quantization: 2-bit (q2_k)
- Default parameters:
  - Temperature: 0.7
  - Top_p: 0.95
  - Top_k: 40

## Usage

1. Chat Mode:
   - Uses Tiny Llama for text-based conversations
   - Supports multi-turn conversations
   - Maintains chat history

## Technical Details

### Model Storage
- Model is stored in the `Resources` folder
- Tiny Llama: `Resources/tinyllama-1.1b-chat-v1.0-q2_k.gguf`

### Memory Management
- Model is loaded/unloaded as needed

### Performance Optimizations
- Quantized model for mobile
- Real-time progress updates

## Installation

1. Clone the repository:
```bash
git clone [repository-url]
```

2. Open the project in Xcode:
```bash
open PocketGPT.xcodeproj
```

3. Select your iPhone as the build target

4. Build and run the app

## Model Download

The model can be downloaded using the provided script:

```bash
./download_models.sh
```

The script will download the Tiny Llama model and place it in the correct location.

## Troubleshooting

### Common Issues

1. **Model Not Loading**
   - Verify model file permissions
   - Check storage space
   - Ensure correct model format

2. **Memory Issues**
   - Close other apps
   - Verify device has minimum 4GB RAM
   - Check storage space

3. **Performance Issues**
   - Ensure device is not overheating
   - Verify iOS version is 16.2 or later
   - Check for background processes

## Performance Benchmarks

- Model loading time: ~30 seconds
- Response generation: ~1-2 seconds per response
- Memory usage: ~1.5GB during active chat
- UI response time: < 100ms for user interactions

## Security

- All processing runs locally on device
- No data is transmitted to external servers
- Model and chat history are stored securely on device
- No internet connection required for operation

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Requirements

- iOS 16.2 or later
- iPhone with sufficient storage
- Minimum 4GB RAM recommended

## Building the Project

1. Open `PocketGPT.xcodeproj` in Xcode
2. Select your iPhone as the build target
3. Build and run the app

The app will automatically load the Tiny Llama model from the Resources folder.
