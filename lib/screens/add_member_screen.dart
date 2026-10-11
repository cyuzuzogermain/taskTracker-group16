import 'package:flutter/material.dart';

import '../models/team_member.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

/// A short form for adding a new team member.
///
/// When the member is saved the screen closes and returns the new member.
class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  // Validation limits for both fields.
  static const int _minLength = 2;
  static const int _maxLength = 40;

  /// Lets the Save button run every field's validator at once.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();

  /// The members already saved, used to reject a duplicate name.
  List<TeamMember> _existingMembers = [];

  /// True while the member is being written to storage.
  bool _isSaving = false;

  /// Turned on after the first failed save, so errors update as the user
  /// fixes each field.
  bool _validateAsYouType = false;

  @override
  void initState() {
    super.initState();
    _loadExistingMembers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingMembers() async {
    final members = await StorageService().loadTeamMembers();

    if (!mounted) return;
    setState(() {
      _existingMembers = members;
    });
  }

  // ------------------------------------------------------------------
  // Validation rules. Each returns an error message, or null if valid.
  // ------------------------------------------------------------------

  String? _validateName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) {
      return 'Enter a name';
    }
    if (name.length < _minLength) {
      return 'Name must be at least $_minLength characters';
    }
    if (name.length > _maxLength) {
      return 'Name must be $_maxLength characters or fewer';
    }
    // Two members with the same name would be impossible to tell apart
    // in the assignee list.
    final alreadyExists = _existingMembers.any(
      (member) => member.name.toLowerCase() == name.toLowerCase(),
    );
    if (alreadyExists) {
      return 'A team member with this name already exists';
    }
    return null;
  }

  String? _validateRole(String? value) {
    final role = (value ?? '').trim();
    if (role.isEmpty) {
      return 'Enter a role';
    }
    if (role.length < _minLength) {
      return 'Role must be at least $_minLength characters';
    }
    if (role.length > _maxLength) {
      return 'Role must be $_maxLength characters or fewer';
    }
    return null;
  }

  /// Validates the form, saves the member to storage and closes the screen.
  Future<void> _save() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      setState(() {
        _validateAsYouType = true;
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final newMember = TeamMember(
      // The current time in milliseconds gives each member a unique id.
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      role: _roleController.text.trim(),
    );

    try {
      // Read the latest list, add the member, then write it back.
      final storage = StorageService();
      final members = await storage.loadTeamMembers();
      members.add(newMember);
      await storage.saveTeamMembers(members);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save the team member. Please try again.'),
        ),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${newMember.name} added to the team')),
    );
    // Hand the new member back to the screen that opened this form.
    Navigator.pop(context, newMember);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Team Member')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: _validateAsYouType
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  maxLength: _maxLength,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: _validateName,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _roleController,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    hintText: 'For example, Mobile Developer',
                  ),
                  maxLength: _maxLength,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  // Pressing Done on the keyboard saves, like the button.
                  onFieldSubmitted: (value) => _save(),
                  validator: _validateRole,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  // Disabled while saving so the member is not added twice.
                  onPressed: _isSaving ? null : _save,
                  child: const Text('Add member'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
