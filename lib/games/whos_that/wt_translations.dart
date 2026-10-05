import '../../core/localization/app_language.dart';

/// Every Who's That string, English and Hindi. English copy follows the Figma
/// frames; Hindi follows the web game where it has the same line.
class WtText {
  final AppLang lang;
  const WtText(this.lang);

  bool get hi => lang == AppLang.hi;

  String get title => hi ? 'पहचान कौन' : "Who's That?";

  // Home (Figma "Whosthat Home")
  String get createGame => hi ? 'गेम बनाएं' : 'Create Game';
  String get createSub => hi ? 'अधिकतम 10 खिलाड़ी' : 'Maximum 10 Players';
  String get joinGame => hi ? 'गेम जॉइन करें' : 'Join Game';
  String get joinCardSub => hi ? 'कोड डालें और जॉइन करें' : 'Enter Code and Join';

  // Create (Figma "Whosthat Create")
  String get createHeadingSub => hi ? '2 से 10 खिलाड़ी चाहिए' : '2 to 10 players needed';
  String get lQuestions => hi ? 'सवालों की संख्या' : 'NUMBER OF QUESTIONS';
  String get lTarget => hi ? 'टारगेट स्कोर' : 'TARGET SCORE';
  String get lName => hi ? 'आपका नाम' : 'YOUR NAME';
  String get phName => hi ? 'आपका नाम' : 'Your name';
  String qOption(int n) => hi ? '$n सवाल' : '$n Questions';
  String targetHint(int max) => hi ? 'जीतने के लिए मिलते-जुलते जवाब (1–$max)' : 'Matching answers needed to win (1–$max)';
  String get create => hi ? 'बनाएं' : 'Create';
  String get creating => hi ? 'बन रहा है…' : 'Creating…';

  // Join (Figma "Whosthat Join")
  String get joinHeadingSub => hi ? 'होस्ट का दिया कोड डालें' : 'Enter the code your host shared';
  String get lCode => hi ? 'गेम कोड' : 'GAME CODE';
  String get joining => hi ? 'जॉइन हो रहा है…' : 'Joining…';

  // Lobby (Figma "Whosthat Lobby" / "Lobby - Active")
  String get gameCode => hi ? 'गेम कोड' : 'GAME CODE';
  String get copyCode => hi ? 'कोड कॉपी करें' : 'Copy Code';
  String get codeCopied => hi ? 'कोड कॉपी हो गया!' : 'Code copied!';
  String get playersLabel => hi ? 'खिलाड़ी' : 'PLAYERS';
  String get you => hi ? '(आप)' : '(You)';
  String get youLower => hi ? '(आप)' : '(you)';
  String get hostTag => hi ? 'होस्ट' : 'HOST';
  String get waitingSlot => hi ? 'खिलाड़ी का इंतज़ार…' : 'Waiting for player…';
  String get waitingPlayers => hi ? 'खिलाड़ियों का इंतज़ार…' : 'Waiting for players…';
  String get waitingHostStart => hi ? 'होस्ट के गेम शुरू करने का इंतज़ार…' : 'Waiting for the host to start…';
  String get startGame => hi ? 'गेम शुरू करें' : 'Start Game';

  // Question (Figma "Whosthat Question" / "Status States")
  String get score => hi ? 'स्कोर' : 'SCORE';
  String get remaining => hi ? 'बाकी' : 'REMAINING';
  String questionNo(int n) => hi ? 'सवाल $n' : 'QUESTION $n';
  String get answered => hi ? 'जवाब दिया' : 'Answered';
  String get offline => hi ? 'ऑफ़लाइन' : 'Offline';
  String get locked => hi ? 'जवाब दर्ज — बाकी सबका इंतज़ार…' : 'Answer locked in — waiting for everyone else…';
  String removeConfirm(String name) => hi ? '$name को गेम से हटाएं?' : 'Remove $name from the game?';
  String get remove => hi ? 'हटाएं' : 'Remove';

  // Reveal (Figma "Whosthat Bullseye" / "Majority Pick" / "Tie")
  String get bullseye => hi ? 'निशाना सही!' : 'Bullseye!';
  String everyonePicked(String name) => hi ? 'सबने $name को चुना - ' : 'Everyone picked $name - ';
  String get plusOne => hi ? '+1 अंक!' : '+1 point!';
  String get crowdsPick => hi ? 'भीड़ की पसंद!' : "Crowd's Pick!";
  String crowdSub(String name) => hi ? '$name को सबसे ज़्यादा वोट मिले! कोई अंक नहीं' : '$name got the most votes! No points';
  String get tie => hi ? 'बराबरी!' : "It's a Tie!";
  String tieSub(List<String> names) {
    final joined = names.length <= 1
        ? names.join()
        : '${names.sublist(0, names.length - 1).join(', ')}${hi ? ' और ' : ' & '}${names.last}';
    return hi ? '$joined बराबर रहे। कोई अंक नहीं' : '$joined all tied. No points';
  }

  String get self => hi ? '(खुद)' : '(self)';
  String get nextQuestion => hi ? 'अगला सवाल →' : 'Next Question →';
  String get seeResults => hi ? 'नतीजे देखें →' : 'See Results →';
  String get waitHost => hi ? 'होस्ट का इंतज़ार…' : 'Waiting for the host…';

  // End (Figma "Whosthat Win" / "Good Game")
  String get winTitle => hi ? 'आपकी टीम जीत गई!' : 'Your Team Wins!';
  String get winSub => hi ? 'बढ़िया खेले!' : 'Well played!';
  String get loseTitle => hi ? 'अच्छा खेल!' : 'Good Game!';
  String get loseSub => hi ? 'बस थोड़ा रह गया! फिर कोशिश करें' : 'So close! Give it another shot';
  String get playAgain => hi ? '🔄 फिर खेलें' : '🔄 Play Again';
  String get backHome => hi ? '🏠 होम पर जाएं' : '🏠 Back to Home';
  String get onlyHostRestarts => hi ? 'होस्ट नया गेम शुरू करेंगे' : 'The host will start the next game';

  // Leaving
  String get leaveTitle => hi ? 'गेम छोड़ें?' : 'Leave the game?';
  String get leaveHostBody => hi ? 'आप होस्ट हैं — छोड़ने पर सबके लिए गेम खत्म हो जाएगा।' : "You're the host — leaving ends the game for everyone.";
  String get leaveBody => hi ? 'आप इस गेम से बाहर हो जाएंगे।' : "You'll be removed from this game.";
  String get leave => hi ? 'छोड़ें' : 'Leave';
  String get stay => hi ? 'रुकें' : 'Stay';

  // Joining a game that's already running
  String get askingTitle => hi ? 'जॉइन करने का अनुरोध' : 'Asking to Join';
  String get askingSub => hi ? 'गेम शुरू हो चुका है — होस्ट की मंज़ूरी चाहिए' : 'The game has started — the host needs to let you in';
  String get waitingApproval => hi ? 'होस्ट की मंज़ूरी का इंतज़ार…' : 'Waiting for the host to accept…';
  String get cancel => hi ? 'रद्द करें' : 'Cancel';
  String get declined => hi ? 'होस्ट ने आपका अनुरोध मना कर दिया' : 'The host declined your request';
  String get wantsToJoin => hi ? 'गेम में शामिल होना चाहते हैं' : 'wants to join the game';
  String get accept => hi ? 'स्वीकार करें' : 'Accept';
  String get decline => hi ? 'मना करें' : 'Decline';

  // Toasts
  String get enterName => hi ? 'अपना नाम डालें' : 'Enter your name';
  String get enterCode => hi ? '4 अक्षरों का कोड डालें' : 'Enter the 4-letter code';
  String get noGame => hi ? 'इस कोड का कोई गेम नहीं मिला' : 'No game found with that code';
  String get alreadyStarted => hi ? 'यह गेम शुरू हो चुका है' : 'That game has already started';
  String get gameFull => hi ? 'गेम भर चुका है (अधिकतम 10)' : 'That game is full (10 players max)';
  String get networkError => hi ? 'कनेक्ट नहीं हो पाया — इंटरनेट चेक करें' : "Couldn't connect — check your internet";
  String get sendFailed => hi ? 'भेजा नहीं जा सका — फिर कोशिश करें' : "Couldn't send — try again";
  String get gameEnded => hi ? 'होस्ट ने गेम खत्म कर दिया' : 'The host ended the game';
  String get youWereRemoved => hi ? 'आपको गेम से हटा दिया गया' : 'You were removed from the game';
  String get reconnecting => hi ? 'दोबारा कनेक्ट हो रहा है…' : 'Reconnecting…';

  // How to play (same steps as the web game)
  String get howTitle => hi ? 'कैसे खेलें' : 'How to Play';
  List<List<String>> get steps => hi
      ? const [
          ['ग्रुप जुटाएं', '2 से 10 खिलाड़ी। एक व्यक्ति गेम बनाकर कोड शेयर करे।'],
          ['सब जॉइन करें', 'बाकी लोग कोड और अपना नाम डालकर लॉबी में आएं।'],
          ['साथ जवाब दें', 'सवाल आएगा — जो खिलाड़ी सही लगे उसे चुनें। सबके जवाब देने तक कोई किसी का जवाब नहीं देख सकता।'],
          ['टीम के तौर पर स्कोर', 'अगर हर खिलाड़ी ने एक ही व्यक्ति को चुना, तो टीम को 1 अंक मिलेगा।'],
          ['टारगेट तक पहुंचें', 'सवाल खत्म होने से पहले टारगेट स्कोर छू लें और पूरी टीम जीत जाएगी।'],
        ]
      : const [
          ['Gather Your Group', '2 to 10 players. One person creates the game and shares the code.'],
          ['Everyone Joins', 'Others enter the code and their name to join the lobby.'],
          ['Answer Together', 'A question appears — pick the player you think fits best. Nobody sees the answers until everyone has picked.'],
          ['Score as a Team', 'If every single player picked the same person, the team earns 1 point.'],
          ['Reach the Target', 'Hit your target score before the questions run out and the whole team wins.'],
        ];
  String get goalTitle => hi ? '🎯 खेल का मकसद' : '🎯 Goal of the Game';
  String get goalText => hi
      ? 'यह एक-दूसरे से जीतने का खेल नहीं है — यह जानने का है कि आपका ग्रुप कितना एक जैसा सोचता है।'
      : "This isn't about winning against each other — it's about finding out how well your group thinks alike.";
}
