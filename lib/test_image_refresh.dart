import 'package:flutter/material.dart';
import 'package:hushmate/core/services/image_url_service.dart';
import 'package:hushmate/core/utils/logger.dart';

class ImageRefreshTest extends StatefulWidget {
  const ImageRefreshTest({Key? key}) : super(key: key);

  @override
  State<ImageRefreshTest> createState() => _ImageRefreshTestState();
}

class _ImageRefreshTestState extends State<ImageRefreshTest> {
  String? _testResult;
  bool _isLoading = false;

  // Test image data
  final String testImageKey = 'messages/1751612010322-04roow.jpg';
  final String testImageUrl = 'https://hushmate-bucket.s3.eu-north-1.amazonaws.com/messages/1751612010322-04roow.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAVNOKURLSTLEHNONW%2F20250704%2Feu-north-1%2Fs3%2Faws4_request&X-Amz-Date=20250704T065332Z&X-Amz-Expires=3600&X-Amz-Signature=77f7e5a4b034e95e2bc86fb26ff9785319fb736c7fe70eb00db2f4e659fc0d6e&X-Amz-SignedHeaders=host';

  Future<void> _testImageRefresh() async {
    setState(() {
      _isLoading = true;
      _testResult = null;
    });

    try {
      AppLogger.info('🔵 TESTING: Starting image refresh test');
      AppLogger.info('🔵 TESTING: Image key: $testImageKey');
      AppLogger.info('🔵 TESTING: Original URL: $testImageUrl');

      final imageUrlService = ImageUrlService();
      
      // Test the refresh API call
      final result = await imageUrlService.getValidImageUrlWithExpiration(testImageKey);
      
      AppLogger.info('🔵 TESTING: API call successful!');
      AppLogger.info('🔵 TESTING: New image URL: ${result['imageUrl']}');
      AppLogger.info('🔵 TESTING: New expiration: ${result['expiresAt']}');
      
      setState(() {
        _testResult = '''
✅ SUCCESS: Image refresh API test passed!

📋 Test Details:
- Image Key: $testImageKey
- Original URL: ${testImageUrl.substring(0, 100)}...
- New URL: ${result['imageUrl']}
- New Expiration: ${result['expiresAt']}

🔧 API Response:
${result.toString()}
''';
      });

    } catch (e) {
      AppLogger.error('❌ TESTING: Image refresh test failed: $e');
      setState(() {
        _testResult = '''
❌ FAILED: Image refresh API test failed!

📋 Test Details:
- Image Key: $testImageKey
- Error: $e

🔧 Debug Info:
- Check if backend endpoint exists: /api/messages/refresh-image-url/$testImageKey
- Verify authentication token is valid
- Check network connectivity
''';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testRetryMechanism() async {
    setState(() {
      _isLoading = true;
      _testResult = null;
    });

    try {
      AppLogger.info('🔵 TESTING: Testing retry mechanism with invalid image key');
      
      final imageUrlService = ImageUrlService();
      
      // Test with an invalid image key to trigger retry mechanism
      final invalidImageKey = 'messages/invalid-image-key.jpg';
      
      AppLogger.info('🔵 TESTING: Testing with invalid image key: $invalidImageKey');
      
      final result = await imageUrlService.getValidImageUrlWithExpiration(invalidImageKey);
      
      setState(() {
        _testResult = '''
✅ SUCCESS: Retry mechanism test completed!

📋 Test Details:
- Invalid Image Key: $invalidImageKey
- Result: ${result['imageUrl']}
- This should be a fallback URL after retries

🔧 Retry Status:
${imageUrlService.getRetryStatus(invalidImageKey)}
''';
      });

    } catch (e) {
      AppLogger.error('❌ TESTING: Retry mechanism test failed: $e');
      setState(() {
        _testResult = '''
❌ FAILED: Retry mechanism test failed!

📋 Test Details:
- Invalid Image Key: messages/invalid-image-key.jpg
- Error: $e

🔧 This might be expected if the API endpoint doesn't exist yet
''';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Refresh API Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Image Data',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Image Key: $testImageKey'),
                    const SizedBox(height: 4),
                    Text('Original URL: ${testImageUrl.substring(0, 80)}...'),
                    const SizedBox(height: 4),
                    const Text('Expected API: GET /api/messages/refresh-image-url/messages/1751612010322-04roow.jpg'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testImageRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(16),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('🧪 Test Image Refresh API', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testRetryMechanism,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.all(16),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('🔄 Test Retry Mechanism', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),
            if (_testResult != null)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Text(
                        _testResult!,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 