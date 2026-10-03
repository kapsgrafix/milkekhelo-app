import '../../core/localization/app_language.dart';

/// All strings Blocks Jodo needs, in English and Hindi.
class BjText {
  final AppLang lang;
  const BjText(this.lang);

  bool get _hi => lang == AppLang.hi;

  String get title => _hi ? 'ब्लॉक जोड़ो' : 'Block Jodo';
  String get score => _hi ? 'स्कोर' : 'Score';
  String get lives => _hi ? 'जानें' : 'Lives';

  // Praise banners (by lines cleared in one move).
  String praise(int lines) {
    if (_hi) {
      if (lines >= 4) return 'ज़बरदस्त!';
      if (lines == 3) return 'कमाल!';
      if (lines == 2) return 'शानदार!';
      return 'बढ़िया!';
    }
    if (lines >= 4) return 'Unbelievable!';
    if (lines == 3) return 'Excellent!';
    if (lines == 2) return 'Great!';
    return 'Good!';
  }

  String combo(int n) => _hi ? 'कॉम्बो x$n' : 'Combo x$n';
  String get allClear => _hi ? 'बोर्ड साफ़!' : 'All Clear!';
  String get newBest => _hi ? 'नया रिकॉर्ड!' : 'New Best!';
  String get noSpace => _hi ? 'जगह नहीं बची!' : 'No space left!';
  String get rescue => _hi ? 'एक जान गई — बोर्ड साफ़!' : 'Life used — board rescued!';

  // Game over
  String get gameOver => _hi ? 'खेल खत्म!' : 'Game Over!';
  String get finalScore => _hi ? 'स्कोर' : 'Score';
  String best(int n) => _hi ? 'सबसे अच्छा: $n' : 'Best: $n';
  String get newBestSub => _hi ? 'आपने अपना रिकॉर्ड तोड़ दिया!' : 'You beat your best score!';
  String get tryAgainSub => _hi ? 'एक और बार? इस बार और ऊपर!' : 'One more go? Aim higher this time!';
  String get playAgain => _hi ? 'फिर से खेलें' : 'Play Again';
  String get backHome => _hi ? 'होम पर जाएँ' : 'Back to Home';

  // How to play
  String get howTitle => _hi ? 'कैसे खेलें' : 'How to Play';
  List<List<String>> get steps => _hi
      ? const [
          ['खींचो और रखो', 'नीचे के तीन ब्लॉक में से किसी एक को खींचकर बोर्ड पर रखो।'],
          ['लाइन पूरी करो', 'पूरी पंक्ति या कॉलम भरते ही वह गायब हो जाती है। जो लाइन पूरी होने वाली हो, वह चमकने लगती है।'],
          ['कॉम्बो बनाओ', 'लगातार चालों में लाइनें साफ़ करो और कॉम्बो से दोगुने-तिगुने अंक पाओ।'],
          ['3 जानें', 'कोई ब्लॉक फिट न हो तो एक जान जाती है और बोर्ड थोड़ा साफ़ हो जाता है। तीनों जानें गईं तो खेल खत्म।'],
        ]
      : const [
          ['Drag & drop', 'Drag any of the three blocks from the tray onto the board.'],
          ['Fill lines', 'Complete a full row or column to blast it away. Lines glow when they are about to clear.'],
          ['Build combos', 'Clear lines on back-to-back moves for a combo multiplier.'],
          ['3 lives', 'No room for any block? You lose a life and the board is rescued. Lose all three and it\'s game over.'],
        ];
  String get goalTitle => _hi ? 'लक्ष्य' : 'Goal';
  String get goalText => _hi ? 'जितना हो सके उतना स्कोर बनाओ और अपना रिकॉर्ड तोड़ो!' : 'Score as high as you can and beat your best!';
}
