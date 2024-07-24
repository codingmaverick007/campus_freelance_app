import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_freelance_app/screens/freelancer_detail_screen.dart';
import 'package:campus_freelance_app/screens/job_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _searchTerm = '';
  bool _isSearching = false;
  List<QueryDocumentSnapshot> _searchResults = [];

  void _search() async {
    setState(() {
      _isSearching = true;
    });

    // Query jobs
    final jobQuery = FirebaseFirestore.instance.collection('jobs').get();

    // Query freelancers
    final freelancerQuery =
        FirebaseFirestore.instance.collection('users').get();

    final jobResults = await jobQuery;
    final freelancerResults = await freelancerQuery;

    final searchTermLower = _searchTerm.toLowerCase();

    setState(() {
      _isSearching = false;
      _searchResults = [
        ...jobResults.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['jobTitle']
              .toString()
              .toLowerCase()
              .contains(searchTermLower);
        }),
        ...freelancerResults.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['fullName']
                  .toString()
                  .toLowerCase()
                  .contains(searchTermLower) ||
              data['title'].toString().toLowerCase().contains(searchTermLower);
        })
      ].toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: InputDecoration(
            hintText: 'Search for jobs or freelancers...',
            suffixIcon: _searchTerm.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchTerm = '';
                        _searchResults.clear();
                      });
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {
              _searchTerm = value;
            });
          },
          onSubmitted: (value) {
            _search();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _search,
          ),
        ],
      ),
      body: _isSearching
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _searchResults.isEmpty
              ? const Center(child: Text('No results found'))
              : ListView.separated(
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    final data = result.data() as Map<String, dynamic>;

                    if (data.containsKey('jobTitle') &&
                        data.containsKey('jobDescription')) {
                      // Display job result
                      return ListTile(
                        leading: Icon(Icons.work),
                        title: Text(data['jobTitle'] ?? 'No Title'),
                        subtitle:
                            Text(data['jobDescription'] ?? 'No Description'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JobDetailScreen(
                                jobId: result.id,
                                job: result,
                                status: data['status'],
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      // Display freelancer result
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: data['profileImageUrl'] != null
                              ? NetworkImage(data['profileImageUrl'])
                              : AssetImage('assets/avatar.jpg')
                                  as ImageProvider,
                        ),
                        title: Text(data['fullName'] ?? 'No Name'),
                        subtitle:
                            Text(data['title'] ?? data['bio'] ?? 'No Bio'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FreelancerDetailScreen(
                                result.id, // Pass freelancerId here
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
    );
  }
}
