#!/bin/bash




echo "🚀 Инициализация администратора..."
echo ""
echo "⚙️  Перестраиваем приложение..."
flutter clean
flutter pub get

echo ""
echo "🏃 Запускаем приложение..."
flutter run

echo ""
echo "✅ Администратор автоматически создан при старте!"
echo ""
echo "📝 Данные для входа:"
echo "   Email:    admin@noti.school"
echo "   Пароль:   Admin123!@#"
echo ""
echo "💾 Данные сохранены в Firebase!"
