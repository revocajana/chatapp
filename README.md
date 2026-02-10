# ChatApp

A simple chat application built with **Flutter** and **Firebase** for learning purposes.

## Overview

ChatApp is a basic chat application designed to learn Flutter development with Firebase backend services.

## Features

1. **Authentication** - User signup and login with Firebase Authentication
2. **See Other Users** - View list of all registered users
3. **Send and Receive Messages** - Real-time messaging between users using Cloud Firestore
4. **Get Notifications** - Receive push notifications for new messages using Firebase Cloud Messaging

## Technology Stack

- **Flutter**: Cross-platform development
- **Dart**: Programming language
- **Firebase Authentication**: User login/signup
- **Cloud Firestore**: Store messages and user data
- **Firebase Cloud Messaging (FCM)**: Push notifications

## Quick Start

### 1. Setup Firebase
- Create a project at [firebase.google.com](https://firebase.google.com)
- Enable Firebase Authentication (Email/Password)
- Create a Cloud Firestore database
- Enable Cloud Messaging

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart
├── screens/
├── services/
└── models/
```

## Learning Notes

This is a learning project to understand:
- Firebase authentication with Flutter
- Real-time database operations with Firestore
- Push notifications with Firebase Cloud Messaging
- State management in Flutter