/// MilkeKhelo Privacy Policy & Terms — the text shown on the Policy page.
/// Edit here to update the policy; bump [policyLastUpdated] when you do.
library;

const String policyLastUpdated = 'October 2026';
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
    paragraphs: [
      'We collect as little as possible. Signing in is optional — you can play every game without an account and without giving us any personal information.',
    ],
    bulletsLabel: 'Information you provide:',
    bullets: [
      'Account information (only if you sign in): when you choose "Continue with Google" or "Continue with Facebook", that provider shares your name, email address, profile photo and a unique account ID with us. We never see or store your Google or Facebook password.',
      'Game progress (only if you sign in): your best scores and streaks, and the state of a game you leave mid-way, so you can continue later or on another phone.',
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
      'We do not ask for or store your phone number, home address, passwords, payment information, contacts, friends list, precise location, photos, microphone, or SMS. We never post anything to your Google or Facebook account. We do not sell your personal information to anyone.',
    ],
  ),
  PolicySection(
    'How We Use Your Information',
    bullets: [
      'To provide and run the games',
      'To sign you in and keep your account secure (if you choose to sign in)',
      'To save your best scores and game progress — on your device, and to your account if you are signed in, so you can continue on any device',
      'To understand performance and improve the experience',
      'To respond to support and account requests (we use your email address only for this — no marketing emails)',
      'To prevent misuse and keep the service safe',
    ],
  ),
  PolicySection(
    'Sign-in with Google & Facebook',
    paragraphs: [
      'Sign-in is handled by Google Firebase Authentication together with Google Sign-In and Facebook Login. We only request your basic public profile and email address. Your account ID links your saved progress to you; your email lets us identify your account if you contact us for support or deletion.',
      'You can remove MilkeKhelo\'s access at any time from your Google Account (Security → Third-party apps) or Facebook (Settings → Apps and Websites). Removing access signs you out; to also erase your saved data, see "Deleting Your Account & Data" below.',
    ],
  ),
  PolicySection(
    'Multiplayer & Firebase',
    paragraphs: [
      'Multiplayer games use Google Firebase to sync players in real time. Display names and temporary game data are stored on Firebase servers only for as long as needed to run a game session, and old sessions are cleared automatically. If you are signed in, your best scores and saved games are stored in Google Firebase, linked to your account ID.',
    ],
  ),
  PolicySection(
    'Local Storage',
    paragraphs: [
      'Games save your settings, best scores and unfinished games on your own device so you can pick up where you left off. If you are not signed in, this information stays on your device and is not sent to us.',
    ],
  ),
  PolicySection(
    'Sharing of Information',
    paragraphs: [
      'We do not sell personal information. We share limited information only with trusted service providers who help us run MilkeKhelo — Google (Firebase hosting, authentication and analytics) and Meta (Facebook Login, only if you use it) — solely to operate the service. We may also disclose information if required by law, regulation, or valid legal process.',
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
      'We keep account information and saved progress for as long as your account exists. Temporary multiplayer game data is cleared automatically after a session ends. When you delete your account, we delete your account information and saved progress within 30 days, except where we must keep something to meet a legal obligation.',
    ],
  ),
  PolicySection(
    'Deleting Your Account & Data',
    paragraphs: [
      'You can ask us to delete your account and all data linked to it at any time. Email $policyEmail from the email address linked to your MilkeKhelo account with the subject "Delete my account", and say whether you signed in with Google or Facebook. We will confirm and delete your account information and saved progress within 30 days.',
      'Data stored only on your device (when you are not signed in) can be removed by clearing the app\'s data or uninstalling the app.',
    ],
  ),
  PolicySection(
    'Children\'s Privacy',
    paragraphs: [
      'MilkeKhelo is intended for users above the minimum digital-consent age in their region. Children under 13 should use the service only with parental supervision, and should not sign in. We do not knowingly collect personal information from children under 13. Accounts are optional, so the app can be enjoyed without sharing personal details. If you believe a child has shared personal information, contact us and we will remove it.',
    ],
  ),
  PolicySection(
    'Your Rights',
    paragraphs: [
      'Depending on your region, you may have the right to access, correct, or delete information relating to you, or to withdraw consent. If you are signed in, you can ask us for a copy of your account data or for it to be deleted. For any request, email us at $policyEmail.',
    ],
  ),
  PolicySection(
    'Security',
    paragraphs: [
      'We use commercially reasonable safeguards and rely on trusted providers (Google Firebase, Google Sign-In, Facebook Login) that use industry-standard security. However, no method of internet transmission or storage can be guaranteed 100% secure.',
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
    paragraphs: [
      'We may update this policy from time to time. Any changes will be posted on this page with an updated date.',
    ],
  ),
];
