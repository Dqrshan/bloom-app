import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bloom/services/ai_service.dart';
import 'package:bloom/services/bloom_provider.dart';
import 'package:bloom/services/database_service.dart';
import 'package:bloom/models/chat_message.dart';

void main() {
  late String testDbPath;
  late BloomProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'bloom_device_id': 'testdevice123',
      'bloom_pairing_code': 'K8Y4B2',
      'bloom_server_url': 'ws://localhost:3000',
      'bloom_ai_api_key': AIService.defaultApiKey,
      'bloom_ai_model': AIService.defaultModel,
    });
    testDbPath = '${Directory.systemTemp.path}/test_bloom_ai_chat_${DateTime.now().microsecondsSinceEpoch}.json';
    DatabaseService.setCustomPath(testDbPath);
    provider = BloomProvider();
    await provider.loadData();
  });

  tearDown(() async {
    final file = File(testDbPath);
    if (await file.exists()) {
      await file.delete();
    }
  });

  group('AIService Unit Tests', () {
    test('AIService initializes with default key and model', () async {
      final ai = AIService();
      await ai.init();

      expect(ai.apiKey, equals(AIService.defaultApiKey));
      expect(ai.model, equals(AIService.defaultModel));
    });

    test('AIService allows updating API key and model', () async {
      final ai = AIService();
      await ai.init();

      await ai.setApiKey('custom-key-12345');
      expect(ai.apiKey, equals('custom-key-12345'));

      await ai.setModel('meta/llama-3.2-90b-vision-instruct');
      expect(ai.model, equals('meta/llama-3.2-90b-vision-instruct'));
    });
  });

  group('Bloom AI Chat CRUD & History Tests', () {
    test('createConversation creates and selects a new conversation', () async {
      expect(provider.conversations, isEmpty);

      final conv = await provider.createConversation(initialTitle: 'Hormone Guide');
      expect(provider.conversations.length, equals(1));
      expect(provider.currentConversation?.id, equals(conv.id));
      expect(provider.currentConversation?.title, equals('Hormone Guide'));
    });

    test('renameConversation updates conversation title', () async {
      final conv = await provider.createConversation(initialTitle: 'Initial Title');
      await provider.renameConversation(conv.id, 'Renamed Health Chat');

      expect(provider.currentConversation?.title, equals('Renamed Health Chat'));
      final stored = await DatabaseService().getConversationById(conv.id);
      expect(stored?.title, equals('Renamed Health Chat'));
    });

    test('deleteConversation removes conversation and updates active selection', () async {
      final conv1 = await provider.createConversation(initialTitle: 'Chat 1');
      final conv2 = await provider.createConversation(initialTitle: 'Chat 2');
      expect(provider.conversations.length, equals(2));

      await provider.deleteConversation(conv2.id);
      expect(provider.conversations.length, equals(1));
      expect(provider.conversations.first.id, equals(conv1.id));
    });

    test('deleteChatMessage removes specific message from conversation', () async {
      final conv = await provider.createConversation(initialTitle: 'Chat with Messages');
      final msg1 = ChatMessage(id: 'm1', text: 'Hello', isUser: true, timestamp: DateTime.now());
      final msg2 = ChatMessage(id: 'm2', text: 'Hi there', isUser: false, timestamp: DateTime.now());

      await DatabaseService().saveConversation(conv.copyWith(messages: [msg1, msg2]));
      await provider.loadData();
      await provider.selectConversation(conv.id);

      expect(provider.currentConversation?.messages.length, equals(2));

      await provider.deleteChatMessage(conv.id, 'm1');
      expect(provider.currentConversation?.messages.length, equals(1));
      expect(provider.currentConversation?.messages.first.id, equals('m2'));
    });

    test('clearAllConversations deletes all chat history', () async {
      await provider.createConversation(initialTitle: 'Chat 1');
      await provider.createConversation(initialTitle: 'Chat 2');
      expect(provider.conversations.length, equals(2));

      await provider.clearAllConversations();
      expect(provider.conversations, isEmpty);
      expect(provider.currentConversation, isNull);
    });
  });
}
