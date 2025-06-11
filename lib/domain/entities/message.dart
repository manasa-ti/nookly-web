import 'package:equatable/equatable.dart';

enum MessageType {
  text,
  image,
  voice,
  file,
  // Add other types if your API supports them directly by string name
}

class Message extends Equatable {
  final String id;
  final String sender;
  final String receiver;
  final String content;
  final DateTime timestamp; // Corresponds to API's createdAt
  final MessageType type;
  final bool? isRead; // Optional, from API's read status
  final Map<String, dynamic>? metadata; // For additional info like fileURL, duration for voice etc.
  final String status; // sent, delivered, read
  final DateTime? deliveredAt;
  final DateTime? readAt;
  // final bool? isDisappearing; // Optional
  // final String? disappearingTime; // Optional

  const Message({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    this.isRead,
    this.metadata,
    this.status = 'sent',
    this.deliveredAt,
    this.readAt,
    // this.isDisappearing,
    // this.disappearingTime,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    print('Parsing message JSON: $json');
    
    // Generate a temporary ID if not provided
    final id = json['_id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    // Get sender and receiver from the API
    final sender = json['sender'] as String?;
    if (sender == null || sender.isEmpty) {
      print('Warning: Missing sender in message: $json');
      throw Exception('Missing sender in message: ' + json.toString());
    }

    final receiver = json['receiver'] as String?;
    if (receiver == null || receiver.isEmpty) {
      print('Warning: Missing receiver in message: $json');
      throw Exception('Missing receiver in message: ' + json.toString());
    }

    // Get timestamp from createdAt or timestamp field
    DateTime timestamp;
    try {
      final timestampStr = json['createdAt'] as String? ?? json['timestamp'] as String?;
      if (timestampStr != null) {
        // Parse the ISO 8601 timestamp
        timestamp = DateTime.parse(timestampStr).toLocal();
        print('Parsed timestamp: $timestamp (local time)');
      } else {
        timestamp = DateTime.now();
        print('No timestamp provided, using current time: $timestamp');
      }
    } catch (e) {
      print('Error parsing timestamp: $e');
      timestamp = DateTime.now();
    }

    // Get message type
    MessageType messageType;
    try {
      final typeString = json['messageType'] as String? ?? 'text';
      messageType = MessageType.values.firstWhere(
        (e) => e.name.toLowerCase() == typeString.toLowerCase(),
        orElse: () => MessageType.text,
      );
    } catch (e) {
      messageType = MessageType.text;
    }

    // Parse timestamps
    DateTime? deliveredAt;
    DateTime? readAt;
    if (json['metadata'] != null) {
      final metadata = json['metadata'] as Map<String, dynamic>;
      if (metadata['deliveredAt'] != null) {
        try {
          deliveredAt = DateTime.parse(metadata['deliveredAt'] as String).toLocal();
          print('Parsed deliveredAt: $deliveredAt (local time)');
        } catch (e) {
          print('Error parsing deliveredAt: $e');
        }
      }
      
      if (metadata['readAt'] != null) {
        try {
          readAt = DateTime.parse(metadata['readAt'] as String).toLocal();
          print('Parsed readAt: $readAt (local time)');
        } catch (e) {
          print('Error parsing readAt: $e');
        }
      }
    }

    print('Message timestamps - deliveredAt: $deliveredAt, readAt: $readAt');

    // Determine status based on timestamps
    String status = 'sent';
    if (readAt != null) {
      status = 'read';
    } else if (deliveredAt != null) {
      status = 'delivered';
    } else if (json['status'] != null) {
      status = json['status'] as String;
    }

    return Message(
      id: id,
      sender: sender,
      receiver: receiver,
      content: json['content'] as String? ?? '',
      timestamp: timestamp,
      type: messageType,
      isRead: json['isRead'] as bool? ?? false,
      metadata: {
        if (json['isDisappearing'] != null) 'isDisappearing': json['isDisappearing'],
        if (json['updatedAt'] != null) 'updatedAt': json['updatedAt'],
      },
      status: status,
      deliveredAt: deliveredAt,
      readAt: readAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'sender': sender,
      'receiver': receiver,
      'content': content,
      'createdAt': timestamp.toIso8601String(),
      'messageType': type.name, // Use .name for enum to string
      'isRead': isRead,
      'metadata': metadata,
      'status': status,
      'deliveredAt': deliveredAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      // 'isDisappearing': isDisappearing,
      // 'disappearingTime': disappearingTime,
    };
  }

  Message copyWith({
    String? id,
    String? sender,
    String? receiver,
    String? content,
    DateTime? timestamp,
    MessageType? type,
    bool? isRead,
    Map<String, dynamic>? metadata,
    String? status,
    DateTime? deliveredAt,
    DateTime? readAt,
  }) {
    return Message(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sender,
        receiver,
        content,
        timestamp,
        type,
        isRead,
        metadata,
        status,
        deliveredAt,
        readAt,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message &&
        other.id == id &&
        other.sender == sender &&
        other.receiver == receiver &&
        other.content == content &&
        other.timestamp == timestamp &&
        other.type == type &&
        other.isRead == isRead &&
        other.status == status &&
        other.deliveredAt == deliveredAt &&
        other.readAt == readAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        sender,
        receiver,
        content,
        timestamp,
        type,
        isRead,
        status,
        deliveredAt,
        readAt,
      );
} 