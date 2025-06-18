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
  final bool isRead;
  final Map<String, String>? metadata;
  final String status; // sent, delivered, read
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final bool isDisappearing; // Whether the message should disappear
  final int? disappearingTime; // Time in seconds before message disappears
  final bool isExpired;
  final DateTime? urlExpirationTime; // Add this field

  const Message({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.content,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.metadata,
    this.status = 'sent',
    this.deliveredAt,
    this.readAt,
    this.isDisappearing = false,
    this.disappearingTime,
    this.isExpired = false,
    this.urlExpirationTime, // Add this parameter
  });

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
        isDisappearing,
        disappearingTime,
        isExpired,
        urlExpirationTime, // Add to props
      ];

  Message copyWith({
    String? id,
    String? sender,
    String? receiver,
    String? content,
    DateTime? timestamp,
    MessageType? type,
    bool? isRead,
    Map<String, String>? metadata,
    String? status,
    DateTime? deliveredAt,
    DateTime? readAt,
    bool? isDisappearing,
    int? disappearingTime,
    bool? isExpired,
    DateTime? urlExpirationTime, // Add to copyWith
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
      isDisappearing: isDisappearing ?? this.isDisappearing,
      disappearingTime: disappearingTime ?? this.disappearingTime,
      isExpired: isExpired ?? this.isExpired,
      urlExpirationTime: urlExpirationTime ?? this.urlExpirationTime, // Add to copyWith
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] as String? ?? json['id'] as String? ?? '';
    final sender = json['sender'] as String? ?? json['from'] as String? ?? '';
    final receiver = json['receiver'] as String? ?? json['to'] as String? ?? '';
    
    DateTime timestamp;
    try {
      timestamp = DateTime.parse(json['createdAt'] as String);
    } catch (e) {
      timestamp = DateTime.now();
    }

    MessageType messageType;
    try {
      final typeStr = json['messageType'] as String? ?? 'text';
      messageType = MessageType.values.firstWhere(
        (type) => type.toString().split('.').last == typeStr,
        orElse: () => MessageType.text,
      );
    } catch (e) {
      messageType = MessageType.text;
    }

    String status = 'sent';
    try {
      status = json['status'] as String? ?? 'sent';
    } catch (e) {
      status = 'sent';
    }

    DateTime? deliveredAt;
    try {
      if (json['deliveredAt'] != null) {
        deliveredAt = DateTime.parse(json['deliveredAt'] as String);
      }
    } catch (e) {
      print('Error parsing deliveredAt: $e');
    }

    DateTime? readAt;
    try {
      if (json['readAt'] != null) {
        readAt = DateTime.parse(json['readAt'] as String);
      }
    } catch (e) {
      print('Error parsing readAt: $e');
    }

    int? disappearingTime;
    try {
      if (json['disappearingTime'] != null) {
        disappearingTime = json['disappearingTime'] as int;
      }
    } catch (e) {
      print('Error parsing disappearingTime: $e');
    }

    // Parse URL expiration time
    DateTime? urlExpirationTime;
    try {
      if (json['urlExpirationTime'] != null) {
        urlExpirationTime = DateTime.parse(json['urlExpirationTime']);
      }
    } catch (e) {
      print('Error parsing urlExpirationTime: $e');
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
        if (json['isDisappearing'] != null) 'isDisappearing': json['isDisappearing'].toString(),
        if (json['updatedAt'] != null) 'updatedAt': json['updatedAt'].toString(),
      },
      status: status,
      deliveredAt: deliveredAt,
      readAt: readAt,
      isDisappearing: json['isDisappearing'] as bool? ?? false,
      disappearingTime: disappearingTime,
      isExpired: false,
      urlExpirationTime: urlExpirationTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'sender': sender,
      'receiver': receiver,
      'content': content,
      'createdAt': timestamp.toIso8601String(),
      'messageType': type == MessageType.image ? 'image' : 'text',
      'isRead': isRead,
      'metadata': metadata,
      'status': status,
      'deliveredAt': deliveredAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'isDisappearing': isDisappearing,
      'disappearingTime': disappearingTime,
      'isExpired': isExpired,
      'urlExpirationTime': urlExpirationTime?.toIso8601String(),
    };
  }

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
        other.readAt == readAt &&
        other.isDisappearing == isDisappearing &&
        other.disappearingTime == disappearingTime &&
        other.isExpired == isExpired &&
        other.urlExpirationTime == urlExpirationTime;
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
        isDisappearing,
        disappearingTime,
        isExpired,
        urlExpirationTime,
      );
} 