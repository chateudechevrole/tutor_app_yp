class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final int ts;
  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.ts,
  });
  factory ChatMessage.fromMap(String id, Map<String, dynamic> d) => ChatMessage(
    id: id,
    senderId: d['senderId'],
    text: d['text'] ?? '',
    ts: d['ts'] ?? 0,
  );
  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'text': text,
    'ts': ts,
  };
}
