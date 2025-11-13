class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final int ts;
  final bool isRead;
  
  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.ts,
    this.isRead = false,
  });
  
  factory ChatMessage.fromMap(String id, Map<String, dynamic> d) => ChatMessage(
    id: id,
    senderId: d['senderId'] ?? '',
    senderName: d['senderName'] ?? 'User',
    text: d['text'] ?? '',
    ts: d['ts'] ?? 0,
    isRead: d['isRead'] ?? false,
  );
  
  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'senderName': senderName,
    'text': text,
    'ts': ts,
    'isRead': isRead,
  };
}
