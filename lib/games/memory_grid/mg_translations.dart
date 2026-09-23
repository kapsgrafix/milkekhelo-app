import '../../core/localization/app_language.dart';

/// All strings Memory Grid needs, in English and Hindi. Kept entirely
/// inside this game's folder.
///
/// Note: the web app's "How to Play" step lists and level-card description
/// lines ("4 blocks" / "7 blocks" / "10 blocks") were English-only in the
/// original source (never localized) — reproduced faithfully here, with
/// Hindi equivalents added since they cost nothing and read better; if you
/// want strict parity with the original gap, use the English strings for
/// both languages instead.
class MgText {
  final AppLang lang;
  const MgText(this.lang);

  bool get _hi => lang == AppLang.hi;

  String get tagline => _hi ? 'याद करो · दबाओ · दोहराओ' : 'Memorise, Tap, and Win!';
  String get soloHeading => _hi ? 'सोलो — अपना सर्वश्रेष्ठ करो' : 'Solo — Beat Your Best';
  String get duelHeading => _hi ? 'साथ खेलें' : 'Play Together';
  String get easy => _hi ? 'आसान' : 'Easy';
  String get medium => _hi ? 'मध्यम' : 'Medium';
  String get hard => _hi ? 'कठिन' : 'Hard';
  String easyDesc(int n) => _hi ? '$n ब्लॉक' : '$n blocks';
  String get duelName => _hi ? '2 खिलाड़ी ऑफलाइन' : '2 Players Offline';
  String get duelSub => _hi ? 'एक ही डिवाइस पर बारी-बारी से खेलें, ज़्यादा स्कोर जीतता है' : 'Same device. Take turns. Highest score wins';
  String get p1 => _hi ? 'खिलाड़ी 1' : 'Player 1';
  String get p2 => _hi ? 'खिलाड़ी 2' : 'Player 2';
  String get p1turn => _hi ? 'खिलाड़ी 1 की बारी' : "Player 1's turn";
  String get p2turn => _hi ? 'खिलाड़ी 2 की बारी' : "Player 2's turn";
  String get memorise => _hi ? 'याद करो!' : 'Memorise!';
  String get hereThey => _hi ? 'ये रहे!' : 'Here they are!';
  String get memorizeIn => _hi ? 'याद करो' : 'Memorize in';
  String get hint => _hi ? 'हिंट' : 'Hint';
  String get streak => _hi ? 'स्ट्रीक' : 'Streak';
  String get lives => _hi ? 'जानें' : 'Lives';

  String mode(String level) {
    if (_hi) {
      return {'easy': 'आसान मोड', 'medium': 'मध्यम मोड', 'hard': 'कठिन मोड'}[level] ?? '';
    }
    return {'easy': 'Easy Mode', 'medium': 'Medium Mode', 'hard': 'Hard Mode'}[level] ?? '';
  }

  String tap(int a, int b) => _hi ? 'ब्लॉक दबाओ — $a / $b' : 'Tap the blocks — $a of $b';
  String get outLives => _hi ? 'जान खत्म!' : 'Out of lives!';
  String get lifeLeft => _hi ? '1 जान बची!' : '1 life left!';
  String livesLeft(int n) => _hi ? '$n जान बची' : '$n lives left';
  String get gameOver => _hi ? 'गेम ओवर' : 'Game Over';
  String get finalStreak => _hi ? 'फाइनल स्ट्रीक' : 'Final Streak';
  String reachedStreak(int n) => _hi ? 'आपकी स्ट्रीक $n तक पहुंची' : 'You reached a streak of $n';
  String get betterLuck => _hi ? 'अगली बार बेहतर!' : 'Better luck this time!';
  String bestStreak(int n) => _hi ? 'बेस्ट स्ट्रीक: $n' : 'Best streak: $n';
  String wins(int n) => _hi ? 'खिलाड़ी $n जीता!' : 'Player $n Wins!';
  String get winSub => _hi ? 'बढ़िया याददाश्त!' : 'Great memory!';
  String get tie => _hi ? 'बराबरी!' : "It's a Tie!";
  String get tieSub => _hi ? 'दोनों बराबर!' : 'Evenly matched!';
  String get playAgain => _hi ? 'फिर खेलें' : 'Play Again';
  String get backHome => _hi ? '🏠 होम पर जाएं' : '🏠 Back to Home';

  List<String> get praise => _hi
      ? const ['शाबाश!', 'बढ़िया!', 'परफेक्ट!', 'तेज़ याददाश्त!', 'कमाल!', 'आग! 🔥']
      : const ['Well done!', 'Nailed it!', 'Perfect!', 'Sharp memory!', 'Brilliant!', 'On fire! 🔥'];

  List<List<String>> get howStepsSolo => _hi
      ? const [
          ['ध्यान से देखो', 'शुरुआत में कुछ ब्लॉक थोड़ी देर के लिए जलेंगे। उन्हें याद करो।'],
          ['याद से दबाओ', 'बुझने के बाद, हर वो ब्लॉक दबाओ जो जला था।'],
          ['स्ट्रीक बनाओ', 'सभी ब्लॉक सही दबाकर स्कोर करो। हर राउंड से स्ट्रीक बढ़ती है।'],
          ['जान का ध्यान रखो', 'गलत दबाने पर एक जान जाती है — हर स्ट्रीक में 3 जानें मिलती हैं।'],
          ['हिंट लो', 'अटक गए? पैटर्न फिर दिखाने के लिए हिंट दबाओ — हर स्ट्रीक में 3 हिंट।'],
        ]
      : const [
          ['Watch Closely', 'Some blocks light up briefly at the start. Memorise them.'],
          ['Tap From Memory', 'After they vanish, tap every block that was lit.'],
          ['Build a Streak', 'Clear all blocks to score. Each cleared round grows your streak.'],
          ['Mind Your Lives', 'A wrong tap costs a life — you get 3 per streak.'],
          ['Use Hints', 'Stuck? Tap Hint to flash the pattern — 3 hints per streak.'],
        ];

  List<List<String>> get howStepsDuel => _hi
      ? const [
          ['साथ याद करो', 'शुरुआत में 10 ब्लॉक जलेंगे। दोनों खिलाड़ी उन्हें याद करें।'],
          ['बारी-बारी खेलो', 'हर बारी में एक ब्लॉक दबाओ — पहले खिलाड़ी 1।'],
          ['अंक कमाओ', 'सही ब्लॉक पर 1 अंक मिलेगा। गलत होने पर लाल चमकेगा — कोई अंक नहीं।'],
          ['बारी बदलती है', 'सही हो या गलत, हर दबाने के बाद बारी बदल जाती है।'],
          ['असीमित हिंट', 'कोई भी खिलाड़ी बाकी ब्लॉक दिखाने के लिए हिंट दबा सकता है।'],
          ['मुकाबला जीतो', 'जब सभी ब्लॉक मिल जाएं, तो ज़्यादा अंक वाला जीतता है!'],
        ]
      : const [
          ['Memorise Together', '10 blocks light up at the start. Both players memorise them.'],
          ['Take Turns', 'Players tap one block per turn — Player 1 goes first.'],
          ['Score a Point', 'A correct block earns 1 point. Wrong flashes red — no point.'],
          ['Turn Passes', 'Right or wrong, the turn passes after each tap.'],
          ['Unlimited Hints', 'Either player can tap Hint to reveal remaining blocks.'],
          ['Win the Duel', 'When all blocks are found, the higher score wins!'],
        ];

  String get howTitle => _hi ? 'कैसे खेलें' : 'How to Play';
  String get goalTitle => _hi ? '🎯 लक्ष्य' : '🎯 Goal';
  String get goalText => _hi
      ? 'अपने प्रतिद्वंद्वी से बेहतर याद रखो! उनसे ज़्यादा सही ब्लॉक खोजकर मुकाबला जीतो।'
      : 'Out-remember your opponent! Find more correct blocks than they do to win the duel.';
}
