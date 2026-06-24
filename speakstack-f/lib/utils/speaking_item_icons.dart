import 'package:flutter/material.dart';

/// Resolves a distinct Material icon for speaking hub list items.
IconData resolveSpeakingListIcon({
  required String title,
  String iconKey = '',
  String? slug,
}) {
  final trimmed = title.trim();
  if (trimmed.isNotEmpty) {
    final byTitle = _titleIcons[trimmed];
    if (byTitle != null) return byTitle;
  }

  final normalizedSlug = slug?.trim().toLowerCase();
  if (normalizedSlug != null && normalizedSlug.isNotEmpty) {
    final bySlug = _gameSlugIcons[normalizedSlug];
    if (bySlug != null) return bySlug;
  }

  if (iconKey.isNotEmpty) {
    final byKey = _keyIcons[iconKey];
    if (byKey != null) return byKey;
  }

  final fromKeywords = _iconFromTitleKeywords(trimmed);
  if (fromKeywords != null) return fromKeywords;

  return _iconFromTitleHash(trimmed.isEmpty ? iconKey : trimmed);
}

Color speakingIconAccent(String title) {
  final palette = _accentPalette;
  if (title.trim().isEmpty) return palette.first;
  return palette[title.hashCode.abs() % palette.length];
}

const _accentPalette = [
  Color(0xFF7A24E4),
  Color(0xFF2196F3),
  Color(0xFF1B9E4B),
  Color(0xFFFF9800),
  Color(0xFFE91E63),
  Color(0xFF009688),
  Color(0xFF5C6BC0),
  Color(0xFF8D6E63),
  Color(0xFF43A047),
  Color(0xFFFB8C00),
  Color(0xFF6A1B9A),
  Color(0xFF00838F),
];

const _gameSlugIcons = {
  'heroes-and-horrors': Icons.castle_outlined,
  'would-you-rather': Icons.compare_arrows_rounded,
  'emoji-pictionary': Icons.emoji_emotions_outlined,
  'cryptic-clues': Icons.manage_search_rounded,
  '20-questions': Icons.quiz_outlined,
  'quick-quill': Icons.draw_outlined,
};

const _keyIcons = {
  'restaurant': Icons.restaurant_menu_rounded,
  'work': Icons.work_outline_rounded,
  'school': Icons.school_outlined,
  'favorite': Icons.favorite_border_rounded,
  'travel': Icons.flight_takeoff_rounded,
  'hotel': Icons.hotel_rounded,
  'health': Icons.medical_services_outlined,
  'shopping': Icons.shopping_bag_outlined,
  'transport': Icons.directions_car_filled_outlined,
  'social': Icons.forum_outlined,
  'bank': Icons.account_balance_outlined,
  'movie': Icons.movie_creation_outlined,
  'library': Icons.local_library_outlined,
  'delivery': Icons.delivery_dining_rounded,
  'customs': Icons.luggage_outlined,
  'haircut': Icons.content_cut_rounded,
  'return': Icons.assignment_return_outlined,
  'birthday': Icons.cake_outlined,
  'home': Icons.home_outlined,
  'pets': Icons.pets_rounded,
  'food': Icons.restaurant_rounded,
  'holiday': Icons.celebration_outlined,
  'routine': Icons.schedule_rounded,
  'hobbies': Icons.interests_outlined,
  'music': Icons.music_note_outlined,
  'books': Icons.menu_book_rounded,
  'sports': Icons.sports_soccer_rounded,
  'weather': Icons.wb_sunny_outlined,
  'fashion': Icons.checkroom_outlined,
  'garden': Icons.yard_outlined,
  'camping': Icons.park_outlined,
  'crafts': Icons.brush_outlined,
  'gaming': Icons.sports_esports_outlined,
  'furniture': Icons.chair_outlined,
  'amusement': Icons.attractions_outlined,
  'art': Icons.palette_outlined,
  'memory': Icons.history_edu_outlined,
  'dragon': Icons.auto_stories_rounded,
  'would_you_rather': Icons.compare_arrows_rounded,
  'emoji': Icons.emoji_emotions_outlined,
  'detective': Icons.manage_search_rounded,
  'question': Icons.quiz_outlined,
  'quill': Icons.draw_outlined,
  'theater_comedy': Icons.theater_comedy_outlined,
};

const _titleIcons = {
  // Role-play scenarios
  'Ordering at a restaurant': Icons.restaurant_menu_rounded,
  'Practicing a job interview': Icons.badge_outlined,
  'Taking a formal speaking test': Icons.record_voice_over_outlined,
  'On a first date': Icons.local_cafe_rounded,
  'Taking an IELTS speaking test': Icons.translate_rounded,
  'Scheduling a dentist appointment': Icons.medical_services_outlined,
  'Reserving a hotel room': Icons.hotel_rounded,
  'Making weekend plans with a friend': Icons.event_outlined,
  'Meeting a new neighbor': Icons.waving_hand_outlined,
  'Ordering food delivery': Icons.delivery_dining_rounded,
  'Passing through customs': Icons.luggage_outlined,
  'Getting a haircut': Icons.content_cut_rounded,
  'Returning a purchase': Icons.assignment_return_outlined,
  'Starting a bank account': Icons.account_balance_wallet_outlined,
  'Planning a birthday party': Icons.cake_outlined,
  'Buying movie tickets': Icons.local_movies_outlined,
  "Getting someone's contact information": Icons.contact_page_outlined,
  'Shopping for new shoes': Icons.shopping_bag_outlined,
  'Ordering a taxi': Icons.local_taxi_rounded,
  'Requesting a library book': Icons.local_library_outlined,
  'Reporting a problem to the landlord': Icons.home_repair_service_outlined,
  'Booking a flight': Icons.flight_rounded,
  'Attending a job fair': Icons.work_history_rounded,
  'Planning a road trip': Icons.map_outlined,
  'Consulting a nutritionist': Icons.monitor_weight_outlined,
  'Attending a networking event': Icons.hub_outlined,
  'Meeting with a life coach': Icons.self_improvement_outlined,
  'Apologizing to a friend': Icons.favorite_border_rounded,
  'Asking for a recommendation letter': Icons.mail_outline_rounded,
  'Negotiating a raise at work': Icons.trending_up_rounded,
  'Discussing a career change with a career counselor': Icons.swap_horiz_rounded,
  'Filing an insurance claim': Icons.shield_outlined,
  'Ordering a drink at a café': Icons.coffee_outlined,
  'Bargaining at a local market': Icons.storefront_outlined,
  'Joining a gym': Icons.fitness_center_rounded,
  'Asking for help after losing a wallet': Icons.wallet_outlined,
  'Renting sport equipment': Icons.downhill_skiing_rounded,
  'Discussing a workout plan with a personal trainer': Icons.directions_run_rounded,
  "Applying for a driver's license": Icons.badge_outlined,
  'Planning a wedding with an event planner': Icons.favorite_rounded,
  'Discussing a home renovation project': Icons.construction_rounded,
  'Pitching a business idea to investors': Icons.rocket_launch_outlined,
  'Leading a team meeting at work': Icons.groups_outlined,
  'Receiving a performance review': Icons.assessment_outlined,
  'Mediating a workplace conflict': Icons.balance_rounded,
  'Brainstorming a new project proposal at work': Icons.lightbulb_outline_rounded,
  'Onboarding a new team member': Icons.person_add_alt_1_outlined,
  'Discussing budget allocation with department heads': Icons.pie_chart_outline_rounded,
  'Talking about new company policies': Icons.policy_outlined,
  'Pitching a screenplay to a film producer': Icons.movie_filter_outlined,
  'Discussing work-life balance with a supervisor': Icons.hourglass_bottom_rounded,
  'Handling a customer complaint': Icons.support_agent_rounded,
  'Buying a car': Icons.directions_car_filled_outlined,
  'Renting an apartment': Icons.apartment_rounded,
  'Adopting a pet': Icons.pets_rounded,
  'Negotiating chores with roommates': Icons.cleaning_services_outlined,
  'Requesting a refund for a cancelled flight': Icons.flight_takeoff_rounded,
  // Speaking games
  'Heroes & Horrors': Icons.castle_outlined,
  'Would You Rather': Icons.compare_arrows_rounded,
  'Emoji Pictionary': Icons.emoji_emotions_outlined,
  'Cryptic Clues': Icons.manage_search_rounded,
  '20 Questions': Icons.quiz_outlined,
  'Quick Quill': Icons.draw_outlined,
  // Intermediate topics
  'Hobbies': Icons.interests_outlined,
  'Workplace and Jobs': Icons.work_outline_rounded,
  'Family': Icons.family_restroom_outlined,
  'Daily Routines': Icons.schedule_rounded,
  'Travel': Icons.flight_takeoff_rounded,
  'Food and Dining': Icons.restaurant_rounded,
  'Holidays': Icons.celebration_outlined,
  'Shopping': Icons.shopping_cart_outlined,
  'Music and Instruments': Icons.music_note_outlined,
  'Books': Icons.menu_book_rounded,
  'Social Media': Icons.share_outlined,
  'Sports': Icons.sports_soccer_rounded,
  'Weather': Icons.wb_sunny_outlined,
  'Pets': Icons.pets_rounded,
  'Fashion': Icons.checkroom_outlined,
  'Cooking': Icons.soup_kitchen_outlined,
  'Household Chores': Icons.cleaning_services_outlined,
  'Time and Calendar': Icons.calendar_month_outlined,
  'Fitness': Icons.fitness_center_rounded,
  'Local Attractions': Icons.place_outlined,
  'Gardening': Icons.yard_outlined,
  'Volunteering': Icons.volunteer_activism_outlined,
  'Childhood Memories': Icons.child_care_outlined,
  'Weddings': Icons.favorite_rounded,
  'Festivals': Icons.festival_outlined,
  'Home Decor': Icons.chair_outlined,
  'Camping': Icons.park_outlined,
  'Crafts': Icons.brush_outlined,
  'Emotions': Icons.sentiment_satisfied_alt_outlined,
  'Gaming': Icons.sports_esports_rounded,
  'Celebrities': Icons.star_outline_rounded,
  'Furniture': Icons.weekend_outlined,
  'Amusement Parks': Icons.attractions_outlined,
  'Cars and Driving': Icons.directions_car_filled_outlined,
  'Friendship': Icons.people_outline_rounded,
  // Advanced topics
  'Money': Icons.payments_outlined,
  'History': Icons.history_edu_outlined,
  'Business': Icons.business_center_outlined,
  'Geography': Icons.public_outlined,
  'Entertainment': Icons.theaters_outlined,
  'Idioms': Icons.format_quote_outlined,
  'Slang': Icons.chat_bubble_outline_rounded,
  'Education': Icons.school_outlined,
  'Health and Fitness': Icons.monitor_heart_outlined,
  'Art': Icons.palette_outlined,
  'Agriculture': Icons.agriculture_outlined,
  'Restaurants': Icons.restaurant_menu_rounded,
  'Traditions': Icons.temple_buddhist_outlined,
  'Personality': Icons.psychology_outlined,
  'Podcasts': Icons.podcasts_outlined,
  'Relationships': Icons.favorite_border_rounded,
  'Public Transportation': Icons.directions_bus_outlined,
  'Technology': Icons.devices_outlined,
  'Photography': Icons.photo_camera_outlined,
  'Natural Disasters': Icons.thunderstorm_outlined,
  'Entrepreneurship': Icons.rocket_launch_outlined,
  'Retirement and Aging': Icons.elderly_outlined,
  'Architecture': Icons.account_balance_outlined,
  'Humor': Icons.sentiment_very_satisfied_outlined,
  'Parenting': Icons.escalator_warning_outlined,
  'Social Issues': Icons.groups_outlined,
  'Tourism': Icons.landscape_outlined,
  'Environmentalism': Icons.eco_outlined,
  'Psychology': Icons.psychology_alt_outlined,
  'Advertising': Icons.campaign_outlined,
  'Dating': Icons.favorite_outline_rounded,
  'Urban Planning': Icons.location_city_outlined,
  'Inventions': Icons.lightbulb_outline_rounded,
  'Pop Culture': Icons.movie_outlined,
  'Charities': Icons.volunteer_activism_outlined,
  'Self Improvement': Icons.self_improvement_outlined,
  // Expert topics
  'Philosophy and Politics': Icons.balance_rounded,
  'Religion and Superstitions': Icons.church_outlined,
  'Law': Icons.gavel_rounded,
  'Outer Space': Icons.rocket_outlined,
  'Globalism': Icons.language_outlined,
  'Government': Icons.account_balance_outlined,
  'Mythology': Icons.auto_stories_rounded,
  'Anthropology': Icons.groups_3_outlined,
  'Current Affairs': Icons.newspaper_outlined,
  'Ethics': Icons.rule_outlined,
  'Taxes': Icons.receipt_long_outlined,
  'Film Analysis': Icons.movie_filter_outlined,
  'Economics': Icons.show_chart_rounded,
  'Nutrition': Icons.restaurant_menu_rounded,
  'Virtual Reality': Icons.view_in_ar_outlined,
  'Journalism': Icons.article_outlined,
  'Energy': Icons.bolt_outlined,
  'Futurism': Icons.auto_awesome_outlined,
  'Astrology': Icons.nightlight_round_outlined,
  'International Relations': Icons.handshake_outlined,
  'Existentialism': Icons.cloud_outlined,
  'Bioethics': Icons.biotech_outlined,
  'Surveillance': Icons.videocam_outlined,
  'Transhumanism': Icons.memory_outlined,
  'Artificial Intelligence': Icons.smart_toy_outlined,
  'Conspiracy Theories': Icons.visibility_off_outlined,
  'Censorship': Icons.block_outlined,
  'Human Rights': Icons.diversity_3_outlined,
  'Automation': Icons.precision_manufacturing_outlined,
};

const _keywordIcons = [
  (['interview', 'job fair', 'resume'], Icons.badge_outlined),
  (['wedding', 'birthday', 'date'], Icons.favorite_rounded),
  (['flight', 'travel', 'customs', 'taxi', 'road trip'], Icons.flight_takeoff_rounded),
  (['bank', 'insurance', 'money', 'refund'], Icons.account_balance_outlined),
  (['restaurant', 'café', 'food', 'delivery'], Icons.restaurant_rounded),
  (['haircut', 'salon'], Icons.content_cut_rounded),
  (['gym', 'workout', 'fitness', 'trainer'], Icons.fitness_center_rounded),
  (['pet', 'adopt'], Icons.pets_rounded),
  (['movie', 'cinema', 'screenplay'], Icons.movie_outlined),
  (['landlord', 'apartment', 'home', 'renovation'], Icons.home_outlined),
  (['meeting', 'team', 'manager', 'work'], Icons.groups_outlined),
  (['school', 'exam', 'ielts', 'test'], Icons.school_outlined),
  (['shop', 'purchase', 'market', 'shoes'], Icons.shopping_bag_outlined),
  (['doctor', 'dentist', 'health', 'nutrition'], Icons.medical_services_outlined),
  (['library', 'book'], Icons.menu_book_rounded),
  (['car', 'driver', 'license'], Icons.directions_car_filled_outlined),
  (['wallet', 'lost'], Icons.wallet_outlined),
  (['neighbor', 'friend', 'roommate'], Icons.people_outline_rounded),
  (['hotel'], Icons.hotel_rounded),
  (['game', 'play'], Icons.sports_esports_rounded),
];

const _hashIconPool = [
  Icons.lightbulb_outline_rounded,
  Icons.explore_outlined,
  Icons.flag_outlined,
  Icons.anchor_outlined,
  Icons.beach_access_outlined,
  Icons.cabin_outlined,
  Icons.diamond_outlined,
  Icons.eco_outlined,
  Icons.extension_outlined,
  Icons.forest_outlined,
  Icons.grass_outlined,
  Icons.hiking_outlined,
  Icons.kitesurfing_outlined,
  Icons.landscape_outlined,
  Icons.local_florist_outlined,
  Icons.nightlight_round_outlined,
  Icons.piano_outlined,
  Icons.ramen_dining_rounded,
  Icons.sailing_outlined,
  Icons.science_outlined,
  Icons.spa_outlined,
  Icons.surfing_outlined,
  Icons.temple_hindu_outlined,
  Icons.water_drop_outlined,
];

IconData? _iconFromTitleKeywords(String title) {
  final lower = title.toLowerCase();
  for (final entry in _keywordIcons) {
    for (final keyword in entry.$1) {
      if (lower.contains(keyword)) return entry.$2;
    }
  }
  return null;
}

IconData _iconFromTitleHash(String seed) {
  if (seed.isEmpty) return Icons.chat_bubble_outline_rounded;
  return _hashIconPool[seed.hashCode.abs() % _hashIconPool.length];
}

/// Backwards-compatible key lookup used by older call sites.
IconData speakingIconForKey(String key) {
  return resolveSpeakingListIcon(title: '', iconKey: key);
}
