# HushMate Dating App - Features Documentation

## Overview
HushMate is a comprehensive dating application built with Flutter that provides users with a complete dating experience including profile management, matching, messaging, voice/video calls, and premium features.

## Core Features

### 1. Authentication & User Management

#### 1.1 User Registration
- **Email-based registration** with password validation
- **Email format validation** and duplicate email checking
- **Password strength requirements** (minimum 6 characters)
- **Automatic profile creation flow** after successful registration

#### 1.2 User Login
- **Email and password authentication**
- **Remember me functionality** with token-based sessions
- **Automatic navigation** to profile completion or home based on profile status
- **Error handling** for invalid credentials

#### 1.3 Password Recovery
- **Forgot password functionality** with email reset
- **Secure token-based password reset** process

#### 1.4 Profile Completion
- **Multi-step profile creation** with 4 stages:
  - Basic Info (age, gender, seeking gender)
  - Location & Age preferences
  - Profile Details (bio, interests, hometown)
  - Objectives (dating goals)
- **Real-time validation** for each step
- **Profile completion status tracking**

### 2. Profile Management

#### 2.1 Profile Creation
- **Comprehensive profile setup** with multiple sections
- **Age and gender selection** with validation
- **Location-based matching** with hometown input
- **Bio and personal description** fields
- **Interest selection** from predefined categories
- **Dating objectives** selection (short-term, long-term, etc.)
- **Age range preferences** for potential matches
- **Distance radius** settings for location-based matching

#### 2.2 Profile Editing
- **Complete profile editing** capabilities
- **Profile picture upload** with image picker
- **Real-time form validation** and error handling
- **Interest and objective management** with dynamic lists
- **Age range and distance preferences** adjustment
- **Profile completion status** tracking

#### 2.3 Profile Viewing
- **Detailed profile display** with all user information
- **Profile picture display** with fallback icons
- **Interest and objective chips** visualization
- **Profile completion indicator**

### 3. Discovery & Matching

#### 3.1 Recommended Profiles
- **Algorithm-based profile recommendations**
- **Swipe-based interaction** (like/dislike)
- **Profile card display** with key information
- **Distance and age information** display
- **Common interests highlighting**
- **Profile detail modal** for comprehensive view
- **Real-time profile loading** with pagination

#### 3.2 Profile Filters
- **Advanced filtering system** with multiple criteria:
  - Age range selection
  - Distance radius adjustment
  - Interest-based filtering
  - Objective-based filtering
- **Real-time filter application**
- **Filter persistence** across sessions

#### 3.3 Received Likes
- **Like management system** for received likes
- **Accept/reject functionality** for incoming likes
- **Like history tracking**
- **Profile preview** for received likes
- **Time-based like display**

### 4. Messaging System

#### 4.1 Chat Inbox
- **Conversation list** with all active chats
- **Unread message indicators** with count
- **Last message preview** with timestamp
- **Online status indicators**
- **Real-time message updates** via WebSocket
- **Conversation sorting** by recent activity

#### 4.2 Individual Chat
- **Real-time messaging** with WebSocket integration
- **Message types support**:
  - Text messages
  - Image messages
  - Voice messages
  - File attachments
- **Message status tracking** (sent, delivered, read)
- **Typing indicators**
- **Message timestamps**
- **Message pagination** for history loading

#### 4.3 Disappearing Messages
- **Configurable disappearing time** for messages
- **Image expiration** with time-based deletion
- **Automatic message cleanup**
- **Expiration notifications**

#### 4.4 Message Features
- **Image sharing** with upload functionality
- **Voice message recording** and playback
- **File attachment support**
- **Message editing** capabilities
- **Message deletion** functionality
- **Read receipts** tracking

### 5. Voice & Video Calling

#### 5.1 Call Service
- **Agora RTC integration** for high-quality calls
- **Audio and video call support**
- **Permission handling** for microphone and camera
- **Call controls** (mute, speaker, camera toggle)
- **Call quality management**

#### 5.2 Call Interface
- **Dedicated call screen** with full controls
- **Video call layout** with local and remote video
- **Audio call interface** with participant info
- **Call duration tracking**
- **Call end functionality**

### 6. Premium Features

#### 6.1 Subscription Management
- **Multiple subscription tiers**:
  - Monthly ($9.99)
  - 6 Months ($49.99) - 17% savings
  - Yearly ($89.99) - 25% savings
- **Feature activation** based on subscription
- **Premium feature display** with status indicators

#### 6.2 Premium Features
- **See Who Likes You** - View likes before matching
- **Unlimited Likes** - No daily limit on likes
- **Advanced Filters** - Enhanced filtering options
- **Read Receipts** - See when messages are read
- **Priority Likes** - Enhanced visibility

### 7. User Safety & Moderation

#### 7.1 Report System
- **User reporting functionality** with multiple reasons
- **Report reason selection** from predefined categories
- **Detailed report submission** with additional context
- **Report status tracking**
- **Moderation workflow** integration

#### 7.2 Privacy Features
- **Profile visibility controls**
- **Message privacy settings**
- **Location privacy** options
- **Block user functionality**

### 8. Settings & Preferences

#### 8.1 Account Settings
- **Profile editing** access
- **Notification preferences**
- **Privacy settings**
- **Account logout** functionality

#### 8.2 Notification Management
- **Push notification** support
- **Notification history** display
- **Notification preferences** configuration
- **Real-time notification** delivery

### 9. Technical Features

#### 9.1 State Management
- **BLoC pattern** implementation for state management
- **Repository pattern** for data access
- **Dependency injection** with GetIt
- **Event-driven architecture**

#### 9.2 Network Layer
- **REST API integration** with Dio HTTP client
- **WebSocket integration** for real-time features
- **Token-based authentication**
- **Error handling** and retry mechanisms

#### 9.3 Data Persistence
- **SharedPreferences** for local storage
- **Secure token storage**
- **User session management**
- **Offline capability** for basic features

#### 9.4 UI/UX Features
- **Material Design 3** implementation
- **Responsive design** for different screen sizes
- **Loading states** and error handling
- **Smooth animations** and transitions
- **Accessibility support**

### 10. Security Features

#### 10.1 Authentication Security
- **JWT token-based authentication**
- **Secure token storage**
- **Session management**
- **Automatic token refresh**

#### 10.2 Data Security
- **Encrypted data transmission**
- **Secure API communication**
- **User data protection**
- **Privacy compliance**

## Architecture Overview

### Frontend Architecture
- **Flutter framework** with Dart programming language
- **Clean Architecture** with separation of concerns
- **BLoC pattern** for state management
- **Repository pattern** for data access
- **Dependency injection** for loose coupling

### Backend Integration
- **RESTful API** for data operations
- **WebSocket** for real-time communication
- **Agora RTC** for voice/video calls
- **Token-based authentication**

### Data Models
- **User entity** with comprehensive profile data
- **Message entity** with multiple types and status
- **Conversation entity** for chat management
- **Matching entities** for discovery features

## Dependencies & Technologies

### Core Dependencies
- **flutter_bloc**: State management
- **dio**: HTTP client for API calls
- **socket_io_client**: Real-time communication
- **agora_rtc_engine**: Voice/video calling
- **get_it**: Dependency injection
- **shared_preferences**: Local storage
- **image_picker**: Image selection
- **permission_handler**: Device permissions

### UI Dependencies
- **flutter_svg**: SVG image support
- **cached_network_image**: Image caching
- **shimmer**: Loading animations
- **flutter_card_swiper**: Profile card swiping
- **just_audio**: Audio playback

### Development Dependencies
- **mockito**: Testing framework
- **bloc_test**: BLoC testing
- **build_runner**: Code generation
- **injectable_generator**: DI code generation

## Platform Support
- **Android** (API level 21+)
- **iOS** (iOS 12.0+)
- **Web** (Flutter web)
- **Desktop** (Windows, macOS, Linux)

This documentation provides a comprehensive overview of all features implemented in the HushMate dating application. Each feature is designed to provide a complete and engaging dating experience while maintaining security, privacy, and user safety standards. 