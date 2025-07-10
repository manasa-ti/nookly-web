import 'package:nookly/domain/entities/message.dart';

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

  print('Message Details:');
  print('ID: ${json['id']}');
  print('Content: ${json['content']}');
  print('Status: ${json['status']}');
  print('\nParsing message using Message.fromJson:');
  
  final message = Message.fromJson(json);
  
  print('\nParsed Message Details:');
  print('ID: ${message.id}');
  print('Content: ${message.content}');
  print('Status: ${message.status}');
  print('Created At: ${message.timestamp} (UTC: ${message.timestamp.isUtc})');
  print('Delivered At: ${message.deliveredAt} (UTC: ${message.deliveredAt?.isUtc})');
  print('Read At: ${message.readAt} (UTC: ${message.readAt?.isUtc})');

  if (message.deliveredAt != null && message.readAt != null) {
    print('\nTime Differences:');
    print('Time to deliver: ${message.deliveredAt!.difference(message.timestamp).inSeconds} seconds');
    print('Time to read: ${message.readAt!.difference(message.deliveredAt!).inSeconds} seconds');
    print('Total time from creation to read: ${message.readAt!.difference(message.timestamp).inSeconds} seconds');
  }
} 