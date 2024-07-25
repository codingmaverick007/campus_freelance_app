import 'package:campus_freelance_app/screens/messaging%20screens/chat_screen.dart';
import 'package:campus_freelance_app/widgets/sliver_app_bar.dart';
import 'package:card_loading/card_loading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:async';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  _ConversationsScreenState createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  String _searchQuery = '';
  Timer? _debounce;
  String profileImageUrl = 'assets/avatar.png';

  @override
  void initState() {
    super.initState();
    _fetchProfileImageUrl();
  }

  Future<void> _fetchProfileImageUrl() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            profileImageUrl =
                userData['profileImageUrl'] ?? 'assets/avatar.png';
          });
        }
      } catch (e) {
        // Handle errors if needed
        print('Error fetching profile image URL: $e');
      }
    }
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {}); // Trigger rebuild with updated search query
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverPersistentHeader(
            delegate: SliverSearchAppBar(
              maxHeight: 180,
              minHeight: 100,
              searchBar: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _searchField(),
              ),
              profileImageUrl: profileImageUrl,
              onSuffixIconTap: () {
                // Handle the suffix icon tap
              },
            ),
            pinned: true,
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _getConversationsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('Error: ${snapshot.error}')),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverFillRemaining(
                  child:
                      Center(child: Text("You don't have any conversations")),
                );
              }

              var conversations = snapshot.data!.docs;
              return FutureBuilder<List<ConversationItemData>>(
                future: _getFilteredConversations(conversations),
                builder: (context, futureSnapshot) {
                  if (futureSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (futureSnapshot.hasError) {
                    return SliverFillRemaining(
                      child:
                          Center(child: Text('Error: ${futureSnapshot.error}')),
                    );
                  }

                  if (!futureSnapshot.hasData || futureSnapshot.data!.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(child: Text("No results found")),
                    );
                  }

                  var filteredConversations = futureSnapshot.data!;
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        var conversationData = filteredConversations[index];
                        return ConversationItem(conversationData);
                      },
                      childCount: filteredConversations.length,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return TextFormField(
      onChanged: _updateSearchQuery,
      decoration: InputDecoration(
        hintText: 'Search by name',
        fillColor: Colors.white,
        filled: true,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getConversationsStream() {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('conversations')
        .where('members', arrayContains: userId)
        .snapshots();
  }

  Future<List<ConversationItemData>> _getFilteredConversations(
      List<QueryDocumentSnapshot> conversations) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    List<ConversationItemData> filteredConversations = [];

    for (var conversation in conversations) {
      String receiverId = conversation['members'][0] == userId
          ? conversation['members'][1]
          : conversation['members'][0];

      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .get();
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        String fullName = userData['fullName'].toLowerCase();

        if (fullName.contains(_searchQuery)) {
          filteredConversations
              .add(ConversationItemData(conversation, userData));
        }
      }
    }

    return filteredConversations;
  }
}

class ConversationItemData {
  final QueryDocumentSnapshot conversation;
  final Map<String, dynamic> userData;

  ConversationItemData(this.conversation, this.userData);
}

class ConversationItem extends StatelessWidget {
  final ConversationItemData conversationItemData;

  const ConversationItem(this.conversationItemData, {super.key});

  @override
  Widget build(BuildContext context) {
    String receiverId = conversationItemData.conversation['members'][0] ==
            FirebaseAuth.instance.currentUser!.uid
        ? conversationItemData.conversation['members'][1]
        : conversationItemData.conversation['members'][0];

    return ListTile(
      title: Text(conversationItemData.userData['fullName']),
      subtitle: LastMessage(conversationItemData.conversation.id),
      leading: CircleAvatar(
        backgroundImage:
            conversationItemData.userData['profileImageUrl'] != null
                ? NetworkImage(conversationItemData.userData['profileImageUrl'])
                : AssetImage('assets/avatar.png') as ImageProvider,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversationItemData.conversation.id,
              receiverId: receiverId,
              receiverName: conversationItemData.userData['fullName'],
              receiverImage: conversationItemData.userData['profileImageUrl'] ??
                  'assets/avatar.png',
            ),
          ),
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
