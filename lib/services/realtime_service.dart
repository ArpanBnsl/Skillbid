import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class RealtimeService {
  /// Subscribe to real-time message updates
  RealtimeChannel subscribeToMessages(
    String chatId, {
    void Function(PostgresChangePayload payload)? onChange,
  }) {
    final channel = supabase.channel('public:messages');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'chat_id',
        value: chatId,
      ),
      callback: (payload) => onChange?.call(payload),
    );

    channel.subscribe();
    return channel;
  }

  /// Subscribe to chat updates
  RealtimeChannel subscribeToChats({
    void Function(PostgresChangePayload payload)? onChange,
  }) {
    final channel = supabase.channel('public:chats');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'chats',
      callback: (payload) => onChange?.call(payload),
    );

    channel.subscribe();
    return channel;
  }

  /// Unsubscribe from a channel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await supabase.removeChannel(channel);
  }
}
