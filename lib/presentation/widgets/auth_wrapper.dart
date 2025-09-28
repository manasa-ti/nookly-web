import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/core/services/auth_handler.dart';
import 'package:nookly/core/services/heartbeat_service.dart';
import 'package:nookly/core/di/injection_container.dart';
import 'package:nookly/core/network/network_service.dart';
import 'package:nookly/presentation/bloc/auth/auth_bloc.dart';
import 'package:nookly/presentation/bloc/auth/auth_event.dart';
import 'package:nookly/presentation/bloc/auth/auth_state.dart';
import 'package:nookly/presentation/pages/auth/login_page.dart';
import 'package:nookly/core/utils/logger.dart';

class AuthWrapper extends StatefulWidget {
  final Widget child;

  const AuthWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late AuthHandler _authHandler;
  late HeartbeatService _heartbeatService;

  @override
  void initState() {
    super.initState();
    _authHandler = AuthHandler();
    _heartbeatService = sl<HeartbeatService>();
    
    // Set up the auth handler with logout callback
    _authHandler.setLogoutCallback(() {
      AppLogger.info('🔐 AuthWrapper: Logout callback triggered');
      if (mounted) {
        context.read<AuthBloc>().add(const ForceLogout(reason: 'Invalid Token'));
      }
    });
    
    // Set up the network service with auth handler
    NetworkService.setAuthHandler(_authHandler);
  }

  @override
  void dispose() {
    _authHandler.clearLogoutCallback();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Handle authentication state changes
        if (state is AuthError && state.message.contains('Invalid Token')) {
          AppLogger.warning('🔐 AuthWrapper: Invalid token detected, navigating to login');
          
          // Stop heartbeat when user is logged out
          _heartbeatService.stopHeartbeat();
          
          // Show a snackbar to inform the user
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid token. Please login again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          
          // Navigate to login screen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
            (route) => false,
          );
        } else if (state is Authenticated) {
          // Start heartbeat when user is authenticated
          AppLogger.info('💓 AuthWrapper: User authenticated, starting heartbeat');
          _heartbeatService.startHeartbeat();
        } else if (state is Unauthenticated) {
          // Stop heartbeat when user is not authenticated
          AppLogger.info('💓 AuthWrapper: User unauthenticated, stopping heartbeat');
          _heartbeatService.stopHeartbeat();
        }
      },
      child: widget.child,
    );
  }
} 