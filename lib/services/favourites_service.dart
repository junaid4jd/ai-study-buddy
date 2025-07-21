import '../screens/flashcards/flashcard_screen.dart';

class FavouritesService {
  static final FavouritesService _instance = FavouritesService._internal();

  factory FavouritesService() => _instance;

  FavouritesService._internal();

  final List<Flashcard> _favouriteFlashcards = [];

  List<Flashcard> get favouriteFlashcards =>
      List.unmodifiable(_favouriteFlashcards);

  void addToFavourites(Flashcard flashcard) {
    if (!_favouriteFlashcards.any((card) => card.id == flashcard.id)) {
      _favouriteFlashcards.add(flashcard);
    }
  }

  void removeFromFavourites(String flashcardId) {
    _favouriteFlashcards.removeWhere((card) => card.id == flashcardId);
  }

  bool isFavourite(String flashcardId) {
    return _favouriteFlashcards.any((card) => card.id == flashcardId);
  }

  void syncFavourites(List<Flashcard> allFlashcards) {
    // Keep only favourites that still exist and are marked as favourite
    _favouriteFlashcards.clear();
    for (var card in allFlashcards) {
      if (card.isFavourite) {
        _favouriteFlashcards.add(card);
      }
    }
  }

  void clearAllFavourites() {
    _favouriteFlashcards.clear();
  }

  int get favouriteCount => _favouriteFlashcards.length;
}