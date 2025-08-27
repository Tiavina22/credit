# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-XX

### Added
- Initial release of Credit Recharge Madagascar app
- Support for three major Madagascar operators (Yas, Orange, Airtel)
- OCR scanning for 14-digit credit codes using Google ML Kit
- Manual code input as fallback option
- Automatic USSD code generation and execution
- Local SQLite database for recharge history
- Material Design 3 UI with operator-specific theming
- Multi-platform support (Android, iOS, Web, Windows, macOS, Linux)

### Features
- **Operator Selection**: Choose between Yas, Orange, and Airtel
- **Code Scanning**: OCR-powered scanning of credit card codes
- **Manual Input**: Fallback manual entry for 14-digit codes
- **USSD Generation**: Automatic formatting based on operator
- **History Tracking**: Local storage of recharge attempts
- **Material Design**: Modern, responsive UI

### Technical Implementation
- Flutter SDK >=3.7.2
- Google ML Kit for OCR text recognition
- SQLite for local data persistence
- Camera integration with runtime permissions
- Cross-platform USSD execution
- Robust error handling and user feedback

### Known Limitations
- USSD execution requires manual confirmation on Android (security restriction)
- Camera scanning requires good lighting conditions
- OCR works best with clear, unobstructed credit card text

## [Unreleased]

### Planned Features
- QR code scanning support
- Dark mode theme
- Multiple language support (French, Malagasy)
- Export history to CSV
- Backup/restore functionality
- Operator balance checking
- Push notifications for recharge reminders

### Roadmap
- Enhanced OCR accuracy
- Offline mode improvements
- Integration with operator APIs
- Advanced analytics and insights
