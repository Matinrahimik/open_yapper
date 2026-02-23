import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../services/user_profile_service.dart';
import '../widgets/pasteable_text_field.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key, required this.userProfileService});

  final UserProfileService userProfileService;

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  final _websiteController = TextEditingController();
  final _twitterController = TextEditingController();
  final _instagramController = TextEditingController();
  final _customAliasKeyController = TextEditingController();
  final _customAliasValueController = TextEditingController();

  Map<String, String> _customFields = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    _websiteController.dispose();
    _twitterController.dispose();
    _instagramController.dispose();
    _customAliasKeyController.dispose();
    _customAliasValueController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final profile = await widget.userProfileService.loadProfile();
    if (!mounted) return;
    setState(() {
      _nameController.text = profile.fullName;
      _emailController.text = profile.email;
      _phoneController.text = profile.phone;
      _linkedinController.text = profile.linkedin;
      _githubController.text = profile.github;
      _websiteController.text = profile.website;
      _twitterController.text = profile.twitter;
      _instagramController.text = profile.instagram;
      _customFields = Map<String, String>.from(profile.customFields);
      _loaded = true;
    });
  }

  Future<void> _save() async {
    final profile = UserProfile(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      linkedin: _linkedinController.text.trim(),
      github: _githubController.text.trim(),
      website: _websiteController.text.trim(),
      twitter: _twitterController.text.trim(),
      instagram: _instagramController.text.trim(),
      customFields: _customFields,
    );
    await widget.userProfileService.saveProfile(profile);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('User info saved')));
  }

  void _addCustomAlias() {
    final key = _customAliasKeyController.text.trim().toLowerCase();
    final value = _customAliasValueController.text.trim();
    if (key.isEmpty || value.isEmpty) return;
    setState(() {
      _customFields[key] = value;
      _customAliasKeyController.clear();
      _customAliasValueController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final previewAliases = UserProfile(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      linkedin: _linkedinController.text.trim(),
      github: _githubController.text.trim(),
      website: _websiteController.text.trim(),
      twitter: _twitterController.text.trim(),
      instagram: _instagramController.text.trim(),
      customFields: _customFields,
    ).aliasMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        Text('User Info', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text(
          'Configure personal values so phrases like "my email" and "my phone" paste the real value automatically.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Profile fields',
          icon: Symbols.person,
          child: Column(
            children: [
              _Field(controller: _nameController, label: 'Name'),
              const SizedBox(height: 10),
              _Field(controller: _emailController, label: 'Email'),
              const SizedBox(height: 10),
              _Field(controller: _phoneController, label: 'Phone'),
              const SizedBox(height: 10),
              _Field(controller: _linkedinController, label: 'LinkedIn'),
              const SizedBox(height: 10),
              _Field(controller: _githubController, label: 'GitHub'),
              const SizedBox(height: 10),
              _Field(controller: _websiteController, label: 'Website'),
              const SizedBox(height: 10),
              _Field(controller: _twitterController, label: 'Twitter / X'),
              const SizedBox(height: 10),
              _Field(controller: _instagramController, label: 'Instagram'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Custom aliases',
          icon: Symbols.short_text,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      controller: _customAliasKeyController,
                      label: 'Spoken phrase (e.g. my portfolio)',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Field(
                      controller: _customAliasValueController,
                      label: 'Replacement value',
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _addCustomAlias,
                    icon: const Icon(Symbols.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_customFields.isEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No custom aliases yet.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ..._customFields.entries.map(
                  (entry) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.key),
                    subtitle: Text(entry.value),
                    trailing: IconButton(
                      icon: const Icon(Symbols.delete_outline),
                      onPressed: () {
                        setState(() => _customFields.remove(entry.key));
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          title: 'Alias preview',
          icon: Symbols.preview,
          child: Column(
            children: [
              if (previewAliases.isEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No aliases available yet. Fill profile fields to generate them.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...previewAliases.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '→ ${entry.value}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Symbols.save, size: 18),
            label: const Text('Save user info'),
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return PasteableTextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
