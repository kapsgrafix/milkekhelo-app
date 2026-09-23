import '../../core/localization/app_language.dart';

/// All strings the Snakes & Ladders game needs, in English and Hindi.
/// Kept entirely inside this game's folder — a wording change here can
/// never affect Memory Grid, First, or Thank You.
class SnlText {
  final AppLang lang;
  const SnlText(this.lang);

  bool get _hi => lang == AppLang.hi;

  String get title => _hi ? 'स्नेक्स एंड लैडर्स' : 'Snakes & Ladders';
  String get getReadyIn => _hi ? 'तैयार हो जाओ' : 'Get Ready in';
  String get yellow => _hi ? 'पीला' : 'Yellow';
  String get red => _hi ? 'लाल' : 'Red';
  String get pts => _hi ? 'अंक' : 'pts';
  String get playAgain => _hi ? '🔄 फिर खेलें' : '🔄 Play Again';
  String get backToHome => _hi ? '🏠 होम पर जाएं' : '🏠 Back to Home';
  String get draw => _hi ? 'बराबरी!' : "It's a Draw!";
  String get howTitle => _hi ? 'कैसे खेलें' : 'How to Play';
  String get goalTitle => _hi ? '🎯 खेल का मकसद' : '🎯 Goal of the Game';
  String get goalText => _hi
      ? '2 मिनट में सबसे ज़्यादा अंक बनाओ। हर खाना = 2 अंक!'
      : 'Score the most points before the 2-minute timer runs out. Each square = 2 points!';

  String turnMsg(String name) => _hi ? '$name की बारी — पासा दबाएं!' : "$name's turn — tap dice!";
  String rolled(String name, int v) => _hi ? '$name ने $v फेंका!' : '$name rolled $v!';
  String get snakeBite => _hi ? '🐍 साँप ने काटा! नीचे...' : '🐍 Snake bite! Sliding down...';
  String get ladderUp => _hi ? '🪜 सीढ़ी! ऊपर चढ़ो...' : '🪜 Ladder! Climbing up...';
  String reached100(String name) => _hi ? '🎉 $name 100 पर पहुंचा!' : '🎉 $name reached 100!';
  String wins(String name) => _hi ? '$name जीता!' : '$name Wins!';
  String endSub(int yp, int rp) =>
      _hi ? 'पीला: $yp अंक · लाल: $rp अंक' : 'Yellow: $yp pts · Red: $rp pts';

  /// [title, description] pairs for the how-to-play sheet.
  List<List<String>> get steps => _hi
      ? const [
          ['दो खिलाड़ी', 'पीला और लाल बारी-बारी खेलें। हाईलाइट खिलाड़ी पासा फेंके।'],
          ['पासा दबाएं', 'पासा दबाओ, गोटी उतने खाने आगे बढ़ेगी।'],
          ['सीढ़ी ऊपर 🪜', 'सीढ़ी के नीचे पहुंचो और सीधे ऊपर चढ़ो!'],
          ['साँप नीचे 🐍', 'साँप के मुंह पर पहुंचे तो पूंछ तक नीचे।'],
          ['अंक कमाओ', 'आपका खाना × 2 = आपके अंक। खाना 40 = 80 अंक।'],
          ['समय से जीतो', '2 मिनट का टाइमर! समय खत्म होने पर ज़्यादा अंक वाला जीतेगा। 100 पहुंचे तो तुरंत जीत!'],
        ]
      : const [
          ['Two Players', 'Yellow and Red take turns. The highlighted player rolls.'],
          ['Tap the Dice', 'Tap the dice to roll. Your goti moves that many squares.'],
          ["Ladders Up 🪜", "Land at a ladder's base and climb straight up!"],
          ['Snakes Down 🐍', "Land on a snake's head and slide down to its tail."],
          ['Score Points', 'Your square × 2 = your points. Square 40 = 80 points.'],
          ['Beat the Clock', '2-minute timer! Highest points when time ends wins. Reaching 100 = instant win!'],
        ];
}
