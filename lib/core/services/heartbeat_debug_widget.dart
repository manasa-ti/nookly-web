import 'package:flutter/material.dart';
import 'package:nookly/core/di/injection_container.dart';
import 'package:nookly/core/services/heartbeat_service.dart';

/// Debug widget to monitor heartbeat status
/// This can be temporarily added to any page for testing
class HeartbeatDebugWidget extends StatefulWidget {
  const HeartbeatDebugWidget({super.key});

  @override
  State<HeartbeatDebugWidget> createState() => _HeartbeatDebugWidgetState();
}

class _HeartbeatDebugWidgetState extends State<HeartbeatDebugWidget> {
  late HeartbeatService _heartbeatService;
  Map<String, dynamic> _status = {};

  @override
  void initState() {
    super.initState();
    _heartbeatService = sl<HeartbeatService>();
    _updateStatus();
    
    // Update status every 5 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        _updateStatus();
      }
      return mounted;
    });
  }

  void _updateStatus() {
    setState(() {
      _status = _heartbeatService.getHeartbeatStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💓 Heartbeat Debug',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ..._status.entries.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    '${entry.key}:',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
                Text(
                  entry.value.toString(),
                  style: TextStyle(
                    color: entry.value == true ? Colors.green : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  _heartbeatService.startHeartbeat();
                  _updateStatus();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(60, 30),
                ),
                child: const Text(
                  'Start',
                  style: TextStyle(fontSize: 10),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  _heartbeatService.stopHeartbeat();
                  _updateStatus();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(60, 30),
                ),
                child: const Text(
                  'Stop',
                  style: TextStyle(fontSize: 10),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _updateStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(60, 30),
                ),
                child: const Text(
                  'Refresh',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
