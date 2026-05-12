# Noti Flutter Converted

Это упрощённая конвертация вашего React-проекта (UI-дизайн Noti) в структуру Flutter-приложения.

## Что уже есть

- Экран логина (LoginScreen)
- Экран регистрации (RegisterScreen)
- Основной экран с боковым меню (MainScreen + SideMenu)
- Заглушки разделов: Главная, Расписание, Домашние задания, Ученики, Учителя, Оценки, Файлы, Настройки
- Градиентный фон, карточки и базовая типографика, похожие на оригинальный дизайн

## Как запустить

Для быстрой проверки без `--dart-define` доступен один bootstrap-админ:

```bash
flutter run
```

Вход:

- Роль: `Админ`
- Email: `admin@noti.kg`
- Пароль: `admin123`

Для локальной проверки с демо-данными и списком аккаунтов на экране входа:

```bash
flutter pub get
flutter run --dart-define=ENABLE_DEMO_DATA=true
```

Для production/dev-проверки без демо-аккаунтов:

```bash
flutter run --dart-define=USE_FIREBASE_AUTH=true --dart-define=ENABLE_DEMO_DATA=false
```

Для локальной работы без Firebase, но с возможностью создавать классы и аккаунты
в текущей сессии, запускайте без Firestore:

```bash
flutter run --dart-define=ENABLE_DEMO_DATA=true
```

Для Firestore обязательно нужен вход через Firebase Auth и custom claims ролей.
Не запускайте Firestore вместе с mock-login, иначе rules отклонят записи:

```bash
flutter run \
  --dart-define=USE_FIREBASE_AUTH=true \
  --dart-define=USE_FIRESTORE=true \
  --dart-define=ENABLE_DEMO_DATA=false
```

Первого Firebase admin нужно создать через provisioning script, потому что
custom claims нельзя выставлять из Flutter-клиента:

```bash
cd firebase-rules-tests
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
npm run provision:admin
```

Вы можете дальше детально дополнять каждый экран логикой и точными виджетами под ваш дизайн.
# noti
