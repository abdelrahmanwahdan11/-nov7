import 'package:flutter/material.dart';

import '../../data/models/profile.dart';

class ProfileSwitcher extends StatelessWidget {
  const ProfileSwitcher({
    super.key,
    required this.profiles,
    required this.activeProfileId,
    this.onSelect,
  });

  final List<Profile> profiles;
  final String? activeProfileId;
  final ValueChanged<Profile>? onSelect;

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) {
      return const SizedBox.shrink();
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        final selected = profile.id == activeProfileId;
        final initial = profile.name.isNotEmpty ? profile.name[0] : '?';
        return ListTile(
          leading: CircleAvatar(child: Text(initial.toUpperCase())),
          title: Text(profile.name),
          subtitle: Text('Last active: ${profile.lastActive.toLocal()}'),
          trailing: selected ? const Icon(Icons.check) : null,
          onTap: () => onSelect?.call(profile),
        );
      },
    );
  }
}
