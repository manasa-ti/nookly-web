import 'package:flutter_test/flutter_test.dart';

import 'core/network/socket_service_messaging_test.dart' as socket_service_messaging_test;
import 'core/services/location_service_simple_test.dart' as location_service_simple_test;
import 'data/repositories/conversation_repository_basic_test.dart' as conversation_repository_basic_test;
import 'presentation/bloc/recommended_profiles/recommended_profiles_business_logic_test.dart' as recommended_profiles_business_logic_test;
import 'presentation/bloc/received_likes/received_likes_business_logic_test.dart' as received_likes_business_logic_test;
import 'presentation/bloc/profile/profile_filters_business_logic_test.dart' as profile_filters_business_logic_test;
import 'presentation/bloc/profile/profile_creation_business_logic_test.dart' as profile_creation_business_logic_test;

void main() {
  group('All Business Logic Tests', () {
    // Core messaging system tests
    socket_service_messaging_test.main();
    location_service_simple_test.main();
    conversation_repository_basic_test.main();
    
    // Profile and recommendation business logic tests
    recommended_profiles_business_logic_test.main();
    received_likes_business_logic_test.main();
    profile_filters_business_logic_test.main();
    profile_creation_business_logic_test.main();
  });
}
