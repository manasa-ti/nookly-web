// Web-specific implementation helper for voice recording
// This file is only used for web compilation
import 'dart:async';
import 'dart:js' as js;

/// Web-specific MediaRecorder wrapper
/// Uses JavaScript interop for MediaRecorder API
class WebMediaRecorderWrapper {
  js.JsObject? _mediaRecorder;
  js.JsObject? _mediaStream;
  List<dynamic> _audioChunks = [];
  String? _blobUrl;
  Completer<String>? _stopCompleter;
  
  Future<void> startRecording() async {
    try {
      // Request microphone access using JavaScript interop
      final navigator = js.context['navigator'];
      final mediaDevices = navigator['mediaDevices'];
      
      final constraints = js.JsObject.jsify({
        'audio': {
          'sampleRate': 44100,
          'channelCount': 1,
          'echoCancellation': true,
          'noiseSuppression': true,
        }
      });
      
      final streamPromise = mediaDevices.callMethod('getUserMedia', [constraints]);
      _mediaStream = await _promiseToJsObject(streamPromise);
      
      // Try to find a supported MIME type (iOS Safari prefers audio/mp4 or audio/aac)
      final supportedTypes = [
        'audio/mp4',           // iOS Safari compatible
        'audio/aac',           // iOS Safari compatible  
        'audio/webm;codecs=opus',
        'audio/webm',
        'audio/ogg;codecs=opus',
      ];
      
      String? selectedMimeType;
      final MediaRecorder = js.context['MediaRecorder'];
      for (final mimeType in supportedTypes) {
        if (MediaRecorder.callMethod('isTypeSupported', [mimeType]) as bool) {
          selectedMimeType = mimeType;
          break;
        }
      }
      
      // Create MediaRecorder using JavaScript
      final options = selectedMimeType != null 
          ? js.JsObject.jsify({'mimeType': selectedMimeType})
          : null;
      
      _mediaRecorder = js.JsObject(
        js.context['MediaRecorder'],
        options != null ? [_mediaStream, options] : [_mediaStream],
      );
      _audioChunks = [];
      _stopCompleter = null;
      
      // Set up data handler (JavaScript function)
      _mediaRecorder!['ondataavailable'] = (dynamic event) {
        // Event is a BlobEvent from JavaScript, access it as JsObject
        try {
          final eventObj = event as js.JsObject;
          final data = eventObj['data'];
          if (data != null) {
            // Data is a JavaScript Blob object
            final dataObj = data as js.JsObject;
            final size = dataObj['size'];
            if (size != null && (size as int) > 0) {
              // Store the JavaScript Blob object directly (not wrapped)
              _audioChunks.add(dataObj);
            }
          }
        } catch (e) {
          // If casting fails, try accessing properties directly
          // This handles cases where event might be a different type
        }
      };
      
      // Set up stop handler (JavaScript function)
      _mediaRecorder!['onstop'] = (dynamic event) {
        try {
          // Create blob from chunks using JavaScript
          // _audioChunks contains JavaScript Blob objects from ondataavailable
          final Blob = js.context['Blob'];
          
          // Create a JavaScript array from the chunks
          // Create empty JavaScript array using jsify
          final jsArray = js.JsObject.jsify([]) as js.JsObject;
          
          // Add chunks to the array using push
          for (var chunk in _audioChunks) {
            if (chunk != null) {
              jsArray.callMethod('push', [chunk]);
            }
          }
          
          // Create blob with the array of chunks
          final blob = js.JsObject(Blob, [jsArray]);
          
          // Create object URL
          final URL = js.context['URL'];
          _blobUrl = URL.callMethod('createObjectURL', [blob]) as String;
          
          if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
            _stopCompleter!.complete(_blobUrl!);
          }
        } catch (e) {
          if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
            _stopCompleter!.completeError(e);
          }
        }
      };
      
      // Start recording
      _mediaRecorder!.callMethod('start');
    } catch (e) {
      // Cleanup on error
      dispose();
      rethrow;
    }
  }
  
  Future<String> stopRecording() async {
    if (_mediaRecorder == null) {
      throw StateError('MediaRecorder not started');
    }
    
    _stopCompleter = Completer<String>();
    
    // Stop MediaRecorder (will trigger onstop event)
    _mediaRecorder!.callMethod('stop');
    
    // Stop all tracks in the stream
    final tracks = _mediaStream!.callMethod('getTracks', []);
    final length = tracks['length'] as int;
    for (var i = 0; i < length; i++) {
      final track = tracks[i] as js.JsObject;
      track.callMethod('stop');
    }
    
    return _stopCompleter!.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        throw TimeoutException('Recording stop timed out');
      },
    );
  }
  
  Future<js.JsObject> _promiseToJsObject(js.JsObject promise) async {
    final completer = Completer<js.JsObject>();
    promise.callMethod('then', [
      (result) {
        completer.complete(result as js.JsObject);
      },
      (error) {
        completer.completeError(error);
      }
    ]);
    return completer.future;
  }
  
  void dispose() {
    // Cancel any pending completers
    if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
      _stopCompleter!.completeError(StateError('Recording disposed'));
    }
    _stopCompleter = null;
    
    // Revoke object URL
    if (_blobUrl != null) {
      final URL = js.context['URL'];
      URL.callMethod('revokeObjectURL', [_blobUrl]);
      _blobUrl = null;
    }
    
    // Stop tracks
    if (_mediaStream != null) {
      try {
        final tracks = _mediaStream!.callMethod('getTracks', []);
        final length = tracks['length'] as int;
        for (var i = 0; i < length; i++) {
          try {
            final track = tracks[i] as js.JsObject;
            track.callMethod('stop');
          } catch (e) {
            // Track might already be stopped, ignore
          }
        }
      } catch (e) {
        // Stream might already be disposed, ignore
      }
      _mediaStream = null;
    }
    
    _mediaRecorder = null;
    _audioChunks.clear();
  }
}
