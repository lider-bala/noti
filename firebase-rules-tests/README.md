# Тестирование правил Firebase

Этот проект содержит скрипты для тестирования `firestore.rules` и `storage.rules`.
Проект использует современный Firebase Modular API (ESM).

## Как подготовить и запустить тесты

1. Удалите кэш зависимостей (важно при обновлении версий):

```bash
rm -rf node_modules package-lock.json
```

2. Установите зависимости:

```bash
npm install
```

3. Запустите тесты (автоматически поднимет Firebase Emulator Suite):

```bash
npm test
```
