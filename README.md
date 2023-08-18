# chat_bot

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

***************************************
  <div style="flex: 2;">
    <p>Chatbot, an innovative AI-driven chat application designed to revolutionize the way you engage in conversations. Crafted using cutting-edge Flutter technology and coded in Dart, Chatbot harnesses the power of OpenAI's advanced GPT technology, redefining natural language processing for a seamless and captivating experience.</p>
  </div>
</div>

## Features

* Advanced AI-powered writing assistance
* Beautiful and intuitive UI
* Chat and Summarize conversation.

## Screenshots

|Returned user Screen                          | New user Screen                              | Chat Screen                |
|----------------------------------------------|----------------------------------------------|----------------------------------------------|
| ![Screenshot_1691564306](https://github.com/SpiderMan-XiaoDo/chat_bot/assets/90297125/1d95b446-e567-4069-addf-b847f8dd28ce) |![Screenshot_1691564355](https://github.com/SpiderMan-XiaoDo/chat_bot/assets/90297125/6d52d8fd-c9a9-4c37-81b9-acf9a42e8025)|![Screenshot_1691564461](https://github.com/SpiderMan-XiaoDo/chat_bot/assets/90297125/7afd5291-1fe0-4540-87e8-cf7e189925a5)|
 | Chat History                                |    Summarize Screen                          | Summarize Screen        |
|----------------------------------------------|----------------------------------------------|----------------------------------------------|
|![Screenshot_1691564562](https://github.com/SpiderMan-XiaoDo/chat_bot/assets/90297125/ae3bda2a-4abb-4da4-a4a0-98c40f528d5d)|![Screenshot_1691564952](https://github.com/SpiderMan-XiaoDo/chat_bot/assets/90297125/1c3d14b5-6549-42ee-805e-2d94efa9cdaf)|![Screenshot_1691564650](https://github.com/SpiderMan-XiaoDo/chat_bot/assets/90297125/b6ec9a36-2999-442b-b897-17780e916e10)|

## Installation

You can download this repository from source using the
instructions below:

```bash
git clone https://github.com/SpiderMan-XiaoDo/chat_bot.git
cd chat_bot
````
After download this repository, you mus config your firebase to save your data:
  Delete file [firebase_options.dart] in lib folder.

To use npm (the Node Package Manager) to install the Firebase CLI, follow these steps:
  1. Install [Node.js](https://nodejs.org/en) using [nvm](https://github.com/nvm-sh/nvm/blob/master/README.md) (the Node Version Manager).
Installing Node.js automatically installs the npm command tools.
  2. Install the Firebase CLI via npm by running the following command:
```bash
npm install -g firebase-tools
````
Log in and test the Firebase CLI:
  1. Log into Firebase using your Google account by running the following command:
```bash
firebase login
````
  This command connects your local machine to Firebase and grants you access to your Firebase projects.
  2. Install the FlutterFire CLI by running the following command from any directory:
```bash
dart pub global activate flutterfire_cli
````
  3. Config your app to use flutter:
```bash
flutterfire configure
````
Then, you could delete my Realtime Database url, and paste your Realtime Database url in 4 files: [home_screen.dart], [new_home_screen.dart], [returned_home_screen.dart], [tab_screen.dart].
  1. Find this code below:
````bash
final url = Uri.https(
        'chat-bot-api-ffdeb-default-rtdb.asia-southeast1.firebasedatabase.app',
        'openai-key.json');
```` 
  2. Change this line  'chat-bot-api-ffdeb-default-rtdb.asia-southeast1.firebasedatabase.app' with your Realtime Database url.
<img width="824" alt="image" src="https://github.com/SpiderMan-XiaoDo/chat_bot/assets/90297125/6315f323-42ef-408e-a743-e0ea2336333c">

Change the 'Rules' in Firestore Database :
<img width="935" alt="image" src="https://github.com/SpiderMan-XiaoDo/chat_bot/assets/90297125/c54a01ec-7e84-444a-8604-d5bcfe991663">

Change this code:
````bash
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
````
To this code:
````bash
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
````
Change the 'Rules' in RealTime DataBase:
````bash
{
  "rules": {
    ".read": "true",  // 2023-8-19
    ".write": "true",  // 2023-8-19
  }
}
````
<img width="922" alt="image" src="https://github.com/SpiderMan-XiaoDo/chat_bot/assets/90297125/e516e133-c39a-46c4-ae74-586c88c4cc10">


## Acknowledgements

chat_bot was built using the following open-source libraries and tools:

* [Flutter](https://flutter.dev/)
* [Dart](https://dart.dev/)
* [Dart openAi](https://pub.dev/packages/dart_openai)
* [Text To Speech](https://pub.dev/packages/flutter_tts)
* [Speech To Text](https://pub.dev/packages/speech_to_text)
* [LangChain](https://pub.dev/packages/langchain)
* [LangChain OpenAI](https://pub.dev/packages/langchain_openai/versions)
* [File Picker](https://pub.dev/packages/file_picker)
* 



