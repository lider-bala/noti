import '../models/user_role.dart';
import 'app_language.dart';
import 'app_literal_localizations.dart';

class AppLocalizations {
  final AppLanguage language;

  const AppLocalizations(this.language);

  static const Map<String, Map<AppLanguage, String>> _localizedValues = {
    'app.name': {
      AppLanguage.russian: 'Noti KG',
      AppLanguage.kyrgyz: 'Noti KG',
    },
    'app.tagline': {
      AppLanguage.russian: 'Умный помощник для школы в Кыргызстане',
      AppLanguage.kyrgyz: 'Кыргызстандагы мектеп үчүн акылдуу жардамчы',
    },
    'language.switch': {
      AppLanguage.russian: 'Язык',
      AppLanguage.kyrgyz: 'Тил',
    },
    'language.russian': {
      AppLanguage.russian: 'Русский',
      AppLanguage.kyrgyz: 'Орусча',
    },
    'language.kyrgyz': {
      AppLanguage.russian: 'Кыргызча',
      AppLanguage.kyrgyz: 'Кыргызча',
    },
    'role.teacher': {
      AppLanguage.russian: 'Учитель',
      AppLanguage.kyrgyz: 'Мугалим',
    },
    'role.student': {
      AppLanguage.russian: 'Ученик',
      AppLanguage.kyrgyz: 'Окуучу',
    },
    'role.parent': {
      AppLanguage.russian: 'Родитель',
      AppLanguage.kyrgyz: 'Ата-эне',
    },
    'role.admin': {
      AppLanguage.russian: 'Админ',
      AppLanguage.kyrgyz: 'Админ',
    },
    'auth.welcome': {
      AppLanguage.russian: 'Добро пожаловать',
      AppLanguage.kyrgyz: 'Кош келиңиз',
    },
    'auth.createAccount': {
      AppLanguage.russian: 'Создайте аккаунт в Noti',
      AppLanguage.kyrgyz: 'Noti үчүн аккаунт түзүңүз',
    },
    'auth.signInDescription': {
      AppLanguage.russian: 'Войдите в систему школы',
      AppLanguage.kyrgyz: 'Мектеп системасына кириңиз',
    },
    'auth.email': {
      AppLanguage.russian: 'Email',
      AppLanguage.kyrgyz: 'Email',
    },
    'auth.password': {
      AppLanguage.russian: 'Пароль',
      AppLanguage.kyrgyz: 'Сырсөз',
    },
    'auth.confirmPassword': {
      AppLanguage.russian: 'Подтвердите пароль',
      AppLanguage.kyrgyz: 'Сырсөздү ырастаңыз',
    },
    'auth.phone': {
      AppLanguage.russian: 'Телефон',
      AppLanguage.kyrgyz: 'Телефон',
    },
    'auth.fullName': {
      AppLanguage.russian: 'Полное имя',
      AppLanguage.kyrgyz: 'Толук аты-жөнү',
    },
    'auth.class': {
      AppLanguage.russian: 'Класс',
      AppLanguage.kyrgyz: 'Класс',
    },
    'auth.forgotPassword': {
      AppLanguage.russian: 'Забыли пароль?',
      AppLanguage.kyrgyz: 'Сырсөздү унуттуңузбу?',
    },
    'auth.login': {
      AppLanguage.russian: 'Войти',
      AppLanguage.kyrgyz: 'Кирүү',
    },
    'auth.register': {
      AppLanguage.russian: 'Зарегистрироваться',
      AppLanguage.kyrgyz: 'Катталуу',
    },
    'auth.noAccount': {
      AppLanguage.russian: 'Нет аккаунта?',
      AppLanguage.kyrgyz: 'Аккаунтуңуз жокпу?',
    },
    'auth.haveAccount': {
      AppLanguage.russian: 'Уже есть аккаунт?',
      AppLanguage.kyrgyz: 'Аккаунтуңуз барбы?',
    },
    'auth.openRegister': {
      AppLanguage.russian: 'Регистрация',
      AppLanguage.kyrgyz: 'Катталуу',
    },
    'auth.openLogin': {
      AppLanguage.russian: 'Войти',
      AppLanguage.kyrgyz: 'Кирүү',
    },
    'auth.demoAccounts': {
      AppLanguage.russian: 'Демо-аккаунты для проверки',
      AppLanguage.kyrgyz: 'Текшерүү үчүн демо-аккаунттар',
    },
    'auth.invalidCredentials': {
      AppLanguage.russian:
          'Неверная роль, email или пароль. Проверьте введённые данные.',
      AppLanguage.kyrgyz:
          'Роль, email же сырсөз туура эмес. Маалыматты кайра текшериңиз.',
    },
    'auth.roleMismatch': {
      AppLanguage.russian: 'Выберите правильную роль для этого аккаунта.',
      AppLanguage.kyrgyz: 'Бул аккаунт үчүн туура ролду тандаңыз.',
    },
    'auth.profileMissing': {
      AppLanguage.russian:
          'Профиль пользователя не найден в базе школы. Обратитесь к администратору.',
      AppLanguage.kyrgyz:
          'Колдонуучунун профили мектеп базасында табылган жок.',
    },
    'auth.accountInactive': {
      AppLanguage.russian: 'Аккаунт заблокирован или удален.',
      AppLanguage.kyrgyz: 'Аккаунт бөгөттөлгөн же өчүрүлгөн.',
    },
    'auth.networkFailed': {
      AppLanguage.russian: 'Нет соединения с Firebase. Проверьте интернет.',
      AppLanguage.kyrgyz: 'Firebase менен байланыш жок. Интернетти текшериңиз.',
    },
    'auth.createUserFailed': {
      AppLanguage.russian:
          'Не удалось создать Firebase Auth аккаунт. Проверьте email, пароль и настройки Firebase Auth.',
      AppLanguage.kyrgyz: 'Firebase Auth аккаунтун түзүү мүмкүн болгон жок.',
    },
    'auth.accountCreated': {
      AppLanguage.russian: 'Аккаунт создан. Вы вошли в систему.',
      AppLanguage.kyrgyz: 'Аккаунт түзүлдү. Сиз системага кирдиңиз.',
    },
    'auth.duplicateEmail': {
      AppLanguage.russian: 'Пользователь с таким email уже существует.',
      AppLanguage.kyrgyz: 'Мындай email менен колдонуучу мурунтан бар.',
    },
    'auth.duplicatePhone': {
      AppLanguage.russian: 'Пользователь с таким номером уже существует.',
      AppLanguage.kyrgyz: 'Мындай номер менен колдонуучу мурунтан бар.',
    },
    'auth.resetSoon': {
      AppLanguage.russian:
          'Восстановление пароля подключим на следующем этапе.',
      AppLanguage.kyrgyz: 'Сырсөздү калыбына келтирүү кийинки этапта кошулат.',
    },
    'auth.socialSoon': {
      AppLanguage.russian:
          'Социальная авторизация пока отключена в этом прототипе.',
      AppLanguage.kyrgyz:
          'Бул прототипте социалдык авторизация азырынча өчүрүлгөн.',
    },
    'auth.emailHint': {
      AppLanguage.russian: 'teacher@noti.kg',
      AppLanguage.kyrgyz: 'teacher@noti.kg',
    },
    'auth.phoneHint': {
      AppLanguage.russian: '+996555123456',
      AppLanguage.kyrgyz: '+996555123456',
    },
    'auth.nameHint': {
      AppLanguage.russian: 'Сыдыкова Айжан Кубанычбековна',
      AppLanguage.kyrgyz: 'Сыдыкова Айжан Кубанычбековна',
    },
    'auth.classHint': {
      AppLanguage.russian: 'Выберите класс',
      AppLanguage.kyrgyz: 'Классты тандаңыз',
    },
    'dashboard.teacher': {
      AppLanguage.russian: 'Панель учителя',
      AppLanguage.kyrgyz: 'Мугалим панели',
    },
    'dashboard.student': {
      AppLanguage.russian: 'Панель ученика',
      AppLanguage.kyrgyz: 'Окуучу панели',
    },
    'dashboard.parent': {
      AppLanguage.russian: 'Панель родителя',
      AppLanguage.kyrgyz: 'Ата-эне панели',
    },
    'dashboard.admin': {
      AppLanguage.russian: 'Панель администратора',
      AppLanguage.kyrgyz: 'Админ панели',
    },
    'section.home': {
      AppLanguage.russian: 'Главная',
      AppLanguage.kyrgyz: 'Башкы бет',
    },
    'section.schedule': {
      AppLanguage.russian: 'Расписание',
      AppLanguage.kyrgyz: 'Жадыбал',
    },
    'section.homework': {
      AppLanguage.russian: 'Домашние задания',
      AppLanguage.kyrgyz: 'Үй тапшырмалары',
    },
    'section.grades': {
      AppLanguage.russian: 'Оценки',
      AppLanguage.kyrgyz: 'Баалар',
    },
    'section.students': {
      AppLanguage.russian: 'Ученики',
      AppLanguage.kyrgyz: 'Окуучулар',
    },
    'section.teachers': {
      AppLanguage.russian: 'Учителя',
      AppLanguage.kyrgyz: 'Мугалимдер',
    },
    'section.files': {
      AppLanguage.russian: 'Файлы',
      AppLanguage.kyrgyz: 'Файлдар',
    },
    'section.settings': {
      AppLanguage.russian: 'Настройки',
      AppLanguage.kyrgyz: 'Жөндөөлөр',
    },
    'section.classmates': {
      AppLanguage.russian: 'Одноклассники',
      AppLanguage.kyrgyz: 'Классташтар',
    },
    'section.attendance': {
      AppLanguage.russian: 'Посещаемость',
      AppLanguage.kyrgyz: 'Катышуу',
    },
    'section.notifications': {
      AppLanguage.russian: 'Уведомления',
      AppLanguage.kyrgyz: 'Билдирмелер',
    },
    'section.overview': {
      AppLanguage.russian: 'Обзор',
      AppLanguage.kyrgyz: 'Обзор',
    },
    'section.users': {
      AppLanguage.russian: 'Пользователи',
      AppLanguage.kyrgyz: 'Колдонуучулар',
    },
    'section.academics': {
      AppLanguage.russian: 'Классы и уроки',
      AppLanguage.kyrgyz: 'Класстар жана сабактар',
    },
    'section.analytics': {
      AppLanguage.russian: 'Аналитика',
      AppLanguage.kyrgyz: 'Аналитика',
    },
    'section.reports': {
      AppLanguage.russian: 'Отчёты',
      AppLanguage.kyrgyz: 'Отчеттор',
    },
    'section.chat': {
      AppLanguage.russian: 'Сообщения',
      AppLanguage.kyrgyz: 'Кабарлар',
    },
    'chat.writeToAdmin': {
      AppLanguage.russian: 'Написать администратору',
      AppLanguage.kyrgyz: 'Админге жазуу',
    },
    'chat.noMessages': {
      AppLanguage.russian: 'Нет сообщений',
      AppLanguage.kyrgyz: 'Кабарлар жок',
    },
    'chat.startConversation': {
      AppLanguage.russian: 'Начните диалог с администратором',
      AppLanguage.kyrgyz: 'Админ менен сүйлөшүүнү баштаңыз',
    },
    'chat.typeMessage': {
      AppLanguage.russian: 'Напишите сообщение...',
      AppLanguage.kyrgyz: 'Кабар жазыңыз...',
    },
    'chat.conversations': {
      AppLanguage.russian: 'Диалоги',
      AppLanguage.kyrgyz: 'Сүйлөшүүлөр',
    },
    'chat.noConversations': {
      AppLanguage.russian: 'Нет диалогов',
      AppLanguage.kyrgyz: 'Сүйлөшүүлөр жок',
    },
    'chat.noConversationsHint': {
      AppLanguage.russian: 'Когда пользователи напишут вам, диалоги появятся здесь',
      AppLanguage.kyrgyz: 'Колдонуучулар жазганда, сүйлөшүүлөр бул жерде пайда болот',
    },
    'common.logout': {
      AppLanguage.russian: 'Выйти',
      AppLanguage.kyrgyz: 'Чыгуу',
    },
    'common.or': {
      AppLanguage.russian: 'или',
      AppLanguage.kyrgyz: 'же',
    },
    'common.today': {
      AppLanguage.russian: 'Сегодня',
      AppLanguage.kyrgyz: 'Бүгүн',
    },
    'common.quickActions': {
      AppLanguage.russian: 'Быстрые действия',
      AppLanguage.kyrgyz: 'Тез аракеттер',
    },
    'common.stats': {
      AppLanguage.russian: 'Статистика',
      AppLanguage.kyrgyz: 'Статистика',
    },
    'common.upcomingLesson': {
      AppLanguage.russian: 'Ближайший урок',
      AppLanguage.kyrgyz: 'Жакынкы сабак',
    },
    'common.recentActivity': {
      AppLanguage.russian: 'Недавняя активность',
      AppLanguage.kyrgyz: 'Акыркы активдүүлүк',
    },
    'common.upcomingEvents': {
      AppLanguage.russian: 'Предстоящие события',
      AppLanguage.kyrgyz: 'Алдыдагы окуялар',
    },
    'common.recentGrades': {
      AppLanguage.russian: 'Последние оценки',
      AppLanguage.kyrgyz: 'Акыркы баалар',
    },
    'common.notifications': {
      AppLanguage.russian: 'Уведомления',
      AppLanguage.kyrgyz: 'Билдирмелер',
    },
    'settings.account': {
      AppLanguage.russian: 'Аккаунт',
      AppLanguage.kyrgyz: 'Аккаунт',
    },
    'settings.preferences': {
      AppLanguage.russian: 'Настройки',
      AppLanguage.kyrgyz: 'Жөндөөлөр',
    },
    'settings.support': {
      AppLanguage.russian: 'Поддержка',
      AppLanguage.kyrgyz: 'Колдоо',
    },
    'settings.profile': {
      AppLanguage.russian: 'Профиль',
      AppLanguage.kyrgyz: 'Профиль',
    },
    'settings.security': {
      AppLanguage.russian: 'Безопасность',
      AppLanguage.kyrgyz: 'Коопсуздук',
    },
    'settings.privacy': {
      AppLanguage.russian: 'Приватность',
      AppLanguage.kyrgyz: 'Купуялык',
    },
    'settings.notifications': {
      AppLanguage.russian: 'Уведомления',
      AppLanguage.kyrgyz: 'Билдирмелер',
    },
    'settings.darkMode': {
      AppLanguage.russian: 'Темная тема',
      AppLanguage.kyrgyz: 'Караңгы тема',
    },
    'settings.theme': {
      AppLanguage.russian: 'Тема приложения',
      AppLanguage.kyrgyz: 'Колдонмонун темасы',
    },
    'settings.themeSubtitle': {
      AppLanguage.russian: 'Единая тема для всех разделов и ролей',
      AppLanguage.kyrgyz: 'Бардык бөлүмдөр жана ролдор үчүн бирдиктүү тема',
    },
    'settings.themeSystem': {
      AppLanguage.russian: 'Система',
      AppLanguage.kyrgyz: 'Система',
    },
    'settings.themeLight': {
      AppLanguage.russian: 'Светлая',
      AppLanguage.kyrgyz: 'Жарык',
    },
    'settings.themeDark': {
      AppLanguage.russian: 'Тёмная',
      AppLanguage.kyrgyz: 'Караңгы',
    },
    'settings.appearance': {
      AppLanguage.russian: 'Внешний вид',
      AppLanguage.kyrgyz: 'Сырткы көрүнүш',
    },
    'settings.language': {
      AppLanguage.russian: 'Язык',
      AppLanguage.kyrgyz: 'Тил',
    },
    'settings.help': {
      AppLanguage.russian: 'Помощь и FAQ',
      AppLanguage.kyrgyz: 'Жардам жана FAQ',
    },
    'settings.contact': {
      AppLanguage.russian: 'Связаться с нами',
      AppLanguage.kyrgyz: 'Биз менен байланышуу',
    },
    'settings.push': {
      AppLanguage.russian: 'Пуш-уведомления',
      AppLanguage.kyrgyz: 'Push-билдирмелер',
    },
    'settings.pushSubtitle': {
      AppLanguage.russian: 'Получать новые оценки, расписание и сообщения',
      AppLanguage.kyrgyz:
          'Жаңы бааларды, жадыбалды жана билдирүүлөрдү алып туруу',
    },
    'settings.homeworkReminders': {
      AppLanguage.russian: 'Напоминания о домашках',
      AppLanguage.kyrgyz: 'Үй тапшырма эскертмелери',
    },
    'settings.homeworkRemindersSubtitle': {
      AppLanguage.russian: 'Уведомлять за день до дедлайна',
      AppLanguage.kyrgyz: 'Мөөнөт бүткөнгө бир күн калганда эскертүү',
    },
    'settings.weeklyReport': {
      AppLanguage.russian: 'Еженедельный отчёт',
      AppLanguage.kyrgyz: 'Апталык отчёт',
    },
    'settings.weeklyReportSubtitle': {
      AppLanguage.russian: 'Отправлять дайджест на email',
      AppLanguage.kyrgyz: 'Email дарегине кыскача маалымат жөнөтүү',
    },
    'feedback.languageChanged': {
      AppLanguage.russian: 'Язык интерфейса обновлён.',
      AppLanguage.kyrgyz: 'Интерфейс тили жаңыртылды.',
    },
    'feedback.homeworkSoon': {
      AppLanguage.russian:
          'Форма создания задания будет подключена на следующем этапе.',
      AppLanguage.kyrgyz: 'Тапшырма түзүү формасы кийинки этапта кошулат.',
    },
    'feedback.downloadSoon': {
      AppLanguage.russian:
          'Действие подготовлено. Реальную загрузку подключим позже.',
      AppLanguage.kyrgyz: 'Аракет даяр. Чыныгы жүктөө кийин кошулат.',
    },
    'admin.overview.title': {
      AppLanguage.russian: 'Администрирование системы',
      AppLanguage.kyrgyz: 'Системаны башкаруу',
    },
    'admin.overview.subtitle': {
      AppLanguage.russian:
          'Управляйте ролями, пользователями и основными метриками школы',
      AppLanguage.kyrgyz:
          'Ролдорду, колдонуучуларды жана мектептин негизги көрсөткүчтөрүн башкарыңыз',
    },
    'admin.overview.systemStatus': {
      AppLanguage.russian: 'Статус системы',
      AppLanguage.kyrgyz: 'Системанын абалы',
    },
    'admin.overview.statusStable': {
      AppLanguage.russian: 'Все сервисы работают стабильно',
      AppLanguage.kyrgyz: 'Бардык сервистер туруктуу иштеп жатат',
    },
    'admin.overview.registeredUsers': {
      AppLanguage.russian: 'Зарегистрированные пользователи',
      AppLanguage.kyrgyz: 'Катталган колдонуучулар',
    },
    'admin.overview.languages': {
      AppLanguage.russian: 'Доступные языки',
      AppLanguage.kyrgyz: 'Жеткиликтүү тилдер',
    },
    'admin.overview.manageAccess': {
      AppLanguage.russian: 'Управление доступом',
      AppLanguage.kyrgyz: 'Жеткиликтүүлүктү башкаруу',
    },
    'admin.overview.lastSync': {
      AppLanguage.russian: 'Последняя синхронизация',
      AppLanguage.kyrgyz: 'Акыркы синхрондоштуруу',
    },
    'admin.users.title': {
      AppLanguage.russian: 'Пользователи системы',
      AppLanguage.kyrgyz: 'Системанын колдонуучулары',
    },
    'admin.users.subtitle': {
      AppLanguage.russian:
          'Все роли подключены к единому реестру входа и регистрации',
      AppLanguage.kyrgyz:
          'Бардык ролдор кирүү жана каттоо боюнча бирдиктүү реестрге туташтырылган',
    },
    'admin.users.total': {
      AppLanguage.russian: 'Всего аккаунтов',
      AppLanguage.kyrgyz: 'Жалпы аккаунттар',
    },
    'admin.users.latest': {
      AppLanguage.russian: 'Последние регистрации',
      AppLanguage.kyrgyz: 'Акыркы каттоолор',
    },
    'admin.analytics.title': {
      AppLanguage.russian: 'Аналитика платформы',
      AppLanguage.kyrgyz: 'Платформанын аналитикасы',
    },
    'admin.analytics.subtitle': {
      AppLanguage.russian:
          'Мониторинг активности по ролям и сценариям использования',
      AppLanguage.kyrgyz:
          'Ролдор жана колдонуу сценарийлери боюнча активдүүлүктү мониторинг кылуу',
    },
    'admin.analytics.roleBreakdown': {
      AppLanguage.russian: 'Распределение ролей',
      AppLanguage.kyrgyz: 'Ролдордун бөлүштүрүлүшү',
    },
    'admin.analytics.activity': {
      AppLanguage.russian: 'Проверенные сценарии',
      AppLanguage.kyrgyz: 'Текшерилген сценарийлер',
    },
    'admin.settings.title': {
      AppLanguage.russian: 'Системные настройки',
      AppLanguage.kyrgyz: 'Системалык жөндөөлөр',
    },
    'admin.settings.subtitle': {
      AppLanguage.russian:
          'Базовые параметры приложения и интерфейса для Кыргызстана',
      AppLanguage.kyrgyz:
          'Кыргызстан үчүн тиркеменин жана интерфейстин негизги параметрлери',
    },
    'admin.settings.kgRegion': {
      AppLanguage.russian: 'Регион по умолчанию: Кыргызстан',
      AppLanguage.kyrgyz: 'Демейки аймак: Кыргызстан',
    },
    'admin.database.title': {
      AppLanguage.russian: 'База данных',
      AppLanguage.kyrgyz: 'Маалымат базасы',
    },
    'admin.database.action': {
      AppLanguage.russian: 'Обновить',
      AppLanguage.kyrgyz: 'Жаңыртуу',
    },
  };

  String t(String key) {
    return _localizedValues[key]?[language] ??
        appLiteralLocalizations[key]?[language] ??
        key;
  }

  String format(String key, Map<String, String> values) {
    var text = t(key);
    values.forEach((name, value) {
      text = text.replaceAll('{$name}', t(value));
    });
    return text;
  }

  String role(UserRole role) {
    switch (role) {
      case UserRole.teacher:
        return t('role.teacher');
      case UserRole.student:
        return t('role.student');
      case UserRole.parent:
        return t('role.parent');
      case UserRole.admin:
        return t('role.admin');
    }
  }

  String languageLabel(AppLanguage value) {
    switch (value) {
      case AppLanguage.russian:
        return t('language.russian');
      case AppLanguage.kyrgyz:
        return t('language.kyrgyz');
    }
  }
}
