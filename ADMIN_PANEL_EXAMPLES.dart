// ignore_for_file: file_names, use_key_in_widget_constructors, avoid_print

// Примеры использования компонентов админ-панели

import 'package:flutter/material.dart';
import 'lib/widgets/admin_panel.dart';

// ============================================================
// ПРИМЕР 1: Простая панель с текстом
// ============================================================
class Example1SimplePanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      title: 'Основная информация',
      icon: Icons.info_rounded,
      children: [
        Text(
          'Это описание системы',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}

// ============================================================
// ПРИМЕР 2: Панель с метриками (сетка)
// ============================================================
class Example2MetricsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        MetricCard(
          title: 'Всего пользователей',
          value: '150',
          subtitle: 'активных сейчас',
          icon: Icons.people_rounded,
          gradient: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        MetricCard(
          title: 'Новых заявок',
          value: '5',
          subtitle: 'ждут одобрения',
          icon: Icons.mail_rounded,
          gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
        MetricCard(
          title: 'Системных ошибок',
          value: '0',
          subtitle: 'отличное состояние',
          icon: Icons.check_circle_rounded,
          gradient: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        ),
        MetricCard(
          title: 'Файлов загружено',
          value: '247',
          subtitle: 'в хранилище',
          icon: Icons.folder_rounded,
          gradient: [Color(0xFFA855F7), Color(0xFF7C3AED)],
        ),
      ],
    );
  }
}

// ============================================================
// ПРИМЕР 3: Список элементов в панели
// ============================================================
class Example3ListPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      AdminListItem(
        title: 'Иван Петров',
        subtitle: 'Учитель • Класс 10А',
        leading: CircleAvatar(child: Text('И')),
        trailing: Icon(Icons.arrow_forward_rounded),
      ),
      AdminListItem(
        title: 'Мария Сидорова',
        subtitle: 'Ученица • Класс 9Б',
        leading: CircleAvatar(child: Text('М')),
        trailing: Icon(Icons.arrow_forward_rounded),
      ),
    ];

    return AdminListPanel(
      title: 'Последние добавленные пользователи',
      icon: Icons.people_rounded,
      items: items,
      onViewAll: () => print('Показать всех'),
    );
  }
}

// ============================================================
// ПРИМЕР 4: Кнопки действий
// ============================================================
class Example4ActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      title: 'Быстрые действия',
      icon: Icons.flash_on_rounded,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            AdminActionButton(
              label: 'Создать учётную запись',
              icon: Icons.person_add_rounded,
              isPrimary: true,
              onPressed: () => print('Создание'),
            ),
            AdminActionButton(
              label: 'Загрузить файл',
              icon: Icons.upload_rounded,
              onPressed: () => print('Загрузка'),
            ),
            AdminActionButton(
              label: 'Удалить аккаунт',
              icon: Icons.delete_rounded,
              isDangerous: true,
              onPressed: () => print('Удаление'),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// ПРИМЕР 5: Сложная панель с разделённым содержимым
// ============================================================
class Example5ComplexPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      title: 'Статистика по ролям',
      icon: Icons.bar_chart_rounded,
      children: [
        // Первый ряд
        Row(
          children: [
            Expanded(
              child: _StatBox(
                label: 'Учителей',
                value: '25',
                icon: Icons.school_rounded,
                color: Color(0xFF10B981),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatBox(
                label: 'Учеников',
                value: '350',
                icon: Icons.people_rounded,
                color: Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        // Второй ряд
        Row(
          children: [
            Expanded(
              child: _StatBox(
                label: 'Родителей',
                value: '180',
                icon: Icons.family_restroom_rounded,
                color: Color(0xFFF59E0B),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatBox(
                label: 'Администраторов',
                value: '3',
                icon: Icons.security_rounded,
                color: Color(0xFFA855F7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ПРИМЕР 6: Полная страница с несколькими панелями
// ============================================================
class Example6FullPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Добро пожаловать!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Панель управления школой',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Метрики
          Padding(
            padding: EdgeInsets.all(16),
            child: Example2MetricsGrid(),
          ),

          // Разделитель
          Divider(height: 32),

          // Две панели рядом
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Example3ListPanel(),
                SizedBox(height: 16),
                Example5ComplexPanel(),
              ],
            ),
          ),

          // Кнопки действий
          Padding(
            padding: EdgeInsets.all(16),
            child: Example4ActionButtons(),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// КАК ИСПОЛЬЗОВАТЬ В ВАШЕМ КОДЕ
// ============================================================

/*
1. ИМПОРТИРУЙТЕ КОМПОНЕНТЫ:
   import 'widgets/admin_panel.dart';

2. ИСПОЛЬЗУЙТЕ В BUILD:
   @override
   Widget build(BuildContext context) {
     return SingleChildScrollView(
       child: Column(
         children: [
           AdminPanel(
             title: 'Моя панель',
             icon: Icons.info_rounded,
             children: [
               Text('Содержимое панели'),
             ],
           ),
         ],
       ),
     );
   }

3. ДЛЯ КАРТОЧЕК МЕТРИК:
   MetricCard(
     title: 'Название',
     value: '100',
     icon: Icons.info_rounded,
     gradient: [Colors.blue, Colors.purple],
   )

4. ДЛЯ СПИСКОВ:
   AdminListPanel(
     title: 'Список',
     items: [
       AdminListItem(title: 'Элемент 1'),
       AdminListItem(title: 'Элемент 2'),
     ],
   )

5. ДЛЯ КНОПОК:
   AdminActionButton(
     label: 'Действие',
     icon: Icons.add_rounded,
     isPrimary: true,
     onPressed: () => print('Нажато'),
   )
*/

// ============================================================
// ЦВЕТОВАЯ СХЕМА
// ============================================================

/*
PRIMARY (Основной):       #6366F1 - Color(0xFF6366F1)
SUCCESS (Успех):          #10B981 - Color(0xFF10B981)
WARNING (Внимание):       #F59E0B - Color(0xFFF59E0B)
ERROR (Ошибка):           #EF4444 - Color(0xFFEF4444)
INFO (Информация):        #3B82F6 - Color(0xFF3B82F6)
SECONDARY (Дополнитель):  #A855F7 - Color(0xFFA855F7)
*/
