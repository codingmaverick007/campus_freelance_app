import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String receiverId;
  final String receiverName;
  final String receiverImage;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.receiverId,
    required this.receiverName,
    required this.receiverImage,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  double _deviceHeight = 0;
  double _deviceWidth = 0;
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ScrollController _listViewController = ScrollController();
  final Map<String, String> _userImageUrlCache = {};
  bool _isSending = false;
  List<DocumentSnapshot> _messages = [];

  @override
  void dispose() {
    _messageController.dispose();
    _listViewController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    await FirebaseMessaging.instance.requestPermission();
  }

  void _sendMessage() {
    if (_isSending) return; // Prevent multiple sends

    String text = _messageController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _isSending = true;
      });
      String senderID = FirebaseAuth.instance.currentUser!.uid;
      String conversationId = widget.conversationId;

      var message = {
        'message': text,
        'senderID': senderID,
        'timestamp': Timestamp.now(),
        'type': 'text'
      };

      FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add(message)
          .then((_) async {
        _messageController.clear();
        _listViewController
            .jumpTo(_listViewController.position.minScrollExtent);
        setState(() {
          _isSending = false;
        });
      }).catchError((error) {
        print('Failed to send message: $error');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to send message'),
        ));
        setState(() {
          _isSending = false;
        });
      });
    }
  }

  Future<void> _sendAttachment(File file) async {
    setState(() {
      _isSending = true;
    });

    String fileName = path.basename(file.path);
    String senderID = FirebaseAuth.instance.currentUser!.uid;
    String conversationId = widget.conversationId;

    UploadTask uploadTask = FirebaseStorage.instance
        .ref()
        .child('chat_attachments')
        .child(conversationId)
        .child(fileName)
        .putFile(file);

    TaskSnapshot snapshot = await uploadTask;

    String downloadUrl = await snapshot.ref.getDownloadURL();

    var message = {
      'message': downloadUrl,
      'senderID': senderID,
      'timestamp': Timestamp.now(),
      'type': 'attachment',
      'fileName': fileName,
    };

    FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(message)
        .then((_) {
      setState(() {
        _isSending = false;
      });
    }).catchError((error) {
      print('Failed to send attachment: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to send attachment'),
      ));
      setState(() {
        _isSending = false;
      });
    });
  }

  Future<String> _getUserImageUrl(String userId) async {
    if (_userImageUrlCache.containsKey(userId)) {
      return _userImageUrlCache[userId]!;
    } else {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      var imageUrl = userDoc['profileImageUrl'] ?? '';
      _userImageUrlCache[userId] = imageUrl;
      return imageUrl;
    }
  }

  Future<void> _pickAttachment() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      File file = File(result.files.single.path!);
      await _sendAttachment(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    _deviceHeight = MediaQuery.of(context).size.height;
    _deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _messageListView(),
            _messageInputField(),
          ],
        ),
      ),
    );
  }

  Widget _messageListView() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('conversations')
            .doc(widget.conversationId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.hasData) {
            _messages = snapshot.data!.docs;
          }

          if (_messages.isEmpty) {
            return Center(child: Text("Let's start a conversation!"));
          }

          return ListView.builder(
            reverse: true,
            controller: _listViewController,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              var messageData = _messages[index].data() as Map<String, dynamic>;
              bool isMe = messageData['senderID'] ==
                  FirebaseAuth.instance.currentUser!.uid;
              return FutureBuilder<String>(
                future: _getUserImageUrl(messageData['senderID']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      !snapshot.hasError) {
                    return _messageBubble(
                        isMe, messageData, snapshot.data ?? '');
                  } else {
                    return _messageBubble(isMe, messageData, '');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _messageBubble(
      bool isOwnMessage, Map<String, dynamic> message, String senderImageUrl) {
    var timestamp = message['timestamp'] as Timestamp?;
    var messageContent = message['message'];
    bool isAttachment = message['type'] == 'attachment';
    String formattedTime = timestamp != null
        ? DateFormat('hh:mm a').format(timestamp.toDate())
        : 'Sending...';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment:
            isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: <Widget>[
          if (!isOwnMessage) _userImageWidget(senderImageUrl),
          SizedBox(width: _deviceWidth * 0.02),
          isAttachment
              ? _attachmentMessageBubble(isOwnMessage, messageContent,
                  formattedTime, message['fileName'])
              : _textMessageBubble(isOwnMessage, messageContent, formattedTime),
          SizedBox(width: _deviceWidth * 0.02),
          if (isOwnMessage) _userImageWidget(senderImageUrl),
        ],
      ),
    );
  }

  Widget _userImageWidget(String imageUrl) {
    double _imageRadius = _deviceHeight * 0.04; // Smaller image size
    return Container(
      height: _imageRadius,
      width: _imageRadius,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(500),
        image: DecorationImage(
          fit: BoxFit.cover,
          image: imageUrl.isNotEmpty
              ? NetworkImage(imageUrl)
              : const AssetImage('assets/avatar.png') as ImageProvider,
        ),
      ),
    );
  }

  Widget _textMessageBubble(
      bool isOwnMessage, String message, String formattedTime) {
    Color _colorScheme = isOwnMessage ? Colors.blue : Colors.grey;

    return Container(
      constraints: BoxConstraints(
        maxWidth: _deviceWidth * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: _colorScheme,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            message,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          SizedBox(height: 4),
          Text(
            formattedTime,
            style: TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _attachmentMessageBubble(
      bool isOwnMessage, String url, String formattedTime, String fileName) {
    Color _colorScheme = isOwnMessage ? Colors.blue : Colors.grey;

    return Container(
      constraints: BoxConstraints(
        maxWidth: _deviceWidth * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: _colorScheme,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onTap: () {
              // Code to open the attachment
            },
            child: Text(
              fileName,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          SizedBox(height: 4),
          Text(
            formattedTime,
            style: TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _messageInputField() {
    return Container(
      height: _deviceHeight * 0.08,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
      ),
      margin: EdgeInsets.symmetric(
          horizontal: _deviceWidth * 0.04, vertical: _deviceHeight * 0.02),
      child: Form(
        key: _formKey,
        child: Row(
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.attachment, color: Colors.black),
              onPressed: _pickAttachment,
            ),
            Expanded(
              child: TextFormField(
                controller: _messageController,
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Please enter a message";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  hintText: "Type a message...",
                  contentPadding: EdgeInsets.symmetric(horizontal: 20),
                ),
                autocorrect: false,
              ),
            ),
            IconButton(
              icon: _isSending
                  ? CircularProgressIndicator(strokeWidth: 2)
                  : Icon(Icons.send, color: Colors.black),
              onPressed: _isSending
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        _sendMessage();
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
