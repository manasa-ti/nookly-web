import 'package:flutter/material.dart';
import 'package:nookly/core/config/app_config.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontFamily: 'Nunito',
            fontSize: (size.width * 0.04).clamp(13.0, 16.0),
            color: Colors.black,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppConfig.defaultPadding),
        itemCount: 10,
        itemBuilder: (context, index) {
          return _NotificationItem(
            title: 'New Match',
            message: 'You have a new match with Sarah!',
            time: '2 hours ago',
            icon: Icons.favorite,
            onTap: () {
              // TODO: Navigate to match details
            },
          );
        },
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontFamily: 'Nunito',
            fontSize: (size.width * 0.04).clamp(13.0, 16.0),
            color: Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            Text(
              time,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: (size.width * 0.03).clamp(10.0, 13.0),
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
} 