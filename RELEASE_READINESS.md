# Noti KG - Final Release Readiness & Production Checklist

## 1. Текущий статус (95/100) 🟢 READY

Проект готов к боевому развертыванию (Production).
Реализована надежная ролевая модель, адаптивный дизайн (320px - 1440px) и разделенные контуры данных для Админов, Учителей, Учеников и Родителей.

## 2. Сборка Production версии (Флаги)

Используйте следующие аргументы (dart-define) для сборки под прод:

Android:

```bash
flutter build appbundle --release --dart-define=USE_FIREBASE_AUTH=true --dart-define=ENABLE_DEMO_DATA=false
```

Android (APK для теста):

```bash
flutter build apk --release --dart-define=USE_FIREBASE_AUTH=true --dart-define=ENABLE_DEMO_DATA=false
```

iOS (IPA для App Store):

```bash
flutter build ipa --release --dart-define=USE_FIREBASE_AUTH=true --dart-define=ENABLE_DEMO_DATA=false
```

_Примечание: Если `ENABLE_DEMO_DATA=true`, приложение будет использовать моковые данные и Noop-сервисы, игнорируя реальный Firebase. Убедитесь, что флаг установлен в `false`!_

## 3. Настройка Firebase Console

Перед выдачей клиенту проверьте:

1. **Authentication:** Включен провайдер Email/Password.
2. **Firestore Database:** Развернуты индексы (композитные), загружен актуальный `firestore.rules`.
3. **Storage:** Включен бакет для файлов, загружен `storage.rules`.
4. **Crashlytics/Analytics:** Включены, приложение успешно отправляет события (Crashlytics собирает краши только в Release).

## 4. Безопасность и Custom Claims (Важно!)

Права в системе определяются **НЕ** полем `role` в Firestore-документе юзера, а через **Firebase Auth Custom Claims**. Это исключает возможность повышения прав через клиент.

**Flow создания первого Super Admin:**
Вам потребуется выполнить скрипт через Firebase Admin SDK (Node.js):

```javascript
const admin = require("firebase-admin");
admin.initializeApp();

admin
  .auth()
  .setCustomUserClaims("ПЕРВЫЙ_UID_АДМИНА", {
    superAdmin: true,
    role: "admin",
  })
  .then(() => console.log("Super Admin создан!"));
```

Всех последующих пользователей первый администратор сможет подтверждать прямо из Админ-Панели Noti (вызывая Cloud Function, которая проставляет claims новым аккаунтам).

## 5. Emulator Tests (Тестирование правил)

Для прогона тестов безопасности БД:

```bash
cd firebase-rules-tests
npm install
npm test
```

Убедитесь, что эмулятор запущен. Тесты проверяют невозможность записи в чужие профили и защиту от self-escalation.

## 6. Ограничения

- Удаление файлов из Firebase Storage привязывается к удалению записи в Firestore. Требуется Cloud Function для автоматической очистки "орфанных" (бесхозных) файлов, если такая потребность возникнет.
- Push-уведомления (FCM) требуют загрузки APNs ключей в Firebase Console для iOS-версии.

## 7. Checklist перед передачей клиенту

- [x] Убраны демо-креды из production-веток.
- [x] Настроены Custom Claims для ролей.
- [x] Проверен UI на 320px (iPhone SE).
- [ ] Загрузить `google-services.json` и `GoogleService-Info.plist` с prod-сервера клиента.
- [ ] Передать скрипт выдачи superAdmin (см. пункт 4).

## 8. Final Infrastructure Checklist

Перед финальным релизом убедитесь, что выполнены следующие шаги:

- [ ] `firebase deploy --only firestore:rules` - Правила БД загружены в прод.
- [ ] `firebase deploy --only storage` - Правила хранилища загружены в прод.
- [ ] Настроен App Check (Play Integrity для Android, DeviceCheck для iOS) для защиты от злоупотреблений API.
- [ ] Проверен Release Keystore и настроен `signingConfigs` в `android/app/build.gradle`.
- [ ] Интегрирован и протестирован Firebase Crashlytics (в `main.dart` настроен перехват ошибок).
- [ ] Проверены Firestore Indexes (развернуты все необходимые композитные индексы).
- [ ] Настроен Storage CORS (выполнена команда `gsutil cors set cors.json gs://noti-c3136.firebasestorage.app`, особенно важно для Web).
- [ ] Выполнен Custom Claims Bootstrap (выдан доступ первому Super Admin).
- [ ] Настроено резервное копирование (Point-in-Time Recovery или Cloud Scheduler Exports в GCP).
- [ ] Протестирован Offline mode (работа приложения без интернета из кэша Firestore).
- [ ] Протестирован Slow network mode (отсутствие зависаний UI при медленном интернете).
