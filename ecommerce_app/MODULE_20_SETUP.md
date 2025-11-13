# Module 20: Setup Instructions & Firebase Configuration

## 📦 Packages to Install

### 1. Install Google Fonts Package

Run this command in your terminal (in the `ecommerce_app` directory):

```bash
flutter pub add google_fonts
```

Or if you prefer to add it manually, it's already added to `pubspec.yaml`:
```yaml
google_fonts: ^6.2.1
```

Then run:
```bash
flutter pub get
```

### 2. Verify All Dependencies

Make sure all packages are installed by running:
```bash
flutter pub get
```

## 🔥 Firebase Setup Requirements

### 1. Firestore Indexes Required

You need to create **Firestore Indexes** for the following queries. When you first run the app, Firebase will show you error messages with links to create these indexes. Click those links, or manually create them:

#### Index 1: Notifications Collection
- **Collection ID**: `notifications`
- **Fields to index**:
  - `userId` (Ascending)
  - `isRead` (Ascending)
- **Query scope**: Collection

#### Index 2: Notifications Collection (Order By)
- **Collection ID**: `notifications`
- **Fields to index**:
  - `userId` (Ascending)
  - `createdAt` (Descending)
- **Query scope**: Collection

#### Index 3: Chats Collection
- **Collection ID**: `chats`
- **Fields to index**:
  - `lastMessageAt` (Descending)
- **Query scope**: Collection

#### Index 4: Messages Subcollection
- **Collection ID**: `messages` (subcollection of `chats`)
- **Fields to index**:
  - `createdAt` (Ascending)
- **Query scope**: Collection

#### Index 5: Orders Collection (Order History)
- **Collection ID**: `orders`
- **Fields to index**:
  - `userId` (Ascending)
  - `createdAt` (Descending)
- **Query scope**: Collection

**How to Create Indexes:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Firestore Database** → **Indexes** tab
4. Click **"Create Index"** or use the link from the error message
5. Fill in the fields as specified above
6. Wait 5-10 minutes for the index to build (status will change from "Building" to "Enabled")

### 2. Firestore Security Rules

Update your Firestore Security Rules to allow the new collections. Go to **Firestore Database** → **Rules** tab and use these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user is admin
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Users collection - users can read/write their own document
    match /users/{userId} {
      allow read: if isAuthenticated() && request.auth.uid == userId;
      allow write: if isAuthenticated() && request.auth.uid == userId;
    }
    
    // Products collection - everyone can read, only admins can write
    match /products/{productId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    
    // User carts - users can read/write their own cart
    match /userCarts/{userId} {
      allow read, write: if isAuthenticated() && request.auth.uid == userId;
    }
    
    // Orders - users can read their own orders, admins can read all
    match /orders/{orderId} {
      allow read: if isAuthenticated() && 
                     (resource.data.userId == request.auth.uid || isAdmin());
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update: if isAdmin();
    }
    
    // Notifications - users can read their own notifications
    match /notifications/{notificationId} {
      allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow create: if isAdmin(); // Only admins create notifications
      allow update: if isAuthenticated() && resource.data.userId == request.auth.uid;
    }
    
    // Chats - users can read/write their own chat document
    match /chats/{chatRoomId} {
      allow read, write: if isAuthenticated() && 
                            (chatRoomId == request.auth.uid || isAdmin());
      
      // Messages subcollection
      match /messages/{messageId} {
        allow read, write: if isAuthenticated() && 
                              (chatRoomId == request.auth.uid || isAdmin());
      }
    }
  }
}
```

**Important Notes:**
- Replace the rules in your Firebase Console
- Click **"Publish"** to save the rules
- Test the rules using the **Rules Playground** in Firebase Console

### 3. Firebase Authentication

Make sure these authentication methods are enabled in Firebase Console:
- **Email/Password** (should already be enabled)

Go to: **Authentication** → **Sign-in method** → Enable **Email/Password**

## 📱 Building the Release APK

### Step 1: Clean the Build

```bash
flutter clean
```

### Step 2: Build the Release APK

```bash
flutter build apk --release
```

This will take a few minutes. When finished, you'll see a message showing where the file is located.

### Step 3: Find Your APK

Navigate to:
```
build/app/outputs/flutter-apk/app-release.apk
```

This is your installable APK file!

### Step 4: Install on Android Phone

1. Transfer the `app-release.apk` file to your Android phone (via USB, email, or cloud storage)
2. On your phone, go to **Settings** → **Security** → Enable **"Install from Unknown Sources"** (or **"Install Unknown Apps"** on newer Android versions)
3. Open the APK file on your phone and tap **"Install"**

## 🎨 Assets Required

### App Logo

Make sure you have an app logo image at:
```
assets/images/app_logo.png
```

If you don't have one yet:
1. Create or download a logo image (PNG format recommended)
2. Place it in the `assets/images/` folder
3. The logo should be transparent background for best results
4. Recommended size: 200x200 pixels or larger

## ✅ Verification Checklist

Before building the release APK, verify:

- [ ] All packages installed (`flutter pub get`)
- [ ] Firebase indexes created and enabled
- [ ] Firestore security rules updated
- [ ] App logo exists at `assets/images/app_logo.png`
- [ ] All features tested in debug mode
- [ ] No console errors when running the app

## 🐛 Common Issues & Solutions

### Issue: "Missing Firestore Index" Error
**Solution**: Click the link in the error message to create the index, or manually create it in Firebase Console.

### Issue: "Permission Denied" in Firestore
**Solution**: Check your Firestore security rules and make sure they match the rules provided above.

### Issue: App Logo Not Showing
**Solution**: 
1. Verify the file exists at `assets/images/app_logo.png`
2. Check `pubspec.yaml` has `assets/images/` in the assets section
3. Run `flutter pub get` and restart the app

### Issue: Build Fails with "Gradle Error"
**Solution**: 
1. Run `flutter clean`
2. Delete `android/.gradle` folder
3. Run `flutter pub get`
4. Try building again

## 📝 Additional Notes

- The app uses **Material 3** design system
- Custom color palette: Brown theme (coffee shop style)
- Google Fonts (Lato) is applied globally
- All screens have rounded corners and modern styling
- VAT calculation is set to 12% (Philippine standard)

## 🎉 Congratulations!

You've successfully completed all modules (13-20)! Your e-commerce app now includes:
- ✅ Profile screen with password change
- ✅ Quantity selector for products
- ✅ VAT calculation (12%)
- ✅ Payment screen with mock payment
- ✅ Notification system
- ✅ Real-time chat with unread counts
- ✅ Professional branding and UI
- ✅ Release APK ready for distribution

Happy coding! 🚀


