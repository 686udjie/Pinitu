import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../parsers/pinterest_parser.dart';
import '../services/client_handler.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with ClientHandler {
  UserProfile? _profile;
  bool _loading = true;
  bool _bioExpanded = false;

  @override
  void initState() {
    super.initState();
    initializeClient().then((_) async {
      setState(() {});
      await _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final html = await client.fetchProfileHtml();
      _profile = PinterestParser.parseUserProfileFromHtml(html);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _doesTextOverflow(String text, TextStyle? style, double maxWidth, int maxLines, BuildContext context) {
    final textSpan = TextSpan(text: text, style: style ?? DefaultTextStyle.of(context).style);
    final tp = TextPainter(
      text: textSpan,
      maxLines: maxLines,
      textDirection: Directionality.of(context),
    );
    tp.layout(maxWidth: maxWidth);
    return tp.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized || _loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final name = _profile?.displayName ?? 'User';
    final username = _profile?.username != null ? '@${_profile!.username}' : '';
    final bio = (_profile?.bio ?? '').trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: _profile?.avatarUrl != null ? NetworkImage(_profile!.avatarUrl!) : null,
          child: _profile?.avatarUrl == null ? const Icon(Icons.person) : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              if (username.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(username, style: TextStyle(color: Colors.grey[600])),
                ),
              if (bio.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const maxLinesCollapsed = 3;
                      final style = Theme.of(context).textTheme.bodyMedium;
                      final hasOverflow = _doesTextOverflow(
                        bio,
                        style,
                        constraints.maxWidth,
                        maxLinesCollapsed,
                        context,
                      );

                      final showToggle = hasOverflow;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bio,
                            maxLines: _bioExpanded ? null : maxLinesCollapsed,
                            overflow: _bioExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                            style: style,
                          ),
                          if (showToggle)
                            GestureDetector(
                              onTap: () => setState(() => _bioExpanded = !_bioExpanded),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  _bioExpanded ? 'collapse' : 'more...',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        )
      ],
    );
  }
}
// TODO: refactor this huge slope, refactor the entire file