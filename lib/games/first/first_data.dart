import 'package:flutter/material.dart';

/// One "First" icebreaker card. `titleEn`/`titleHi` is the bold headline,
/// `subEn`/`subHi` is the smaller line under it (together they read as one
/// question, e.g. "FIRST MOVIE / YOU WATCHED IN A THEATRE").
class FirstCard {
  final String titleEn;
  final String subEn;
  final String titleHi;
  final String subHi;
  final String icon;
  final String catKey;
  const FirstCard({
    required this.titleEn,
    required this.subEn,
    required this.titleHi,
    required this.subHi,
    required this.icon,
    required this.catKey,
  });
}

class FirstCategory {
  final String nameEn;
  final String nameHi;
  final Color color;
  final bool darkText;
  const FirstCategory({required this.nameEn, required this.nameHi, required this.color, this.darkText = false});
}

class FirstData {
  FirstData._();

  static const Map<String, FirstCategory> categories = {
    'ent': FirstCategory(nameEn: 'Entertainment & Pop Culture', nameHi: 'मनोरंजन', color: Color(0xFF7B3FA0)),
    'adv': FirstCategory(nameEn: 'Experiences & Adventures', nameHi: 'यात्रा और अनुभव', color: Color(0xFF1A7A6E)),
    'rel': FirstCategory(nameEn: 'Relationships & Emotions', nameHi: 'रिश्ते और भावनाएं', color: Color(0xFFD94F3D)),
    'mil': FirstCategory(nameEn: 'Personal Milestones', nameHi: 'जीवन के पड़ाव', color: Color(0xFFD4A800), darkText: true),
    'sch': FirstCategory(nameEn: 'School & Growing Up', nameHi: 'स्कूल के दिन', color: Color(0xFF3A7EC6)),
  };

  static const List<FirstCard> cards = [
    // Entertainment & Pop Culture
    FirstCard(icon: '🎬', catKey: 'ent', titleEn: 'FIRST MOVIE', subEn: 'YOU WATCHED IN A THEATRE', titleHi: 'पहली फ़िल्म', subHi: 'जो थिएटर में देखी'),
    FirstCard(icon: '📺', catKey: 'ent', titleEn: 'FIRST TV SHOW', subEn: 'YOU REALLY LIKED', titleHi: 'पहला TV शो', subHi: 'जो आपको सच में पसंद आया'),
    FirstCard(icon: '⭐', catKey: 'ent', titleEn: 'FIRST FAMOUS PERSON', subEn: 'YOU LIKED THE MOST', titleHi: 'पहला मशहूर इंसान', subHi: 'जो आपको सबसे ज़्यादा पसंद था'),
    FirstCard(icon: '🎵', catKey: 'ent', titleEn: 'FIRST SAD SONG', subEn: 'YOU REALLY LIKED', titleHi: 'पहला दर्द भरा गाना', subHi: 'जो आपको सच में पसंद आया'),
    FirstCard(icon: '🔁', catKey: 'ent', titleEn: 'FIRST SONG', subEn: 'YOU HEARD ON REPEAT', titleHi: 'पहला गाना', subHi: 'जो आपने बार-बार सुना'),
    FirstCard(icon: '🕺', catKey: 'ent', titleEn: 'FIRST DANCE SONG', subEn: 'YOU REMEMBER LIKING A LOT', titleHi: 'पहला डांस सॉन्ग', subHi: 'जो आपको बहुत पसंद था'),
    // Experiences & Adventures
    FirstCard(icon: '✈️', catKey: 'adv', titleEn: 'FIRST TRAVEL', subEn: 'OUTSIDE YOUR CITY', titleHi: 'पहली यात्रा', subHi: 'जो शहर से बाहर की थी'),
    FirstCard(icon: '🏖️', catKey: 'adv', titleEn: 'FIRST FAMILY HOLIDAY', subEn: 'YOU REMEMBER', titleHi: 'पहली फैमिली छुट्टी', subHi: 'जो आपको याद है'),
    FirstCard(icon: '🎒', catKey: 'adv', titleEn: 'FIRST TIME', subEn: 'YOU WENT SOMEWHERE ALONE', titleHi: 'पहली बार अकेले', subHi: 'जब आप कहीं अकेले गए'),
    FirstCard(icon: '💒', catKey: 'adv', titleEn: 'FIRST FAMILY WEDDING', subEn: 'YOU REMEMBER ATTENDING', titleHi: 'पहली फैमिली शादी', subHi: 'जो आपको याद है'),
    FirstCard(icon: '🎡', catKey: 'adv', titleEn: 'FIRST CARNIVAL OR MELA', subEn: 'YOU REMEMBER ATTENDING', titleHi: 'पहला मेला', subHi: 'जो आपको याद है'),
    FirstCard(icon: '🎢', catKey: 'adv', titleEn: 'FIRST AMUSEMENT RIDE', subEn: 'YOU EVER TOOK', titleHi: 'पहली राइड', subHi: 'जो आपने ली'),
    FirstCard(icon: '🪂', catKey: 'adv', titleEn: 'FIRST FUN OR ADVENTURE', subEn: 'ACTIVITY YOU TRIED', titleHi: 'पहली एडवेंचर एक्टिविटी', subHi: 'जो आपने आज़माई'),
    FirstCard(icon: '🍽️', catKey: 'adv', titleEn: 'FIRST RESTAURANT', subEn: 'YOU REMEMBER VISITING REGULARLY', titleHi: 'पहला रेस्टोरेंट', subHi: 'जहाँ आप अक्सर जाते थे'),
    FirstCard(icon: '🏙️', catKey: 'adv', titleEn: 'FIRST CITY', subEn: 'YOU LIVED IN APART FROM HOMETOWN', titleHi: 'पहला शहर', subHi: 'जहाँ आप घर से बाहर रहे'),
    FirstCard(icon: '🌍', catKey: 'adv', titleEn: 'FIRST COUNTRY', subEn: 'YOU LEARNED ABOUT APART FROM YOUR OWN', titleHi: 'पहला देश', subHi: 'जो आपने अपने देश के अलावा जाना'),
    // Relationships & Emotions
    FirstCard(icon: '👶', catKey: 'rel', titleEn: 'FIRST TIME', subEn: 'YOU HELD A BABY', titleHi: 'पहली बार', subHi: 'जब आपने बच्चे को गोद लिया'),
    FirstCard(icon: '👩‍🏫', catKey: 'rel', titleEn: 'FIRST TEACHER', subEn: 'YOU LIKED', titleHi: 'पहले टीचर', subHi: 'जो आपको पसंद थे'),
    FirstCard(icon: '🤝', catKey: 'rel', titleEn: 'FIRST BEST FRIEND', subEn: 'YOU EVER HAD', titleHi: 'पहला पक्का दोस्त', subHi: 'जो सच्चा यार था'),
    FirstCard(icon: '💍', catKey: 'rel', titleEn: 'FIRST RISHTA TALK', subEn: 'OR TALKS OF PAIRING UP', titleHi: 'पहली रिश्ते की बात', subHi: 'या मेल-मिलाप की बात'),
    FirstCard(icon: '🌸', catKey: 'rel', titleEn: 'FIRST COMPLIMENT', subEn: 'YOU REMEMBER CLEARLY', titleHi: 'पहली तारीफ़', subHi: 'जो आपको अच्छे से याद है'),
    FirstCard(icon: '💑', catKey: 'rel', titleEn: 'FIRST TIME', subEn: 'YOU FELT SPECIAL WITH YOUR PARTNER', titleHi: 'पहली बार', subHi: 'जब पार्टनर के साथ खास लगा'),
    FirstCard(icon: '🎁', catKey: 'rel', titleEn: 'FIRST SPECIAL GIFT', subEn: 'YOU REMEMBER RECEIVING', titleHi: 'पहला खास तोहफ़ा', subHi: 'जो आपको मिला'),
    FirstCard(icon: '🛍️', catKey: 'rel', titleEn: 'FIRST GIFT', subEn: 'YOU BOUGHT FOR SOMEONE ELSE', titleHi: 'पहला तोहफ़ा', subHi: 'जो आपने किसी को दिया'),
    FirstCard(icon: '🐾', catKey: 'rel', titleEn: 'FIRST ANIMAL FRIEND', subEn: 'OR ANIMAL YOU CARED FOR', titleHi: 'पहला जानवर दोस्त', subHi: 'जिसकी आपने देखभाल की'),
    FirstCard(icon: '😢', catKey: 'rel', titleEn: 'FIRST TIME', subEn: 'YOU CRIED A LOT AS AN ADULT', titleHi: 'पहली बार', subHi: 'जब बड़े होकर खूब रोए'),
    // Personal Milestones
    FirstCard(icon: '💰', catKey: 'mil', titleEn: 'FIRST EARNING', subEn: 'YOU EVER MADE', titleHi: 'पहली कमाई', subHi: 'जो आपने की'),
    FirstCard(icon: '🏠', catKey: 'mil', titleEn: 'FIRST HOUSE', subEn: 'YOU EVER LIVED IN', titleHi: 'पहला घर', subHi: 'जहाँ आप रहे'),
    FirstCard(icon: '📱', catKey: 'mil', titleEn: 'FIRST PHONE', subEn: 'YOU EVER OWNED', titleHi: 'पहला फ़ोन', subHi: 'जो आपके पास था'),
    FirstCard(icon: '💼', catKey: 'mil', titleEn: 'FIRST JOB', subEn: 'OR WORK YOU GOT PAID FOR', titleHi: 'पहली नौकरी', subHi: 'या काम जिसका पैसा मिला'),
    FirstCard(icon: '📄', catKey: 'mil', titleEn: 'FIRST BILL', subEn: 'YOU PAID YOURSELF', titleHi: 'पहला बिल', subHi: 'जो आपने खुद भरा'),
    FirstCard(icon: '🏦', catKey: 'mil', titleEn: 'FIRST BANK VISIT', subEn: 'YOU REMEMBER', titleHi: 'पहली बैंक विज़िट', subHi: 'जो आपको याद है'),
    FirstCard(icon: '👨‍🍳', catKey: 'mil', titleEn: 'FIRST MEAL', subEn: 'YOU COOKED YOURSELF', titleHi: 'पहला खाना', subHi: 'जो आपने खुद बनाया'),
    FirstCard(icon: '🌆', catKey: 'mil', titleEn: 'FIRST CITY', subEn: 'YOU EVER LIVED IN', titleHi: 'पहला शहर', subHi: 'जहाँ आप रहे'),
    FirstCard(icon: '🚪', catKey: 'mil', titleEn: 'FIRST TIME', subEn: "YOU STEPPED OUT OF YOUR PARENTS' HOME", titleHi: 'पहली बार', subHi: 'जब माता-पिता का घर छोड़ा'),
    FirstCard(icon: '🚗', catKey: 'mil', titleEn: 'FIRST VEHICLE', subEn: 'YOU OWNED PERSONALLY OR AS A FAMILY', titleHi: 'पहला वाहन', subHi: 'जो आपका या परिवार का था'),
    FirstCard(icon: '🛒', catKey: 'mil', titleEn: 'FIRST THING', subEn: 'YOU BOUGHT WITH YOUR OWN MONEY', titleHi: 'पहली चीज़', subHi: 'जो अपने पैसों से खरीदी'),
    FirstCard(icon: '💎', catKey: 'mil', titleEn: 'FIRST JEWELLERY', subEn: 'OR ACCESSORY YOU OWNED', titleHi: 'पहला ज़ेवर', subHi: 'या एक्सेसरी जो आपके पास थी'),
    // School & Growing Up
    FirstCard(icon: '🏫', catKey: 'sch', titleEn: 'FIRST SCHOOL', subEn: 'YOU EVER ATTENDED', titleHi: 'पहला स्कूल', subHi: 'जहाँ आप पढ़े'),
    FirstCard(icon: '🎊', catKey: 'sch', titleEn: 'FIRST FESTIVAL', subEn: 'YOU ENJOYED AS A CHILD', titleHi: 'पहला त्योहार', subHi: 'जो बचपन में मनाया'),
    FirstCard(icon: '🏆', catKey: 'sch', titleEn: 'FIRST SUBJECT', subEn: 'YOU SCORED HIGHEST MARKS IN', titleHi: 'पहला विषय', subHi: 'जिसमें सबसे ज़्यादा नंबर आए'),
    FirstCard(icon: '🧸', catKey: 'sch', titleEn: 'FIRST TOY', subEn: 'YOU WERE OBSESSED WITH AS A CHILD', titleHi: 'पहला खिलौना', subHi: 'जिसका आप दीवाने थे'),
    FirstCard(icon: '😬', catKey: 'sch', titleEn: 'FIRST SUBJECT', subEn: 'YOU FAILED IN', titleHi: 'पहला विषय', subHi: 'जिसमें फेल हुए'),
    FirstCard(icon: '😈', catKey: 'sch', titleEn: 'FIRST TIME', subEn: 'YOU BUNKED A CLASS', titleHi: 'पहली बार बंकी', subHi: 'जब क्लास छोड़ी'),
    FirstCard(icon: '🤥', catKey: 'sch', titleEn: 'FIRST LIE', subEn: 'YOU TOLD AS A CHILD TO HIDE A MISTAKE', titleHi: 'पहला झूठ', subHi: 'जो बचपन में गलती छुपाने को बोला'),
    FirstCard(icon: '😅', catKey: 'sch', titleEn: 'FIRST TIME', subEn: 'YOU GOT INTO TROUBLE FOR SOMETHING NAUGHTY', titleHi: 'पहली बार शरारत में', subHi: 'जब पकड़े गए'),
    FirstCard(icon: '🎮', catKey: 'sch', titleEn: 'FIRST CHILDHOOD GAME', subEn: 'YOU ENJOYED PLAYING', titleHi: 'पहला बचपन का खेल', subHi: 'जो आपको बहुत पसंद था'),
    FirstCard(icon: '😄', catKey: 'sch', titleEn: 'FIRST NICKNAME', subEn: 'YOU EVER HAD', titleHi: 'पहला उपनाम', subHi: 'जो आपको मिला'),
    FirstCard(icon: '🍲', catKey: 'sch', titleEn: 'FIRST FOOD', subEn: 'YOU ENJOYED EATING THE MOST', titleHi: 'पहला खाना', subHi: 'जो आपको सबसे पसंद था'),
    FirstCard(icon: '🍮', catKey: 'sch', titleEn: 'FIRST DESSERT', subEn: 'YOU ENJOYED EATING THE MOST', titleHi: 'पहली मिठाई', subHi: 'जो आपको सबसे पसंद थी'),
    FirstCard(icon: '🤕', catKey: 'sch', titleEn: 'FIRST CHILDHOOD INJURY', subEn: 'YOU REMEMBER', titleHi: 'पहली चोट', subHi: 'जो बचपन में लगी थी'),
  ];
}
