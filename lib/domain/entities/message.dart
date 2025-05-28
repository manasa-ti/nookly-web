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

    // Get timestamp from createdAt
    final timestamp = json['createdAt'] != null 
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now();

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
      status: json['status'] as String? ?? 'sent',
      deliveredAt: json['deliveredAt'] != null ? DateTime.parse(json['deliveredAt']) : null,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      // metadata can be constructed based on type if needed, e.g. for image/file URLs
      // isDisappearing: json['isDisappearing'] as bool?,
      // disappearingTime: json['disappearingTime'] as String?,
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
    // bool? isDisappearing,
    // String? disappearingTime,
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
      // isDisappearing: isDisappearing ?? this.isDisappearing,
      // disappearingTime: disappearingTime ?? this.disappearingTime,
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
        // isDisappearing,
        // disappearingTime,
      ];
} 