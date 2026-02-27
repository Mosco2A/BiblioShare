import '../../shared/models/book_model.dart';
import '../../shared/models/friendship_model.dart';
import '../../shared/models/loan_model.dart';
import '../../shared/models/user_model.dart';

/// Service fournissant des données de démonstration pour l'app.
/// Utilisé comme fallback quand Supabase n'est pas disponible.
class SeedDataService {
  SeedDataService._();

  // IDs des utilisateurs de démo
  static const _userMarie = 'demo-marie';
  static const _userThomas = 'demo-thomas';
  static const _userSophie = 'demo-sophie';
  static const _userLucas = 'demo-lucas';
  static const _userCamille = 'demo-camille';

  /// Utilisateurs de démo (amis potentiels)
  static List<UserModel> getDemoUsers() {
    final now = DateTime.now();
    return [
      UserModel(
        id: _userMarie,
        displayName: 'Marie Dupont',
        username: 'marie.lit',
        bio: 'Passionnée de littérature française et de romans policiers',
        location: 'Paris',
        preferredGenres: ['Roman', 'Policier', 'Classique'],
        createdAt: now.subtract(const Duration(days: 180)),
        updatedAt: now.subtract(const Duration(days: 2)),
        onboardingCompleted: true,
      ),
      UserModel(
        id: _userThomas,
        displayName: 'Thomas Martin',
        username: 'tom_books',
        bio: 'SF, fantasy et manga. Toujours un livre en cours !',
        location: 'Lyon',
        preferredGenres: ['Science-Fiction', 'Fantasy', 'Manga'],
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now.subtract(const Duration(days: 5)),
        onboardingCompleted: true,
      ),
      UserModel(
        id: _userSophie,
        displayName: 'Sophie Bernard',
        username: 'sophie_b',
        bio: 'Dévoreuse de thrillers et de développement personnel',
        location: 'Bordeaux',
        preferredGenres: ['Thriller', 'Développement personnel', 'Essai'],
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(days: 1)),
        onboardingCompleted: true,
      ),
      UserModel(
        id: _userLucas,
        displayName: 'Lucas Petit',
        username: 'lucas.reads',
        bio: 'BD, comics et romans graphiques',
        location: 'Toulouse',
        preferredGenres: ['BD', 'Comics', 'Roman graphique'],
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 10)),
        onboardingCompleted: true,
      ),
      UserModel(
        id: _userCamille,
        displayName: 'Camille Moreau',
        username: 'cam_lecture',
        bio: 'Littérature contemporaine et poésie',
        location: 'Nantes',
        preferredGenres: ['Contemporain', 'Poésie', 'Autofiction'],
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now.subtract(const Duration(days: 3)),
        onboardingCompleted: true,
      ),
    ];
  }

  /// Livres pour la bibliothèque de l'utilisateur courant
  static List<BookModel> getDemoBooks(String userId) {
    final now = DateTime.now();
    return [
      BookModel(
        id: 'seed-1',
        userId: userId,
        isbn13: '9782070368228',
        title: "L'Étranger",
        authors: [const BookAuthor(name: 'Albert Camus')],
        publisher: 'Gallimard',
        pageCount: 185,
        description:
            "Aujourd'hui, maman est morte. Ou peut-être hier, je ne sais pas.",
        genres: ['Classique', 'Roman'],
        coverUrl:
            'https://covers.openlibrary.org/b/isbn/9782070368228-M.jpg',
        condition: 'good',
        goodreadsRating: 4.0,
        dateAdded: now.subtract(const Duration(days: 30)),
        language: 'fr',
      ),
      BookModel(
        id: 'seed-2',
        userId: userId,
        isbn13: '9782070360024',
        title: 'Le Petit Prince',
        authors: [const BookAuthor(name: 'Antoine de Saint-Exupéry')],
        publisher: 'Gallimard',
        pageCount: 96,
        description: "Un pilote se pose dans le Sahara et rencontre un petit prince venu d'une autre planète.",
        genres: ['Classique', 'Conte', 'Jeunesse'],
        coverUrl:
            'https://covers.openlibrary.org/b/isbn/9782070360024-M.jpg',
        condition: 'good',
        goodreadsRating: 4.3,
        dateAdded: now.subtract(const Duration(days: 28)),
        language: 'fr',
      ),
      BookModel(
        id: 'seed-3',
        userId: userId,
        isbn13: '9782070413119',
        title: 'Harry Potter à l\'école des sorciers',
        authors: [const BookAuthor(name: 'J.K. Rowling')],
        publisher: 'Gallimard Jeunesse',
        pageCount: 311,
        description: "Le jour de ses onze ans, Harry Potter reçoit la visite d'un géant et découvre qu'il est un sorcier.",
        genres: ['Fantasy', 'Jeunesse', 'Aventure'],
        coverUrl:
            'https://covers.openlibrary.org/b/isbn/9782070413119-M.jpg',
        condition: 'good',
        goodreadsRating: 4.5,
        dateAdded: now.subtract(const Duration(days: 25)),
        language: 'fr',
      ),
      BookModel(
        id: 'seed-4',
        userId: userId,
        isbn13: '9782253004226',
        title: 'Les Misérables',
        authors: [const BookAuthor(name: 'Victor Hugo')],
        publisher: 'Le Livre de Poche',
        pageCount: 1900,
        description: "Jean Valjean, ancien forçat, tente de se racheter dans la France du XIXe siècle.",
        genres: ['Classique', 'Roman historique'],
        coverUrl:
            'https://covers.openlibrary.org/b/isbn/9782253004226-M.jpg',
        condition: 'fair',
        goodreadsRating: 4.2,
        dateAdded: now.subtract(const Duration(days: 22)),
        language: 'fr',
      ),
      BookModel(
        id: 'seed-5',
        userId: userId,
        isbn13: '9782070364824',
        title: 'La Peste',
        authors: [const BookAuthor(name: 'Albert Camus')],
        publisher: 'Gallimard',
        pageCount: 308,
        description: "Une épidémie de peste s'abat sur Oran. Le docteur Rieux lutte contre le fléau.",
        genres: ['Classique', 'Roman'],
        coverUrl:
            'https://covers.openlibrary.org/b/isbn/9782070364824-M.jpg',
        condition: 'good',
        goodreadsRating: 3.99,
        dateAdded: now.subtract(const Duration(days: 20)),
        language: 'fr',
      ),
      BookModel(
        id: 'seed-6',
        userId: userId,
        isbn13: '9782253151531',
        title: 'Da Vinci Code',
        authors: [const BookAuthor(name: 'Dan Brown')],
        publisher: 'Le Livre de Poche',
        pageCount: 756,
        description: "Robert Langdon enquête sur le meurtre du conservateur du Louvre.",
        genres: ['Thriller', 'Policier'],
        coverUrl:
            'https://covers.openlibrary.org/b/isbn/9782253151531-M.jpg',
        condition: 'good',
        goodreadsRating: 3.9,
        dateAdded: now.subtract(const Duration(days: 18)),
        language: 'fr',
      ),
      BookModel(
        id: 'seed-7',
        userId: userId,
        isbn13: '9782070612765',
        title: 'Germinal',
        authors: [const BookAuthor(name: 'Émile Zola')],
        publisher: 'Gallimard',
        pageCount: 592,
        description: "Étienne Lantier arrive dans le Nord pour travailler à la mine.",
        genres: ['Classique', 'Roman social'],
        coverUrl:
            'https://covers.openlibrary.org/b/isbn/9782070612765-M.jpg',
        condition: 'good',
        goodreadsRating: 3.9,
        dateAdded: now.subtract(const Duration(days: 15)),
        language: 'fr',
      ),
      BookModel(
        id: 'seed-8',
        userId: userId,
        isbn13: '9782253001874',
        title: 'Le Comte de Monte-Cristo',
        authors: [const BookAuthor(name: 'Alexandre Dumas')],
        publisher: 'Le Livre de Poche',
        pageCount: 1504,
        description: "Edmond Dantès, injustement emprisonné, s'évade et prépare sa vengeance.",
        genres: ['Classique', 'Aventure', 'Roman historique'],
        coverUrl:
            'https://covers.openlibrary.org/b/isbn/9782253001874-M.jpg',
        condition: 'good',
        goodreadsRating: 4.3,
        dateAdded: now.subtract(const Duration(days: 12)),
        language: 'fr',
      ),
      BookModel(
        id: 'seed-9',
        userId: userId,
        isbn13: '9782290382561',
        title: 'Dune',
        authors: [const BookAuthor(name: 'Frank Herbert')],
        publisher: 'J\'ai Lu',
        pageCount: 928,
        description: "Paul Atréides doit assurer l'avenir de la planète la plus inhospitalière de l'univers.",
        genres: ['Science-Fiction', 'Aventure'],
        coverUrl:
            'https://covers.openlibrary.org/b/isbn/9782290382561-M.jpg',
        condition: 'good',
        goodreadsRating: 4.3,
        dateAdded: now.subtract(const Duration(days: 10)),
        language: 'fr',
      ),
      BookModel(
        id: 'seed-10',
        userId: userId,
        isbn13: '9782253009849',
        title: '1984',
        authors: [const BookAuthor(name: 'George Orwell')],
        publisher: 'Le Livre de Poche',
        pageCount: 438,
        description: "Dans un monde totalitaire, Winston Smith tente de résister à Big Brother.",
        genres: ['Science-Fiction', 'Dystopie', 'Classique'],
        coverUrl:
            'https://covers.openlibrary.org/b/isbn/9782253009849-M.jpg',
        condition: 'good',
        goodreadsRating: 4.2,
        dateAdded: now.subtract(const Duration(days: 8)),
        language: 'fr',
      ),
      BookModel(
        id: 'seed-11',
        userId: userId,
        isbn13: '9782070409204',
        title: "L'Alchimiste",
        authors: [const BookAuthor(name: 'Paulo Coelho')],
        publisher: 'J\'ai Lu',
        pageCount: 251,
        description: "Santiago, un berger andalou, part à la recherche d'un trésor enfoui au pied des Pyramides.",
        genres: ['Roman', 'Développement personnel'],
        coverUrl:
            'https://covers.openlibrary.org/b/isbn/9782070409204-M.jpg',
        condition: 'good',
        goodreadsRating: 3.9,
        dateAdded: now.subtract(const Duration(days: 5)),
        language: 'fr',
      ),
      BookModel(
        id: 'seed-12',
        userId: userId,
        isbn13: '9782253010692',
        title: 'Madame Bovary',
        authors: [const BookAuthor(name: 'Gustave Flaubert')],
        publisher: 'Le Livre de Poche',
        pageCount: 480,
        description: "Emma Bovary rêve d'une vie romanesque et passionnée.",
        genres: ['Classique', 'Roman'],
        coverUrl:
            'https://covers.openlibrary.org/b/isbn/9782253010692-M.jpg',
        condition: 'fair',
        goodreadsRating: 3.7,
        dateAdded: now.subtract(const Duration(days: 3)),
        language: 'fr',
      ),
    ];
  }

  /// Livres des amis (pour les fonctionnalités sociales)
  static List<BookModel> getDemoFriendBooks() {
    final now = DateTime.now();
    return [
      // Livres de Marie
      BookModel(
        id: 'friend-1',
        userId: _userMarie,
        isbn13: '9782070368228',
        title: "L'Étranger",
        authors: [const BookAuthor(name: 'Albert Camus')],
        publisher: 'Gallimard',
        genres: ['Classique'],
        coverUrl: 'https://covers.openlibrary.org/b/isbn/9782070368228-M.jpg',
        dateAdded: now.subtract(const Duration(days: 60)),
      ),
      BookModel(
        id: 'friend-2',
        userId: _userMarie,
        isbn13: '9782253174127',
        title: 'La Vérité sur l\'affaire Harry Quebert',
        authors: [const BookAuthor(name: 'Joël Dicker')],
        publisher: 'Le Livre de Poche',
        genres: ['Policier', 'Thriller'],
        coverUrl: 'https://covers.openlibrary.org/b/isbn/9782253174127-M.jpg',
        dateAdded: now.subtract(const Duration(days: 45)),
      ),
      // Livres de Thomas
      BookModel(
        id: 'friend-3',
        userId: _userThomas,
        isbn13: '9782290382561',
        title: 'Dune',
        authors: [const BookAuthor(name: 'Frank Herbert')],
        publisher: "J'ai Lu",
        genres: ['Science-Fiction'],
        coverUrl: 'https://covers.openlibrary.org/b/isbn/9782290382561-M.jpg',
        dateAdded: now.subtract(const Duration(days: 40)),
      ),
      BookModel(
        id: 'friend-4',
        userId: _userThomas,
        isbn13: '9782070415731',
        title: 'Le Seigneur des Anneaux',
        authors: [const BookAuthor(name: 'J.R.R. Tolkien')],
        publisher: 'Gallimard',
        genres: ['Fantasy', 'Aventure'],
        coverUrl: 'https://covers.openlibrary.org/b/isbn/9782070415731-M.jpg',
        dateAdded: now.subtract(const Duration(days: 35)),
      ),
      // Livres de Sophie
      BookModel(
        id: 'friend-5',
        userId: _userSophie,
        isbn13: '9782253151531',
        title: 'Da Vinci Code',
        authors: [const BookAuthor(name: 'Dan Brown')],
        publisher: 'Le Livre de Poche',
        genres: ['Thriller'],
        coverUrl: 'https://covers.openlibrary.org/b/isbn/9782253151531-M.jpg',
        dateAdded: now.subtract(const Duration(days: 30)),
      ),
      BookModel(
        id: 'friend-6',
        userId: _userSophie,
        isbn13: '9782266283038',
        title: 'Sapiens',
        authors: [const BookAuthor(name: 'Yuval Noah Harari')],
        publisher: 'Pocket',
        genres: ['Essai', 'Histoire'],
        coverUrl: 'https://covers.openlibrary.org/b/isbn/9782266283038-M.jpg',
        dateAdded: now.subtract(const Duration(days: 20)),
      ),
      // Livres de Lucas
      BookModel(
        id: 'friend-7',
        userId: _userLucas,
        isbn13: '9782205077575',
        title: 'Astérix chez les Pictes',
        authors: [
          const BookAuthor(name: 'Jean-Yves Ferri'),
          const BookAuthor(name: 'Didier Conrad'),
        ],
        publisher: 'Albert René',
        genres: ['BD', 'Humour'],
        coverUrl: 'https://covers.openlibrary.org/b/isbn/9782205077575-M.jpg',
        dateAdded: now.subtract(const Duration(days: 15)),
      ),
      // Livres de Camille
      BookModel(
        id: 'friend-8',
        userId: _userCamille,
        isbn13: '9782072762093',
        title: 'Chanson douce',
        authors: [const BookAuthor(name: 'Leïla Slimani')],
        publisher: 'Gallimard',
        genres: ['Contemporain', 'Roman'],
        coverUrl: 'https://covers.openlibrary.org/b/isbn/9782072762093-M.jpg',
        dateAdded: now.subtract(const Duration(days: 10)),
      ),
    ];
  }

  /// Amitiés de démo avec l'utilisateur courant
  static List<FriendshipModel> getDemoFriendships(String userId) {
    final now = DateTime.now();
    return [
      FriendshipModel(
        id: 'fs-1',
        requesterId: userId,
        receiverId: _userMarie,
        status: FriendshipStatus.accepted,
        groupTags: ['Classiques'],
        source: 'search',
        createdAt: now.subtract(const Duration(days: 90)),
        acceptedAt: now.subtract(const Duration(days: 89)),
      ),
      FriendshipModel(
        id: 'fs-2',
        requesterId: _userThomas,
        receiverId: userId,
        status: FriendshipStatus.accepted,
        groupTags: ['SF & Fantasy'],
        source: 'search',
        createdAt: now.subtract(const Duration(days: 60)),
        acceptedAt: now.subtract(const Duration(days: 59)),
      ),
      FriendshipModel(
        id: 'fs-3',
        requesterId: userId,
        receiverId: _userSophie,
        status: FriendshipStatus.accepted,
        groupTags: ['Thrillers'],
        source: 'search',
        createdAt: now.subtract(const Duration(days: 30)),
        acceptedAt: now.subtract(const Duration(days: 29)),
      ),
      FriendshipModel(
        id: 'fs-4',
        requesterId: _userLucas,
        receiverId: userId,
        status: FriendshipStatus.pending,
        source: 'search',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      FriendshipModel(
        id: 'fs-5',
        requesterId: _userCamille,
        receiverId: userId,
        status: FriendshipStatus.pending,
        source: 'search',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  /// Prêts de démo
  static List<LoanModel> getDemoLoansAsOwner(String userId) {
    final now = DateTime.now();
    return [
      LoanModel(
        id: 'loan-1',
        bookId: 'seed-6', // Da Vinci Code
        ownerId: userId,
        borrowerId: _userSophie,
        status: LoanStatus.active,
        requestedAt: now.subtract(const Duration(days: 14)),
        acceptedAt: now.subtract(const Duration(days: 13)),
        lentAt: now.subtract(const Duration(days: 12)),
        dueDate: now.add(const Duration(days: 16)),
        originalDueDate: now.add(const Duration(days: 16)),
        conditionBefore: 'good',
        notes: 'Prêté lors du café lecture',
      ),
    ];
  }

  /// Emprunts de démo
  static List<LoanModel> getDemoLoansAsBorrower(String userId) {
    final now = DateTime.now();
    return [
      LoanModel(
        id: 'loan-2',
        bookId: 'friend-3', // Dune de Thomas
        ownerId: _userThomas,
        borrowerId: userId,
        status: LoanStatus.active,
        requestedAt: now.subtract(const Duration(days: 7)),
        acceptedAt: now.subtract(const Duration(days: 6)),
        lentAt: now.subtract(const Duration(days: 5)),
        dueDate: now.add(const Duration(days: 23)),
        originalDueDate: now.add(const Duration(days: 23)),
        conditionBefore: 'good',
      ),
    ];
  }

  /// Retourne un UserModel de démo par ID
  static UserModel? getUserById(String id) {
    final users = getDemoUsers();
    try {
      return users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }
}
