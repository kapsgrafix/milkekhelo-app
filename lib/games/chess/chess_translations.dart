import '../../core/localization/app_language.dart';

/// Every Chess string, English and Hindi.
class ChessText {
  final AppLang lang;
  const ChessText(this.lang);

  bool get hi => lang == AppLang.hi;

  String get title => hi ? 'शतरंज' : 'Chess';

  // Landing (Figma "Chess Home")
  String get solo => hi ? 'सोलो' : 'Solo';
  String get soloSub => hi ? 'बॉट के खिलाफ़ खेलें' : 'Play against the bot';
  String get twoPlayers => hi ? '2 खिलाड़ी' : '2 Players';
  String get twoPlayersSub => hi ? 'एक ही फ़ोन पर साथ खेलें' : 'Play together on one device';

  // Players
  String get you => hi ? 'आप' : 'You';
  String get bot => hi ? 'शतरंज बॉट' : 'Chess Bot';
  String get player1 => hi ? 'खिलाड़ी 1' : 'Player 1';
  String get player2 => hi ? 'खिलाड़ी 2' : 'Player 2';
  String get white => hi ? 'सफ़ेद' : 'White';
  String get black => hi ? 'काला' : 'Black';
  String get yourTurn => hi ? 'आपकी बारी' : 'Your turn';
  String get thinking => hi ? 'सोच रहा है' : 'Thinking';
  String get turn => hi ? 'बारी' : 'Turn';

  // Moments
  String get check => hi ? 'शह!' : 'Check!';
  String get checkmate => hi ? 'शह और मात!' : 'Checkmate!';
  String get promoteTo => hi ? 'प्यादे को बदलें' : 'Promote pawn';

  // Results
  String get youWin => hi ? 'आप जीत गए! 🎉' : 'You win! 🎉';
  String get botWins => hi ? 'बॉट जीत गया' : 'The bot wins';
  String wins(String name) => hi ? '$name जीत गए!' : '$name wins!';
  String get draw => hi ? 'ड्रॉ' : 'Draw';
  String get stalemate => hi ? 'स्टेलमेट — कोई चाल नहीं बची' : 'Stalemate — no legal moves';
  String get insufficient => hi ? 'मात देने लायक मोहरे नहीं बचे' : 'Not enough pieces to checkmate';
  String get fiftyMove => hi ? '50 चालों का नियम' : '50-move rule';
  String get repetition => hi ? 'एक ही स्थिति तीन बार' : 'Same position three times';
  String get playAgain => hi ? '🔄 फिर खेलें' : '🔄 Play Again';
  String get backHome => hi ? '🏠 होम पर जाएं' : '🏠 Back to Home';

  // How to play
  String get howTitle => hi ? 'कैसे खेलें' : 'How to Play';
  List<List<String>> get steps => hi
      ? const [
          ['मोहरा चुनें', 'अपने किसी मोहरे पर टैप करें — जहाँ वह जा सकता है वहाँ बिंदु दिखेंगे।'],
          ['चाल चलें', 'किसी बिंदु पर टैप करें। घेरे वाला खाना मतलब वहाँ विरोधी का मोहरा कटेगा।'],
          ['मोहरे काटें', 'कटे हुए मोहरे प्रोफ़ाइल के पास दिखते हैं, साथ में आपकी बढ़त भी।'],
          ['शह से बचें', 'राजा पर हमला होने पर उसका खाना लाल हो जाता है — उसे बचाना ज़रूरी है।'],
          ['मात दें', 'विरोधी राजा को ऐसी शह दें जिससे वह बच न सके — आप जीत गए!'],
        ]
      : const [
          ['Pick a Piece', 'Tap one of your pieces — dots show every square it can move to.'],
          ['Make a Move', 'Tap a dot to move. A ringed square means you capture the piece there.'],
          ['Collect Captures', 'Captured pieces line up next to the profile, with your material lead.'],
          ['Escape Check', "When a king is attacked its square turns red — it must be saved."],
          ['Checkmate to Win', "Trap the other king so it can't escape check, and you win!"],
        ];
  String get goalTitle => hi ? '🎯 खेल का मकसद' : '🎯 Goal of the Game';
  String get goalText => hi
      ? 'सफ़ेद पहले चलता है। विरोधी के राजा को शह और मात दें।'
      : 'White moves first. Checkmate the other king to win.';
}
