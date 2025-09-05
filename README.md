# 📱 Credit Recharge App

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

A modern Flutter application for mobile credit recharging in Madagascar, supporting **Yas**, **Orange**, and **Airtel** operators with advanced OCR scanning capabilities.

## ✨ Features

### 🔍 Smart Code Recognition
- **OCR Text Recognition** using Google ML Kit for detecting 14-digit recharge codes
- **Real-time scanning** with optimized camera view
- **Manual input fallback** when scanning fails
- **Code validation** to ensure 14-digit format

### 📞 USSD Integration
- **Automatic USSD generation** based on selected operator
- **Native Android integration** for direct USSD execution
- **Fallback mechanisms** with clipboard copy and manual instructions
- **Multi-method approach** for maximum compatibility

### 🏢 Multi-Operator Support
- **Yas**: `#321*{code}#`
- **Orange**: `144{code}`
- **Airtel**: `*999*{code}#`

### 📊 Local History
- **SQLite database** for storing recharge history
- **Date and operator tracking**
- **Easy history management** with delete options
- **Offline functionality**

### 🎨 Modern UI/UX
- **Material Design 3** components
- **Intuitive operator selection** with visual feedback
- **Haptic feedback** for better user experience
- **Responsive design** for various screen sizes

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.7.2)
- Android SDK (API level 21+)
- Camera permissions for code scanning
- Phone permissions for USSD execution

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Tiavina22/credit.git
   cd credit
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

### Build for Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release
```

## 📱 Screenshots

| Home Screen | Scanner | History |
|-------------|---------|---------|
| ![Home](screenshots/home.png) | ![Scanner](screenshots/scanner.png) | ![History](screenshots/history.png) |

## 🛠️ Technical Stack

### Dependencies
- **`mobile_scanner`** - QR/Barcode scanning
- **`google_ml_kit`** - OCR text recognition
- **`camera`** - Camera functionality
- **`sqflite`** - Local database
- **`url_launcher`** - USSD execution
- **`permission_handler`** - Runtime permissions
- **`intl`** - Internationalization

### Architecture
```
lib/
├── models/
│   ├── operator.dart           # Mobile operator data models
│   └── recharge_history.dart   # History data models
├── services/
│   ├── database_helper.dart    # SQLite database operations
│   ├── scanner_service.dart    # OCR and scanning logic
│   └── ussd_service.dart       # USSD execution handling
├── screens/
│   ├── home_screen.dart        # Main application screen
│   ├── scanner_screen.dart     # Code scanning interface
│   ├── ocr_scanner_screen.dart # OCR-based scanning
│   └── history_screen.dart     # Recharge history view
└── main.dart                   # Application entry point
```

## 🎯 Usage

1. **Select Operator**: Choose between Yas, Orange, or Airtel
2. **Input Code**: 
   - Scan a 14-digit recharge code using the camera
   - Or manually enter the code
3. **Execute**: Tap "Recharge" to generate and execute the USSD code
4. **History**: View past recharges in the history section

## 🔒 Permissions

The app requires the following Android permissions:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.CALL_PHONE" />
<uses-permission android:name="android.permission.INTERNET" />
```

## 🌍 Localization

Currently supported languages:
- English (default)
- French (Madagascar context)

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Commit your changes**
   ```bash
   git commit -m 'Add some amazing feature'
   ```
4. **Push to the branch**
   ```bash
   git push origin feature/amazing-feature
   ```
5. **Open a Pull Request**

### Code Style
- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable names
- Add comments for complex logic
- Ensure code passes `flutter analyze`

## 🐛 Bug Reports

Found a bug? Please open an issue with:
- Device information
- Flutter version
- Steps to reproduce
- Expected vs actual behavior

## 📋 Roadmap

- [ ] **Multi-language support** (Malagasy, English, French)
- [ ] **Backup/restore** functionality
- [ ] **QR code generation** for sharing codes
- [ ] **Dark mode** support
- [ ] **Widget support** for quick recharge
- [ ] **Statistics dashboard**
- [ ] **Export history** to CSV/PDF

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Google ML Kit** for OCR capabilities
- **Flutter team** for the amazing framework
- **Madagascar mobile operators** for USSD code specifications
- **Open source community** for inspiration and tools

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/Tiavina22/credit/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Tiavina22/credit/discussions)
- **Email**: [your-email@example.com](mailto:your-email@example.com)

## 🌟 Star the Project

If this project helped you, please consider giving it a ⭐ on GitHub!

---

**Made with ❤️ in Madagascar for the Madagascar mobile community.**
