import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gourmet_snacks_app/widgets/chat_bubble.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String? userName;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    this.userName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // 3. Get Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 4. Controllers
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Mark as read when the screen is opened
    _markMessagesAsRead(); //
    // Listener to scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Part 2: "Mark as Read" Logic
  Future<void> _markMessagesAsRead() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Check if the current user is an admin (not the chatRoomId owner)
    final bool isAdmin = currentUser.uid != widget.chatRoomId;

    if (!isAdmin) {
      // If I am the USER opening this chat:
      await _firestore.collection('chats').doc(widget.chatRoomId).set({
        'unreadByUserCount': 0,
      }, SetOptions(merge: true));
    }
    else {
      // If I am the ADMIN opening this chat:
      await _firestore.collection('chats').doc(widget.chatRoomId).set({
        'unreadByAdminCount': 0, // Reset the admin's count
      }, SetOptions(merge: true));
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final String messageText = _messageController.text.trim();
    _messageController.clear();
    final timestamp = FieldValue.serverTimestamp();

    final bool isAdmin = currentUser.uid != widget.chatRoomId;

    try {
      // TASK 1: Save the message (to the 'messages' subcollection)
      await _firestore
          .collection('chats')
          .doc(widget.chatRoomId)
          .collection('messages')
          .add({
        'text': messageText,
        'createdAt': timestamp,
        'senderId': currentUser.uid,
        'senderEmail': currentUser.email,
      });

      // TASK 2: Update the Parent Doc & Unread Counts
      Map<String, dynamic> parentDocData = {};
      parentDocData['lastMessage'] = messageText;
      parentDocData['lastMessageAt'] = timestamp;

      // 1. If I am the USER sending:
      if (!isAdmin) { //
        parentDocData['userEmail'] = currentUser.email;
        // Increment the ADMIN's unread count
        parentDocData['unreadByAdminCount'] = FieldValue.increment(1);
        // Reset my own count since I'm sending a message
        parentDocData['unreadByUserCount'] = 0;
      }
      // 2. If I am the ADMIN sending:
      else { //
        // Increment the USER's unread count
        parentDocData['unreadByUserCount'] = FieldValue.increment(1);
        // Reset my own count since I'm sending a message
        parentDocData['unreadByAdminCount'] = 0;
      }

      await _firestore
          .collection('chats')
          .doc(widget.chatRoomId)
          .set(parentDocData, SetOptions(merge: true));

      // TASK 3: Scroll to bottom
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  // Part 4: The build Method (UI)
  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    void _scrollToBottom() {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(

        title: Text(widget.userName ?? 'Contact Admin'), //
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator()); //
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}')); //
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Say hello!')); //
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                final messages = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index].data() as Map<String, dynamic>;

                    return ChatBubble(
                      message: messageData['text'] ?? '',
                      // Check if sender is the current user
                      isCurrentUser: messageData['senderId'] == currentUser!.uid,
                    );
                  },
                );
              },
            ),
          ),

          // The Text Input Field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}