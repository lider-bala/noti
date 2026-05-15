import 'package:flutter/material.dart';
import 'lib/widgets/admin_panel.dart';

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

class Example5ComplexPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      title: 'Статистика по ролям',
      icon: Icons.bar_chart_rounded,
      children: [
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

class Example6FullPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Padding(
            padding: EdgeInsets.all(16),
            child: Example2MetricsGrid(),
          ),
          Divider(height: 32),
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
          Padding(
            padding: EdgeInsets.all(16),
            child: Example4ActionButtons(),
          ),
        ],
      ),
    );
  }
}
