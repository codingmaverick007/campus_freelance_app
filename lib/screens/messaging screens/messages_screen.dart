import 'package:campus_freelance_app/screens/messaging%20screens/chat_screen.dart';
import 'package:card_loading/card_loading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Conversations'),
        ),
        body: const ConversationsList(),
      ),
    );
  }
}

class ConversationsList extends StatelessWidget {
  const ConversationsList({super.key});

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: _getConversationsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("You don't have any conversations"));
        }

        var conversations = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            var conversationData = conversations[index];
            return ConversationItem(conversationData);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getConversationsStream(String uid) {
    return FirebaseFirestore.instance
        .collection('conversations')
        .where('members', arrayContains: uid)
        .snapshots();
  }
}

class ConversationItem extends StatelessWidget {
  final QueryDocumentSnapshot conversation;

  const ConversationItem(this.conversation, {super.key});

  @override
  Widget build(BuildContext context) {
    String receiverId =
        conversation['members'][0] == FirebaseAuth.instance.currentUser!.uid
            ? conversation['members'][1]
            : conversation['members'][0];

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(receiverId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // While waiting for the future to complete, show a loading card
          return ListTile(
            title: CardLoading(
              height: 20,
              width: 150,
              borderRadius: BorderRadius.circular(8),
              margin: const EdgeInsets.only(bottom: 8),
            ),
            leading: CardLoading(
              borderRadius: BorderRadius.circular(20),
              height: 40,
              width: 40,
            ),
          );
        }

        if (snapshot.hasError) {
          // If there's an error, display an error message
          return ListTile(
            title: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          // If data is not available or user document doesn't exist
          return const ListTile(
            title: Text('User not found'),
          );
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        return ListTile(
          title: Text(userData['fullName']),
          subtitle: LastMessage(conversation.id),
          leading: CircleAvatar(
            backgroundImage: NetworkImage(userData['profileImageUrl']),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  conversationId: conversation.id,
                  receiverId: receiverId,
                  receiverName: userData['fullName'],
                  receiverImage: userData['profileImageUrl'],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class LastMessage extends StatelessWidget {
  final String conversationId;

  const LastMessage(this.conversationId, {super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CardLoading(
            height: 20,
            width: 200,
            borderRadius: BorderRadius.circular(8),
            margin: const EdgeInsets.only(bottom: 8),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("No messages yet");
        }

        var lastMessage = snapshot.data!.docs.first;
        var isCurrentUser = lastMessage['senderID'] == currentUserId;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isCurrentUser)
                  const Icon(
                    Icons.send_outlined,
                    size: 12,
                    color: Colors.grey,
                  ),
                if (isCurrentUser)
                  const SizedBox(
                    width: 4,
                  ),
                Expanded(
                  child: Text(
                    lastMessage['message'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              timeago.format(lastMessage['timestamp'].toDate()),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        );
      },
    );
  }
}
