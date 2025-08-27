# Application Flutter de Recharge de Crédit Mobile

Cette application Flutter permet de recharger facilement du crédit mobile pour les opérateurs Yas, Orange et Airtel à Madagascar.

## Fonctionnalités

- **Sélection d'opérateur** : Choisir entre Yas, Orange et Airtel
- **Scanner de code** : Scanner un code de recharge de 14 chiffres avec la caméra
- **Saisie manuelle** : Option de saisie manuelle si le scanner échoue
- **Génération USSD automatique** : Génère automatiquement le bon code selon l'opérateur
- **Historique local** : Sauvegarde l'historique des recharges avec SQLite

## Codes USSD par opérateur

- **Yas** : `#321*{code}#`
- **Orange** : `144{code}`
- **Airtel** : `*999*{code}#`

## Installation

1. Cloner le projet
2. Installer les dépendances :
   ```bash
   flutter pub get
   ```
3. Lancer l'application :
   ```bash
   flutter run
   ```

## Permissions requises

- **Caméra** : Pour scanner les codes de recharge
- **Téléphone** : Pour lancer les codes USSD
- **Internet** : Pour les fonctionnalités réseau

## Dépendances principales

- `google_ml_kit` : Scanner OCR
- `flutter_barcode_scanner` : Scanner de codes barres
- `url_launcher` : Lancement des codes USSD
- `sqflite` : Base de données locale
- `permission_handler` : Gestion des permissions

## Structure du projet

```
lib/
├── models/
│   ├── operator.dart
│   └── recharge_history.dart
├── services/
│   ├── database_helper.dart
│   ├── scanner_service.dart
│   └── ussd_service.dart
├── screens/
│   ├── home_screen.dart
│   └── history_screen.dart
└── main.dart
```

## Utilisation

1. **Choisir un opérateur** : Sélectionner Yas, Orange ou Airtel
2. **Scanner ou saisir le code** : Scanner le code de recharge ou le saisir manuellement
3. **Valider** : Appuyer sur "Recharger" pour générer et lancer le code USSD
4. **Consulter l'historique** : Voir les recharges précédentes dans l'onglet historique

## Note

Cette application est conçue spécifiquement pour les opérateurs mobiles de Madagascar. Les codes USSD peuvent varier selon les régions.
