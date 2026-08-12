# RideNow Mobile Apps 📱

Welcome to the **RideNow Mobile Apps** repository. This repository contains the mobile application clients for the RideNow platform, built with Flutter.

## 📂 Project Structure

This repository is divided into two distinct Flutter applications:

1. **`ridezio_customer` (User App)**
   The dedicated application for end-users and customers. It allows users to browse available vehicles, book rides, view their booking history, manage their profiles, and handle location-based searches.

2. **`ridezio_admin` (Shop Admin App)**
   The dedicated application for shop owners and administrators. It enables shop admins to manage their vehicle fleet, view incoming bookings, process ride handovers and returns, upload condition verification videos, and record offline payments (Pay at Shop).

## 🚀 Getting Started

Both applications are built with [Flutter](https://flutter.dev/). Ensure you have the Flutter SDK installed on your development machine before proceeding.

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable version recommended)
- Android Studio / VS Code
- Xcode (for iOS development on macOS)

### Running the Customer App
1. Navigate to the customer app directory:
   ```bash
   cd ridezio_customer
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

### Running the Admin App
1. Navigate to the admin app directory:
   ```bash
   cd ridezio_admin
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## ⚙️ Configuration

Make sure to configure your API base URLs in the respective configuration files inside each app to connect them to your running backend (Laravel) server.

*Note: All online payment gateways (Stripe, Razorpay, Macky's Pay) have been decoupled from these apps in favor of an exclusive "Pay at Shop" (offline/UPI) flow.*
