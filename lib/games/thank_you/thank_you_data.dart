import 'package:flutter/material.dart';

/// One "Thank You" gratitude card. Note: the category label (`cat`) has no
/// Hindi translation in the original source — it always displays in
/// English regardless of language, reproduced faithfully here.
class ThankYouCard {
  final String titleEn;
  final String subEn;
  final String titleHi;
  final String subHi;
  final String icon;
  final String cat;
  final int paletteIndex; // 1-6, cycles through ThankYouData.palette
  const ThankYouCard({
    required this.titleEn,
    required this.subEn,
    required this.titleHi,
    required this.subHi,
    required this.icon,
    required this.cat,
    required this.paletteIndex,
  });
}

class ThankYouData {
  ThankYouData._();

  static const List<Color> palette = [
    Color(0xFF1A6B3C),
    Color(0xFF0F5A6E),
    Color(0xFF5A3A1A),
    Color(0xFF6E1A5A),
    Color(0xFF1A3A6E),
    Color(0xFF5A1A1A),
  ];

  static const List<ThankYouCard> cards = [
    ThankYouCard(paletteIndex: 1, icon: '⚡', cat: 'Everyday Things', titleEn: 'ONE ELECTRIC APPLIANCE', subEn: 'YOU ARE THANKFUL FOR', titleHi: 'एक बिजली का उपकरण', subHi: 'जिसके लिए आप शुक्रगुज़ार हैं'),
    ThankYouCard(paletteIndex: 2, icon: '🌤️', cat: 'Nature', titleEn: 'ONE WEATHER OR SEASON', subEn: 'YOU ARE GRATEFUL FOR', titleHi: 'एक मौसम', subHi: 'जिसके लिए आप आभारी हैं'),
    ThankYouCard(paletteIndex: 3, icon: '❤️', cat: 'Your Body', titleEn: 'AN ORGAN IN YOUR BODY', subEn: 'YOU ARE THANKFUL FOR', titleHi: 'एक अंग', subHi: 'जिसके लिए आप शुक्रगुज़ार हैं'),
    ThankYouCard(paletteIndex: 4, icon: '🤝', cat: 'People', titleEn: 'ONE FRIEND', subEn: 'YOU ARE DEEPLY GRATEFUL FOR', titleHi: 'एक दोस्त', subHi: 'जिनके लिए आप गहरे आभारी हैं'),
    ThankYouCard(paletteIndex: 5, icon: '👩‍🏫', cat: 'People', titleEn: 'ONE TEACHER', subEn: 'YOU ARE THANKFUL FOR', titleHi: 'एक टीचर', subHi: 'जिनके लिए आप शुक्रगुज़ार हैं'),
    ThankYouCard(paletteIndex: 6, icon: '👨‍👩‍👧', cat: 'Family', titleEn: 'ONE RELATIVE OR FAMILY MEMBER', subEn: 'YOU ARE GRATEFUL FOR', titleHi: 'एक रिश्तेदार या परिवार का सदस्य', subHi: 'जिनके लिए आप आभारी हैं'),
    ThankYouCard(paletteIndex: 1, icon: '👕', cat: 'Everyday Things', titleEn: 'ONE PIECE OF CLOTHING', subEn: 'YOU ARE THANKFUL FOR', titleHi: 'कपड़े का एक टुकड़ा', subHi: 'जिसके लिए आप शुक्रगुज़ार हैं'),
    ThankYouCard(paletteIndex: 2, icon: '☕', cat: 'Food & Drink', titleEn: 'ONE BEVERAGE', subEn: 'YOU ARE GRATEFUL FOR', titleHi: 'एक पेय पदार्थ', subHi: 'जिसके लिए आप आभारी हैं'),
    ThankYouCard(paletteIndex: 3, icon: '🍲', cat: 'Food & Drink', titleEn: 'ONE FOOD ITEM', subEn: 'YOU ARE THANKFUL FOR', titleHi: 'एक खाने की चीज़', subHi: 'जिसके लिए आप शुक्रगुज़ार हैं'),
    ThankYouCard(paletteIndex: 4, icon: '🎬', cat: 'Arts & Culture', titleEn: 'ONE MOVIE', subEn: 'YOU ARE GRATEFUL FOR', titleHi: 'एक फ़िल्म', subHi: 'जिसके लिए आप आभारी हैं'),
    ThankYouCard(paletteIndex: 5, icon: '🎵', cat: 'Arts & Culture', titleEn: 'ONE SONG', subEn: 'YOU ARE THANKFUL FOR', titleHi: 'एक गाना', subHi: 'जिसके लिए आप शुक्रगुज़ार हैं'),
    ThankYouCard(paletteIndex: 6, icon: '🎨', cat: 'Arts & Culture', titleEn: 'ONE ARTIST', subEn: 'ALIVE OR NOT, YOU ARE GRATEFUL FOR', titleHi: 'एक कलाकार', subHi: 'जीवित हो या न हो, आभारी हैं'),
    ThankYouCard(paletteIndex: 1, icon: '👑', cat: 'Society', titleEn: 'ONE LEADER', subEn: 'ALIVE OR NOT, YOU ARE THANKFUL FOR', titleHi: 'एक नेता', subHi: 'जीवित हो या न हो, आभारी हैं'),
    ThankYouCard(paletteIndex: 2, icon: '⚽', cat: 'Lifestyle', titleEn: 'ONE SPORT', subEn: 'YOU ARE GRATEFUL FOR', titleHi: 'एक खेल', subHi: 'जिसके लिए आप शुक्रगुज़ार हैं'),
    ThankYouCard(paletteIndex: 3, icon: '🌅', cat: 'Lifestyle', titleEn: 'ONE DAILY ROUTINE', subEn: 'YOU ARE THANKFUL FOR', titleHi: 'एक रोज़ाना की दिनचर्या', subHi: 'जिसके लिए आप आभारी हैं'),
    ThankYouCard(paletteIndex: 4, icon: '🧸', cat: 'Memories', titleEn: 'ONE CHILDHOOD MEMORY', subEn: 'YOU ARE DEEPLY GRATEFUL FOR', titleHi: 'एक बचपन की याद', subHi: 'जिसके लिए आप गहरे आभारी हैं'),
    ThankYouCard(paletteIndex: 5, icon: '📐', cat: 'Learning', titleEn: 'ONE SCHOOL SUBJECT', subEn: 'YOU ARE THANKFUL FOR', titleHi: 'एक स्कूल का विषय', subHi: 'जिसके लिए आप शुक्रगुज़ार हैं'),
    ThankYouCard(paletteIndex: 6, icon: '📖', cat: 'Learning', titleEn: 'ONE BOOK', subEn: 'YOU ARE GRATEFUL FOR', titleHi: 'एक किताब', subHi: 'जिसके लिए आप आभारी हैं'),
    ThankYouCard(paletteIndex: 1, icon: '💡', cat: 'Wisdom', titleEn: 'ONE LIFE LESSON', subEn: 'YOU ARE THANKFUL FOR', titleHi: 'एक जीवन की सीख', subHi: 'जिसके लिए आप शुक्रगुज़ार हैं'),
    ThankYouCard(paletteIndex: 2, icon: '🛋️', cat: 'Home', titleEn: 'ONE PIECE OF FURNITURE', subEn: 'YOU ARE GRATEFUL FOR', titleHi: 'फ़र्नीचर का एक टुकड़ा', subHi: 'जिसके लिए आप आभारी हैं'),
    ThankYouCard(paletteIndex: 3, icon: '🏖️', cat: 'Experiences', titleEn: 'ONE HOLIDAY', subEn: 'YOU ARE THANKFUL FOR', titleHi: 'एक छुट्टी', subHi: 'जिसके लिए आप शुक्रगुज़ार हैं'),
    ThankYouCard(paletteIndex: 4, icon: '🏡', cat: 'Family', titleEn: 'ONE FAMILY TRADITION', subEn: 'YOU ARE GRATEFUL FOR', titleHi: 'एक पारिवारिक परंपरा', subHi: 'जिसके लिए आप आभारी हैं'),
    ThankYouCard(paletteIndex: 5, icon: '🎊', cat: 'Culture', titleEn: 'ONE FESTIVAL', subEn: 'YOU ARE THANKFUL FOR', titleHi: 'एक त्योहार', subHi: 'जिसके लिए आप शुक्रगुज़ार हैं'),
    ThankYouCard(paletteIndex: 6, icon: '💑', cat: 'Relationships', titleEn: 'ONE TRAIT IN YOUR PARTNER', subEn: 'YOU ARE DEEPLY GRATEFUL FOR', titleHi: 'पार्टनर की एक खूबी', subHi: 'जिसके लिए आप गहरे आभारी हैं'),
    ThankYouCard(paletteIndex: 1, icon: '🌟', cat: 'Self', titleEn: 'ONE TRAIT IN YOURSELF', subEn: 'YOU ARE THANKFUL FOR', titleHi: 'अपने आप की एक खूबी', subHi: 'जिसके लिए आप शुक्रगुज़ार हैं'),
    ThankYouCard(paletteIndex: 2, icon: '👶', cat: 'Family', titleEn: 'ONE TRAIT IN YOUR CHILD', subEn: 'YOU ARE GRATEFUL FOR', titleHi: 'बच्चे की एक खूबी', subHi: 'जिसके लिए आप आभारी हैं'),
    ThankYouCard(paletteIndex: 3, icon: '🧑', cat: 'Family', titleEn: 'ONE TRAIT IN YOUR BROTHER', subEn: 'YOU ARE THANKFUL FOR', titleHi: 'भाई की एक खूबी', subHi: 'जिसके लिए आप शुक्रगुज़ार हैं'),
    ThankYouCard(paletteIndex: 4, icon: '👧', cat: 'Family', titleEn: 'ONE TRAIT IN YOUR SISTER', subEn: 'YOU ARE GRATEFUL FOR', titleHi: 'बहन की एक खूबी', subHi: 'जिसके लिए आप आभारी हैं'),
    ThankYouCard(paletteIndex: 5, icon: '🌸', cat: 'Nature', titleEn: 'ONE FLOWER', subEn: 'YOU ARE THANKFUL FOR', titleHi: 'एक फूल', subHi: 'जिसके लिए आप शुक्रगुज़ार हैं'),
    ThankYouCard(paletteIndex: 6, icon: '🌊', cat: 'Nature', titleEn: 'ONE NATURAL FORCE', subEn: 'WIND, WATER, SOIL OR SUNRAYS', titleHi: 'एक प्राकृतिक शक्ति', subHi: 'हवा, पानी, मिट्टी या धूप'),
    ThankYouCard(paletteIndex: 1, icon: '📱', cat: 'Technology', titleEn: 'ONE SOCIAL MEDIA PLATFORM', subEn: 'YOU ARE GRATEFUL FOR', titleHi: 'एक सोशल मीडिया प्लेटफ़ॉर्म', subHi: 'जिसके लिए आप आभारी हैं'),
    ThankYouCard(paletteIndex: 2, icon: '💊', cat: 'Health', titleEn: 'ONE MEDICAL INVENTION', subEn: 'YOU ARE THANKFUL FOR', titleHi: 'एक चिकित्सा आविष्कार', subHi: 'जिसके लिए आप शुक्रगुज़ार हैं'),
    ThankYouCard(paletteIndex: 3, icon: '✊', cat: 'Society', titleEn: 'ONE CULTURAL REFORM', subEn: 'YOU ARE GRATEFUL FOR', titleHi: 'एक सांस्कृतिक सुधार', subHi: 'जिसके लिए आप आभारी हैं'),
    ThankYouCard(paletteIndex: 4, icon: '💍', cat: 'Everyday Things', titleEn: 'ONE ACCESSORY YOU OWN', subEn: 'YOU ARE THANKFUL FOR', titleHi: 'एक एक्सेसरी', subHi: 'जिसके लिए आप शुक्रगुज़ार हैं'),
    ThankYouCard(paletteIndex: 5, icon: '🚗', cat: 'Everyday Things', titleEn: 'ONE VEHICLE', subEn: 'YOU ARE GRATEFUL FOR', titleHi: 'एक वाहन', subHi: 'जिसके लिए आप आभारी हैं'),
    ThankYouCard(paletteIndex: 6, icon: '🧑‍💼', cat: 'People', titleEn: 'ONE PROFESSIONAL MENTOR', subEn: 'YOU ARE THANKFUL FOR', titleHi: 'एक पेशेवर मेंटर', subHi: 'जिनके लिए आप शुक्रगुज़ार हैं'),
    ThankYouCard(paletteIndex: 1, icon: '🎯', cat: 'Lifestyle', titleEn: 'ONE HOBBY OR SKILL', subEn: 'YOU ARE GRATEFUL FOR', titleHi: 'एक शौक या हुनर', subHi: 'जिसके लिए आप आभारी हैं'),
    ThankYouCard(paletteIndex: 2, icon: '🙌', cat: 'Reflection', titleEn: 'ONE PRIVILEGE YOU HAVE', subEn: 'NOT EVERYONE GETS', titleHi: 'एक सुविधा जो आपके पास है', subHi: 'जो सबको नहीं मिलती'),
    ThankYouCard(paletteIndex: 3, icon: '🗺️', cat: 'Identity', titleEn: 'ONE THING ABOUT YOUR COUNTRY', subEn: 'YOU ARE THANKFUL FOR', titleHi: 'अपने देश की एक बात', subHi: 'जिसके लिए आप शुक्रगुज़ार हैं'),
    ThankYouCard(paletteIndex: 4, icon: '🎭', cat: 'Identity', titleEn: 'ONE THING ABOUT YOUR CULTURE', subEn: 'YOU ARE GRATEFUL FOR', titleHi: 'अपनी संस्कृति की एक बात', subHi: 'जिसके लिए आप आभारी हैं'),
    ThankYouCard(paletteIndex: 5, icon: '🥄', cat: 'Home', titleEn: 'ONE UTENSIL', subEn: 'YOU ARE THANKFUL FOR', titleHi: 'एक बर्तन', subHi: 'जिसके लिए आप शुक्रगुज़ार हैं'),
    ThankYouCard(paletteIndex: 6, icon: '📸', cat: 'Memories', titleEn: 'ONE PHOTO OR VIDEO', subEn: 'PRIVATE & PERSONAL, YOU TREASURE', titleHi: 'एक फ़ोटो या वीडियो', subHi: 'जो निजी और खास है'),
    ThankYouCard(paletteIndex: 1, icon: '🎉', cat: 'Memories', titleEn: 'ONE FUN MEMORY WITH FRIENDS', subEn: 'YOU ARE DEEPLY GRATEFUL FOR', titleHi: 'दोस्तों के साथ एक मज़ेदार याद', subHi: 'जिसके लिए आप गहरे आभारी हैं'),
    ThankYouCard(paletteIndex: 2, icon: '🏆', cat: 'Growth', titleEn: 'ONE PERSONAL ACHIEVEMENT', subEn: 'YOU ARE THANKFUL FOR', titleHi: 'एक निजी उपलब्धि', subHi: 'जिसके लिए आप शुक्रगुज़ार हैं'),
    ThankYouCard(paletteIndex: 3, icon: '👩', cat: 'Family', titleEn: 'A TRAIT IN YOUR MOTHER', subEn: 'YOU ARE THANKFUL FOR', titleHi: 'माँ की एक खूबी', subHi: 'जिसके लिए आप शुक्रगुज़ार हैं'),
    ThankYouCard(paletteIndex: 4, icon: '👨', cat: 'Family', titleEn: 'A TRAIT IN YOUR FATHER', subEn: 'YOU ARE THANKFUL FOR', titleHi: 'पिता की एक खूबी', subHi: 'जिसके लिए आप आभारी हैं'),
    ThankYouCard(paletteIndex: 5, icon: '🤝', cat: 'People', titleEn: 'A TRAIT IN YOUR BEST FRIEND', subEn: 'YOU ARE GRATEFUL FOR', titleHi: 'सबसे अच्छे दोस्त की एक खूबी', subHi: 'जिसके लिए आप शुक्रगुज़ार हैं'),
    ThankYouCard(paletteIndex: 6, icon: '💡', cat: 'Everyday Things', titleEn: 'ONE MODERN FACILITY', subEn: 'ELECTRICITY, GAS, INTERNET & WHY', titleHi: 'एक आधुनिक सुविधा', subHi: 'बिजली, गैस, इंटरनेट और क्यों'),
    ThankYouCard(paletteIndex: 1, icon: '🧖', cat: 'Lifestyle', titleEn: 'ONE SELF CARE ROUTINE', subEn: 'OR PRODUCT YOU DISCOVERED', titleHi: 'एक सेल्फ केयर रूटीन', subHi: 'या प्रोडक्ट जो आपने खोजा'),
    ThankYouCard(paletteIndex: 2, icon: '✅', cat: 'Growth', titleEn: 'ONE HABIT', subEn: 'YOU FIND TRULY USEFUL', titleHi: 'एक आदत', subHi: 'जो आपको बहुत उपयोगी लगती है'),
    ThankYouCard(paletteIndex: 3, icon: '✨', cat: 'Reflection', titleEn: 'ONE LUXURY', subEn: 'YOU ARE GLAD YOU CAN AFFORD', titleHi: 'एक ऐलिश चीज़', subHi: 'जो आप अफ़ोर्ड कर पाते हैं'),
  ];
}
