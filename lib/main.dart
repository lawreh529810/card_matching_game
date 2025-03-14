import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => GameProvider(),
      child: const CardMatchingGame(),
    ),
  );
}

class CardMatchingGame extends StatelessWidget {
  const CardMatchingGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Matching Game',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const GameScreen(),
    );
  }
}

class GameProvider extends ChangeNotifier {
  final int gridSize = 4;
  List<CardModel> cards = [];
  int score = 0;
  int matchesFound = 0;
  bool timerRunning = false;
  int timeElapsed = 0;
  Timer? _timer;
  CardModel? firstSelectedCard;

  GameProvider() {
    _initializeCards();
  }

  void _initializeCards() {
    List<String> values = List.generate(
      (gridSize * gridSize) ~/ 2,
      (index) => (index + 1).toString(),
    );
    values.addAll(values);
    values.shuffle();

    cards = values.map((value) => CardModel(value: value)).toList();
  }

  void flipCard(CardModel card) {
    if (!card.isFaceUp &&
        (firstSelectedCard == null || firstSelectedCard != card)) {
      card.isFaceUp = true;
      notifyListeners();

      if (firstSelectedCard == null) {
        firstSelectedCard = card;
      } else {
        if (firstSelectedCard!.value == card.value) {
          score += 10;
          matchesFound++;

          if (matchesFound == (cards.length ~/ 2)) {
            stopTimer();
          }

          firstSelectedCard = null;
        } else {
          score -= 2;

          // Use Future.delayed to flip cards back after a short delay
          Future.delayed(const Duration(seconds: 1), () {
            // Ensure no concurrent modification occurs
            if (!cards.contains(card) || !cards.contains(firstSelectedCard))
              return;

            // Flip cards back
            card.isFaceUp = false;
            firstSelectedCard!.isFaceUp = false;
            firstSelectedCard = null;
            notifyListeners();
          });
        }
      }
    }

    if (!timerRunning) {
      startTimer();
    }
  }

  void startTimer() {
    timerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      timeElapsed++;
      notifyListeners();
    });
  }

  void stopTimer() {
    timerRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  void resetGame() {
    score = 0;
    matchesFound = 0;
    timeElapsed = 0;
    firstSelectedCard = null;

    // Delay reinitializing cards slightly to avoid conflicts
    Future.delayed(Duration.zero, () {
      _initializeCards();
      stopTimer();
      notifyListeners(); // Ensuring the UI updates after the reset
    });
  }
}

class CardModel {
  final String value;
  bool isFaceUp;

  CardModel({required this.value, this.isFaceUp = false});
}

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Card Matching Game')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Score: ${provider.score}'),
                Text('Time: ${provider.timeElapsed}s'),
                ElevatedButton(
                  onPressed: provider.resetGame,
                  child: const Text('Restart'),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: provider.gridSize,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: provider.cards.length,
              itemBuilder: (context, index) {
                final card = provider.cards[index];

                return GestureDetector(
                  onTap: () => provider.flipCard(card),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color:
                          card.isFaceUp ? Colors.blueAccent : Colors.grey[400],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Center(
                      child: Text(
                        card.isFaceUp ? card.value : '',
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
