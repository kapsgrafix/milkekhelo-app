/// MilkeKhelo Privacy Policy & Terms — the text shown on the Policy page.
/// Edit here to update the policy; bump [policyLastUpdated] when you do.
library;

const String policyLastUpdated = 'September 2026';
const String policyEmail = 'talk@milkekhelo.com';
const String policyWebsite = 'milkekhelo.com';

/// One block of the policy: a heading followed by paragraphs and/or bullets.
class PolicySection {
  final String heading;
  final List<String> paragraphs;
  final List<String> bullets;

  /// Optional label shown above [bullets] (e.g. "Information you provide:").
  final String? bulletsLabel;

  /// Extra bullet groups after the first (label + items).
  final List<(String, List<String>)> moreBullets;

  /// Text shown after the bullets.
  final List<String> after;

  const PolicySection(
    this.heading, {
    this.paragraphs = const [],
    this.bulletsLabel,
    this.bullets = const [],
    this.moreBullets = const [],
    this.after = const [],
  });
}

const List<PolicySection> policySections = [
  PolicySection(
    'Introduction',
    paragraphs: [
      'Welcome to MilkeKhelo ("MKK", "we", "our", or "us"). MilkeKhelo is a bilingual social gaming platform offering conversation-based games and interactive experiences designed to encourage meaningful interactions among friends, families, colleagues, and communities.',
      'This Privacy Policy explains how we collect, use, store, and protect your information when you use our website, app, and related services. By using MilkeKhelo, you agree to this policy.',
    ],
    after: ['MilkeKhelo is built to create conversations, not collect them.'],
  ),
  PolicySection(
    'Information We Collect',
    paragraphs: ['We collect as little as possible. You can play most of our games without providing any personal information.'],
    bulletsLabel: 'Information you provide:',
    bullets: [
      'Display name: In multiplayer games like "Who\'s That?", the name you type is shared with other players in your game session and stored temporarily to run the game.',
      'Feedback: Any message you choose to send us by email.',
    ],
    moreBullets: [
      (
        'Information collected automatically:',
        [
          'Device type, operating system, and browser information',
          'Approximate location (derived from IP address)',
          'Usage analytics (such as which games are popular)',
          'App version and basic diagnostics',
        ],
      ),
    ],
  ),
  PolicySection(
    'Information We Do NOT Collect',
    paragraphs: [
      'We do not require accounts or logins. We do not ask for or store your email address, phone number, home address, passwords, payment information, contacts, precise location, photos, microphone, or SMS. We do not sell your personal information to anyone.',
    ],
  ),
  PolicySection(
    'How We Use Your Information',
    bullets: [
      'To provide and run the games',
      'To save game progress and preferences on your device',
      'To understand performance and improve the experience',
      'To respond to support requests',
      'To prevent misuse and keep the service safe',
    ],
  ),
  PolicySection(
    'Multiplayer & Firebase',
    paragraphs: [
      'Multiplayer games use Google Firebase to sync players in real time. Display names and temporary game data are stored on Firebase servers only for as long as needed to run a game session, and old sessions are cleared automatically.',
    ],
  ),
  PolicySection(
    'Local Storage',
    paragraphs: [
      'Some games (like Memory Grid) save your best score on your own device so you can beat it later. This information never leaves your device and is not sent to us.',
    ],
  ),
  PolicySection(
    'Sharing of Information',
    paragraphs: [
      'We do not sell personal information. We may share limited information with trusted service providers who help us run MilkeKhelo — such as hosting (Google Firebase) and analytics (Google Analytics) — solely to operate the service. We may also disclose information if required by law, regulation, or valid legal process.',
    ],
  ),
  PolicySection(
    'AI Features',
    paragraphs: [
      'Some MilkeKhelo features may use artificial intelligence to generate conversation prompts or game content. Where this happens, information is processed by trusted AI providers solely to generate the requested output. We do not sell your conversations to third parties.',
    ],
  ),
  PolicySection(
    'Data Retention',
    paragraphs: [
      'We retain information only as long as necessary to provide the service, meet legal obligations, and resolve any disputes. Temporary multiplayer game data is cleared automatically after a session ends.',
    ],
  ),
  PolicySection(
    "Children's Privacy",
    paragraphs: [
      "MilkeKhelo is intended for users above the minimum digital-consent age in their region. Children under 13 should use the service only with parental supervision. We do not knowingly collect personal information from children under 13. Since we don't require emails or accounts, the app can be enjoyed without sharing personal details. If you believe a child has shared personal information, contact us and we will remove it.",
    ],
  ),
  PolicySection(
    'Your Rights',
    paragraphs: [
      "Depending on your region, you may have the right to access, correct, or delete information relating to you, or to withdraw consent. Because we don't operate accounts, most data is either temporary or stored only on your own device. You can clear on-device data anytime through your browser settings. For any request, email us at $policyEmail.",
    ],
  ),
  PolicySection(
    'Security',
    paragraphs: [
      'We use commercially reasonable safeguards and rely on trusted providers (Google Firebase, Google Analytics) that use industry-standard security. However, no method of internet transmission or storage can be guaranteed 100% secure.',
    ],
  ),
  PolicySection(
    'Terms of Use',
    paragraphs: [
      'MilkeKhelo is provided free, "as is", for personal entertainment. Please play respectfully with others. Do not misuse the app, disrupt its services, or use it for any unlawful purpose. We may update or discontinue games at any time.',
    ],
  ),
  PolicySection(
    'Changes to This Policy',
    paragraphs: ['We may update this policy from time to time. Any changes will be posted on this page with an updated date.'],
  ),
];
