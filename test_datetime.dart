import 'package:nookly/domain/entities/message.dart';
import 'package:nookly/core/utils/logger.dart';

void main() {
  final json = {
    'id': '6838884dfa5855ded91f9a5d',
    'content': 'Check now',
    'sender': '682c36852ec4900d61b36dee',
    'receiver': '682c36ed2ec4900d61b36dfb',
    'type': 'text',
    'status': 'read',
    'createdAt': '2025-05-29T16:16:13.340Z',
    'updatedAt': '2025-05-29T19:23:35.674Z',
    'metadata': {
      'isDisappearing': false,
      'isRead': true,
      'deliveredAt': '2025-05-29T19:23:30.691Z',
      'readAt': '2025-05-29T19:23:35.673Z'
    }
  };

  AppLogger.info('Message Details:');
  AppLogger.info('ID: ${json['id']}');
  AppLogger.info('Content: ${json['content']}');
  AppLogger.info('Status: ${json['status']}');
  AppLogger.info('\nParsing message using Message.fromJson:');
  
  final message = Message.fromJson(json);

  // Extract nested timestamps from metadata per new structure
  final deliveredAtStr = message.metadata?.deliveredAt;
  final readAtStr = message.metadata?.readAt;
  final deliveredAt = deliveredAtStr != null ? DateTime.tryParse(deliveredAtStr) : null;
  final readAt = readAtStr != null ? DateTime.tryParse(readAtStr) : null;

  AppLogger.info('\nParsed Message Details:');
  AppLogger.info('ID: ${message.id}');
  AppLogger.info('Content: ${message.content}');
  AppLogger.info('Status: ${message.status}');
  AppLogger.info('Created At: ${message.timestamp} (UTC: ${message.timestamp.isUtc})');
  AppLogger.info('Delivered At: $deliveredAt (UTC: ${deliveredAt?.isUtc})');
  AppLogger.info('Read At: $readAt (UTC: ${readAt?.isUtc})');

  if (deliveredAt != null && readAt != null) {
    AppLogger.info('\nTime Differences:');
    AppLogger.info('Time to deliver: ${deliveredAt.difference(message.timestamp).inSeconds} seconds');
    AppLogger.info('Time to read: ${readAt.difference(deliveredAt).inSeconds} seconds');
    AppLogger.info('Total time from creation to read: ${readAt.difference(message.timestamp).inSeconds} seconds');
  }
} 