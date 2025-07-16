import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  // Dynamic color system that adapts to dark/light mode - matching dashboard
  Color get backgroundColor {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF121212)
        : const Color(0xFFF2F7FF);
  }

  Color get lightColor {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFD7EAFF);
  }

  Color get darkColor {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFFB3C5D7)
        : const Color(0xFF477BA5);
  }

  Color get userSelectedColor {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF3D5A80)
        : const Color(0xFFAAD6FF);
  }

  Color get highContrastBlue {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF4FC3F7)
        : const Color(0xFF00AFEC);
  }

  Color get highContrastDarkBlue {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFFE3F2FD)
        : const Color(0xFF001A27);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // M3 Compact App Bar
          SliverAppBar(
            floating: false,
            pinned: true,
            snap: false,
            elevation: 0,
            surfaceTintColor: lightColor,
            backgroundColor: backgroundColor,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: highContrastDarkBlue,
                size: 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // M3 Expressive About Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // M3 App Info Section (without container)
                _buildM3AppInfoContent(),
                const SizedBox(height: 32),

                // M3 About Section (without container)
                Text(
                  'About the App',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: highContrastDarkBlue,
                  ),
                ),
                const SizedBox(height: 20),
                _buildM3AboutContent(),
                const SizedBox(height: 32),

                // M3 Features Section with Stacked Cards
                Text(
                  'Key Features',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: highContrastDarkBlue,
                  ),
                ),
                const SizedBox(height: 20),
                _buildM3FeaturesSection(),
                const SizedBox(height: 32),

                // M3 Developer & Privacy Section with Stacked Cards
                Text(
                  'Developer & Privacy',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: highContrastDarkBlue,
                  ),
                ),
                const SizedBox(height: 20),
                _buildM3LinksSection(),

                SizedBox(height: 32 + MediaQuery.of(context).padding.bottom),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildM3AppInfoContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // M3 Expressive App Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [highContrastBlue, userSelectedColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: highContrastBlue.withAlpha(60),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Payables',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: highContrastDarkBlue,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: highContrastBlue.withAlpha(31),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Version 0.0.1',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: highContrastBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildM3AboutContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        'Payables is your personal subscription management app that helps you track, manage, and stay on top of all your recurring payments and subscriptions with intelligent insights and beautiful design.',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: darkColor,
          height: 1.6,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildM3FeaturesSection() {
    final features = [
      {
        'title': 'Track Payables',
        'subtitle': 'Monitor all your recurring payments in one place',
        'icon': Icons.subscriptions_rounded,
        'color': highContrastBlue,
      },
      {
        'title': 'Smart Reminders',
        'subtitle': 'Never miss a payment with intelligent notifications',
        'icon': Icons.notifications_active_rounded,
        'color': userSelectedColor,
      },
      {
        'title': 'Spending Insights',
        'subtitle': 'Analyze your spending patterns and trends',
        'icon': Icons.analytics_rounded,
        'color': darkColor,
      },
      {
        'title': 'Data Management',
        'subtitle': 'Backup and export your subscription data securely',
        'icon': Icons.backup_rounded,
        'color': highContrastBlue,
      },
    ];

    return Column(
      children: [
        for (int i = 0; i < features.length; i++) ...[
          _buildM3FeatureCard(
            features[i]['title'] as String,
            features[i]['subtitle'] as String,
            features[i]['icon'] as IconData,
            features[i]['color'] as Color,
            index: i,
            isLast: i == features.length - 1,
          ),
          if (i < features.length - 1) const SizedBox(height: 2),
        ],
      ],
    );
  }

  Widget _buildM3FeatureCard(
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    required int index,
    required bool isLast,
  }) {
    // Determine border radius based on position - matching dashboard pattern
    BorderRadius borderRadius;
    if (index == 0) {
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
        bottomLeft: Radius.circular(5),
        bottomRight: Radius.circular(5),
      );
    } else if (isLast) {
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(5),
        topRight: Radius.circular(5),
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      );
    } else {
      borderRadius = BorderRadius.circular(5);
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: lightColor.withAlpha(150),
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(41),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: highContrastDarkBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: darkColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildM3LinksSection() {
    final links = [
      {
        'title': 'Contact Developer',
        'icon': Icons.email_rounded,
        'color': highContrastBlue,
        'action': () => _launchEmail(),
      },
      {
        'title': 'Privacy Policy',
        'icon': Icons.privacy_tip_rounded,
        'color': userSelectedColor,
        'action': () => _launchPrivacyPolicy(),
      },
      {
        'title': 'Terms of Service',
        'icon': Icons.description_rounded,
        'color': darkColor,
        'action': () => _launchTermsOfService(),
      },
    ];

    return Column(
      children: [
        for (int i = 0; i < links.length; i++) ...[
          _buildM3LinkCard(
            links[i]['title'] as String,
            links[i]['icon'] as IconData,
            links[i]['color'] as Color,
            links[i]['action'] as VoidCallback,
            index: i,
            isLast: i == links.length - 1,
          ),
          if (i < links.length - 1) const SizedBox(height: 2),
        ],
      ],
    );
  }

  Widget _buildM3LinkCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    required int index,
    required bool isLast,
  }) {
    // Determine border radius based on position - matching dashboard pattern
    BorderRadius borderRadius;
    if (index == 0) {
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
        bottomLeft: Radius.circular(5),
        bottomRight: Radius.circular(5),
      );
    } else if (isLast) {
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(5),
        topRight: Radius.circular(5),
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      );
    } else {
      borderRadius = BorderRadius.circular(5);
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: lightColor.withAlpha(150),
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: color.withAlpha(31),
        highlightColor: color.withAlpha(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(41),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: highContrastDarkBlue,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Link handlers
  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'developer@payables.app',
      query: 'subject=Payables App Feedback',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _launchPrivacyPolicy() async {
    final Uri url = Uri.parse('https://payables.app/privacy');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _launchTermsOfService() async {
    final Uri url = Uri.parse('https://payables.app/terms');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}
