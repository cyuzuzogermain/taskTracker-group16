import 'package:flutter/material.dart';

import '../models/team_member.dart';
import '../services/seed_data.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/member_avatar.dart';

/// The first screen of the app: the user picks which team member they are.
///
/// There is no password. The chosen member is handed back through
/// [onSignedIn], and the caller decides what happens next.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.onSignedIn});

  /// Called with the chosen member when Continue is pressed.
  final void Function(TeamMember member) onSignedIn;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  List<TeamMember> _members = [];

  /// True while the member list is being read from storage.
  bool _isLoading = true;

  /// True if reading the member list failed.
  bool _loadFailed = false;

  /// The id of the member the user has tapped, or null if none yet.
  String? _selectedMemberId;

  /// True after Continue was pressed with nobody selected.
  bool _showSelectionError = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  /// Reads the team members from storage. On the very first launch storage
  /// is empty, so the sample data is added first.
  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });

    try {
      final storage = StorageService();
      await SeedData.seed(storage);
      final members = await storage.loadTeamMembers();

      if (!mounted) return;
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  /// Marks a member as selected and clears any earlier error message.
  void _selectMember(TeamMember member) {
    setState(() {
      _selectedMemberId = member.id;
      _showSelectionError = false;
    });
  }

  /// Validates that someone is selected, then signs them in.
  void _continue() {
    if (_selectedMemberId == null) {
      setState(() {
        _showSelectionError = true;
      });
      return;
    }

    final member = _members.firstWhere((m) => m.id == _selectedMemberId);
    widget.onSignedIn(member);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              _buildHeader(context),
              const SizedBox(height: AppSpacing.lg),
              // Expanded gives the list all the space between the header
              // and the button, and lets it scroll if there are many members.
              Expanded(child: _buildBody(context)),
              if (_showSelectionError) _buildSelectionError(context),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                // The button is disabled until there is someone to choose.
                onPressed: _members.isEmpty ? null : _continue,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.task_alt_outlined, size: 40, color: AppColors.primary),
        const SizedBox(height: AppSpacing.md),
        Text('Project & SLA Task Tracker', style: textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Choose who you are to continue.',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Shows a spinner, an error, an empty message or the member list,
  /// depending on the current state.
  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadFailed) {
      return _buildMessage(
        context,
        icon: Icons.error_outline,
        message: 'Could not load the team. Please try again.',
        showRetry: true,
      );
    }

    if (_members.isEmpty) {
      return _buildMessage(
        context,
        icon: Icons.group_outlined,
        message: 'No team members found.',
        showRetry: true,
      );
    }

    return ListView.separated(
      itemCount: _members.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final member = _members[index];
        return _MemberOption(
          member: member,
          isSelected: member.id == _selectedMemberId,
          onTap: () => _selectMember(member),
        );
      },
    );
  }

  Widget _buildMessage(
    BuildContext context, {
    required IconData icon,
    required String message,
    required bool showRetry,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (showRetry) ...[
            const SizedBox(height: AppSpacing.xs),
            TextButton(onPressed: _loadMembers, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectionError(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 20, color: AppColors.error),
          const SizedBox(width: AppSpacing.xs),
          // Expanded lets the message wrap on narrow screens.
          Expanded(
            child: Text(
              'Select a team member to continue.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One selectable row in the member list.
class _MemberOption extends StatelessWidget {
  const _MemberOption({
    required this.member,
    required this.isSelected,
    required this.onTap,
  });

  final TeamMember member;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      // The selected row gets a thicker navy border.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              MemberAvatar(member: member),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(member.role, style: textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.borderStrong,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
