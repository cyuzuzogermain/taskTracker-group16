import 'package:flutter/material.dart';
import 'package:task_tracker_app/models/team_member.dart';
import 'package:task_tracker_app/services/storage_service.dart';
import 'package:task_tracker_app/services/seed_data.dart';

class TeamMembersScreen extends StatefulWidget {
  const TeamMembersScreen({super.key});

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  final StorageService storage = StorageService();

  List<TeamMember> members = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMembers();
  }

 Future<void> loadMembers() async {
  await SeedData.seed(storage);

  final data = await storage.loadTeamMembers();

  if (!mounted) return;

  setState(() {
    members = data;
    isLoading = false;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Members'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : members.isEmpty
              ? const Center(
                  child: Text(
                    'No team members found',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(member.initials),
                        ),
                        title: Text(
                          member.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(member.role),
                      ),
                    );
                  },
                ),
    );
  }
}