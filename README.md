# Ripple — iOS Мессенджер

Мессенджер для iOS с обменом сообщениями в реальном времени. Написан на UIKit и Firebase.

## Стек технологий

- **UIKit** — вёрстка кодом, без Storyboards
- **MVVM + Coordinator** — навигация и бизнес-логика отделены от представлений
- **Firebase** — Auth, Firestore (real-time listeners), Cloud Messaging (push-уведомления)
- **Swift Concurrency** — `async/await`, `actor` для потокобезопасного кэша сообщений
- **Combine** — реактивная валидация форм, привязка данных
- **Kingfisher** — асинхронная загрузка изображений
- **SkeletonView** — плейсхолдеры при загрузке

## Функциональность

- Регистрация и вход по email
- Диалоги в реальном времени через Firestore listeners
- Индикатор печати
- Статус доставки сообщений (отправлено / доставлено / прочитано)
- Очередь офлайн-сообщений — отправляются автоматически при восстановлении сети
- Push-уведомления через FCM
- Аватары из инициалов с градиентным фоном
- Редактирование профиля

## Архитектура

```
App/
├── Coordinators       # Навигация (AppCoordinator → Auth / Conversations / Chat)
├── Features/          # Экраны (ViewController + ViewModel + Coordinator)
├── Services/          # Обёртки Firebase (Auth, Message, Conversation, Push)
├── Domain/            # Модели, MessageCache actor
└── Extensions/        # Хелперы UIKit (цвета, градиенты, алёрты)
```

Каждый модуль следует единому паттерну: `Coordinator` управляет навигацией, `ViewModel` — состоянием и логикой, `ViewController` — отображением и пробросом действий пользователя.

## Запуск

1. Создать проект в Firebase, включить **Authentication** (Email/Password) и **Firestore**
2. Скачать `GoogleService-Info.plist` и добавить в таргет `Ripple/`
3. Настроить правила Firestore для чтения/записи авторизованными пользователями
4. Открыть в Xcode 16+, собрать на iOS 16+

## Требования

- Xcode 16+
- iOS 16+
- Firebase-проект (бесплатный тариф Spark)
