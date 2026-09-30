import '../services/transaction_service.dart';

class SpendingNudge {
  static const _fixedThreshold = 3;
  static const _percentThreshold = 0.30;

  static String? check(String category, double amount) {
    final now = DateTime.now();
    final allTx = TransactionService.getAll();

    final monthlyExpenses = allTx.where(
      (t) =>
          t.isExpense && t.date.month == now.month && t.date.year == now.year,
    );

    final categoryTx = monthlyExpenses
        .where((t) => t.category == category)
        .toList();

    final categoryTotal = categoryTx.fold(0.0, (sum, t) => sum + t.amount);
    final monthlyTotal = monthlyExpenses.fold(0.0, (sum, t) => sum + t.amount);

    final countHit = categoryTx.length >= _fixedThreshold;
    final percentHit =
        monthlyTotal > 0 && (categoryTotal / monthlyTotal) >= _percentThreshold;

    if (!countHit && !percentHit) return null;

    final isReallyBad =
        categoryTx.length >= 5 ||
        (monthlyTotal > 0 && (categoryTotal / monthlyTotal) >= 0.5);

    return _pick(category, categoryTx.length, isReallyBad);
  }

  static String _pick(String category, int count, bool isReallyBad) {
    final messages = _messages[category] ?? _messages['default']!;
    final pool = isReallyBad ? messages['savage']! : messages['gentle']!;
    pool.shuffle();
    return pool.first;
  }

  static final _messages = <String, Map<String, List<String>>>{
    'Food & Drink': {
      'gentle': [
        'Hermyonie, this is your third food trip this month. Cute. 🌸 Just noting it.',
        'Hey Hermyonie, your stomach is happy. Your budget is... adjusting. That\'s okay.',
        'Denny, you\'ve been eating well. No judgment. Just a soft reminder the budget exists.',
        'Hermyonie, the food spending is adding up. You\'re still doing great though. 🍜',
      ],
      'savage': [
        'Denzel. The budget. Remember that? You made one. It had rules.',
        'Denny, at what point does the food app just become your personality.',
        'Denzel, your wallet is not a restaurant. Stop treating it like a buffet.',
        'You have a budget, Denny. It\'s just watching from a distance at this point. 👀',
      ],
    },
    'Shopping': {
      'gentle': [
        'Hermyonie, your cart has been busy this month. You good? 🛍️',
        'Denny, just checking in. The shopping is adding up a little.',
        'Hermyonie, treating yourself is valid. Budget just wants to be included too. 🌷',
      ],
      'savage': [
        'Denzel. The checkout button is not a coping mechanism. We talked about this.',
        'Denny, you have a budget. It is crying. In the corner. Alone.',
        'Denzel, the items are arriving faster than your savings are growing. Just saying.',
        'At this point Denny, the budget is just decorative. Is that what we want? 🛒',
      ],
    },
    'Entertainment': {
      'gentle': [
        'Hermyonie, you\'ve been having fun this month. That\'s honestly valid. 🎬',
        'Denny, entertainment is self-care. Just making sure the budget agrees.',
        'Hermyonie, living your life. Love that for you. Wallet is just keeping tabs. 🌸',
        'Denny, you deserve good things. Just... maybe not all of them this month.',
      ],
      'savage': [
        'Denzel. You have a budget. You also have a streaming subscription. And went out. And bought game credits. In the same month.',
        'Denny, the entertainment spending has entered its villain arc and we are concerned.',
        'Denzel, no explanation needed apparently. But the budget would love one.',
        'You just did it again, Denny. No hesitation. No remorse. Iconic. Expensive. 💸',
        'Denzel, the budget you made is sitting there like a disappointed parent right now.',
      ],
    },
    'Transport': {
      'gentle': [
        'Hermyonie, you\'ve been on the move this month. 🚗 Noted with love.',
        'Denny, lots of rides lately. Just keeping an eye on it for you.',
        'Hermyonie, your commute is costing more than expected this month. You\'re fine though.',
      ],
      'savage': [
        'Denzel, does Grab have a loyalty program? Because you might qualify at this point.',
        'Denny, the transport spending is wild. Have you considered... walking. Once.',
        'Denzel. Feet exist. The budget is begging you to remember that.',
      ],
    },
    'Health': {
      'gentle': [
        'Hermyonie, taking care of yourself is always worth it. 💊 Just tracking it.',
        'Denny, health first. Budget is just noting it, not judging.',
        'Hermyonie, your body thanks you. We\'re just keeping the numbers honest. 🌷',
      ],
      'savage': [
        'Denzel, maybe the most healing thing right now is resting the wallet too.',
        'Denny, the health spending is high. Which means either you\'re very healthy or very not. Either way, noted.',
      ],
    },
    'Personal Care': {
      'gentle': [
        'Hermyonie, glowing up is valid. We see you. 💅',
        'Denny, self-care spending noted. You deserve to feel good.',
        'Hermyonie, the skincare is thriving. Budget just wants a mention too. 🌸',
      ],
      'savage': [
        'Denzel, the serums are eating well. The savings are not.',
        'Denny, you have a budget. Your skincare routine does not know that.',
        'Denzel, you are one product away from a budget crisis and we say this with love and concern.',
      ],
    },
    'Bills & Utilities': {
      'gentle': [
        'Hermyonie, adulting is expensive. You\'re handling it. 💪',
        'Denny, bills are bills. Just making sure everything\'s accounted for.',
      ],
      'savage': [
        'Denzel, the bills are not playing this month. Neither is the budget.',
        'Denny, the utilities said pay me. The budget said same. Tough crowd.',
      ],
    },
    'default': {
      'gentle': [
        'Hermyonie, this category\'s been getting a workout this month. 👀',
        'Denny, just a nudge. This is adding up quietly.',
        'Hermyonie, the budget is watching. Lovingly. But watching. 🌸',
      ],
      'savage': [
        'Denzel. You have a budget. It has been very patient. That patience is running out.',
        'Denny, no explanation as usual. The budget would just like to be acknowledged.',
        'Denzel, at this point the budget is just vibes and prayers and we made it together.',
      ],
    },
  }; // closes _messages
} // closes SpendingNudge class
