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

  /// Subscribe to real-time bid updates for a specific job
  RealtimeChannel subscribeToBids(
    String jobId, {
    void Function(PostgresChangePayload payload)? onChange,
  }) {
    final channel = supabase.channel('public:bids:$jobId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'bids',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'job_id',
        value: jobId,
      ),
      callback: (payload) => onChange?.call(payload),
    );

    channel.subscribe();
    return channel;
  }

  /// Subscribe to contract location updates (for live tracking)
  RealtimeChannel subscribeToContractUpdates(
    String contractId, {
    void Function(PostgresChangePayload payload)? onChange,
  }) {
    final channel = supabase.channel('public:contracts:$contractId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'contracts',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: contractId,
      ),
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
