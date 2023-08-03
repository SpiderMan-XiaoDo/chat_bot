import 'package:flutter/foundation.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';

class SummarizeData {
  const SummarizeData({required this.conversation, required this.apiKey});
  final String apiKey;
  final List<Map<String, String>> conversation;

  String summarize() {
    final llm =
        OpenAI(apiKey: apiKey, model: 'gpt-3.5-turbo', temperature: 1.0);
    var memory = ConversationBufferMemory();
    conversation.forEach((element) {
      if (element.keys.first == 'user') {
        memory.chatHistory.addUserChatMessage(element.values.first);
      } else {
        memory.chatHistory.addAIChatMessage(element.values.first);
      }
    });
    var memory_buffer = memory.loadMemoryVariables();
    var chatData = '';
    memory_buffer.asStream().forEach((element) {
      chatData = chatData + element.values.first;
    });
    return chatData;
  }

  bufferMemory() {
    final llm =
        OpenAI(apiKey: apiKey, model: 'gpt-3.5-turbo', temperature: 1.0);
    var memory = ConversationBufferMemory();
    conversation.forEach((element) {
      if (element.keys.first == 'user') {
        memory.chatHistory.addUserChatMessage(element.values.first);
      } else {
        memory.chatHistory.addAIChatMessage(element.values.first);
      }
    });
    return memory;
  }
}
