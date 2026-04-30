import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Book model - easy to replace with database model
class Book {
  final String id;
  final String title;
  final String subject;
  final String classLevel;
  final String docType;
  final bool isPremium;
  final double? price; // Price in MWK for premium books
  final String? description;
  final String? coverUrl;
  final String? downloadUrl;

  Book({
    required this.id,
    required this.title,
    required this.subject,
    required this.classLevel,
    required this.docType,
    this.isPremium = false,
    this.price,
    this.description,
    this.coverUrl,
    this.downloadUrl,
  });

  // Factory constructor for creating Book from database map
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      subject: map['subject'] ?? '',
      classLevel: map['class'] ?? map['classLevel'] ?? '',
      docType: map['docType'] ?? map['documentType'] ?? '',
      isPremium: map['isPremium'] ?? map['is_premium'] ?? false,
      price: map['price']?.toDouble(),
      description: map['description'],
      coverUrl: map['coverUrl'] ?? map['cover_url'],
      downloadUrl: map['downloadUrl'] ?? map['download_url'],
    );
  }

  // Convert Book to map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'class': classLevel,
      'docType': docType,
      'isPremium': isPremium,
      'price': price,
      'description': description,
      'coverUrl': coverUrl,
      'downloadUrl': downloadUrl,
    };
  }
}

/// Enum for book type selection
enum BookType { free, premium }

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedClass = 'All';
  String _selectedSubject = 'All';
  BookType _selectedBookType = BookType.free;

  // ============================================================
  // DUMMY DATA - Replace this with database API call
  // Example replacement:
  // final List<Book> _allBooks = await BookRepository.getBooks();
  // ============================================================
  final List<Book> _allBooks = [
    // Free Books
    Book(id: '1', title: 'Mathematics Form 1', subject: 'Mathematics', classLevel: 'Form 1', docType: 'Textbook', isPremium: false),
    Book(id: '2', title: 'Physics Form 2', subject: 'Physics', classLevel: 'Form 2', docType: 'Textbook', isPremium: false),
    Book(id: '3', title: 'Chemistry Form 3', subject: 'Chemistry', classLevel: 'Form 3', docType: 'Textbook', isPremium: false),
    Book(id: '4', title: 'Biology Form 4', subject: 'Biology', classLevel: 'Form 4', docType: 'Textbook', isPremium: false),
    Book(id: '5', title: 'English Grammar', subject: 'English', classLevel: 'Form 1', docType: 'Guide', isPremium: false),
    Book(id: '6', title: 'History Notes', subject: 'History', classLevel: 'Form 2', docType: 'Notes', isPremium: false),
    Book(id: '7', title: 'Geography Form 3', subject: 'Geography', classLevel: 'Form 3', docType: 'Textbook', isPremium: false),
    Book(id: '8', title: 'Mathematics Form 2', subject: 'Mathematics', classLevel: 'Form 2', docType: 'Guide', isPremium: false),
    Book(id: '9', title: 'Physics Form 1', subject: 'Physics', classLevel: 'Form 1', docType: 'Notes', isPremium: false),
    Book(id: '10', title: 'Chemistry Form 4', subject: 'Chemistry', classLevel: 'Form 4', docType: 'Textbook', isPremium: false),
    // Premium Books
    Book(id: '11', title: 'Advanced Mathematics', subject: 'Mathematics', classLevel: 'Form 4', docType: 'Textbook', isPremium: true, price: 500.00),
    Book(id: '12', title: 'Premium Physics Pack', subject: 'Physics', classLevel: 'Form 3', docType: 'Guide', isPremium: true, price: 750.00),
    Book(id: '13', title: 'Chemistry Masterclass', subject: 'Chemistry', classLevel: 'Form 4', docType: 'Textbook', isPremium: true, price: 600.00),
    Book(id: '14', title: 'Biology Complete Notes', subject: 'Biology', classLevel: 'Form 3', docType: 'Notes', isPremium: true, price: 450.00),
    Book(id: '15', title: 'English Literature Premium', subject: 'English', classLevel: 'Form 4', docType: 'Guide', isPremium: true, price: 550.00),
  ];

  // Filter options - these can also come from database
  List<String> get _classes => ['All', 'Form 1', 'Form 2', 'Form 3', 'Form 4'];
  List<String> get _subjects => ['All', 'Mathematics', 'Physics', 'Chemistry', 'Biology', 'English', 'History', 'Geography'];

  // Filtered books based on search and filter criteria
  List<Book> get _filteredBooks {
    return _allBooks.where((book) {
      // Filter by book type (free or premium)
      final matchesBookType = _selectedBookType == BookType.free ? !book.isPremium : book.isPremium;
      final matchesSearch = _searchController.text.isEmpty ||
          book.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          book.subject.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesClass = _selectedClass == 'All' || book.classLevel == _selectedClass;
      final matchesSubject = _selectedSubject == 'All' || book.subject == _selectedSubject;
      return matchesBookType && matchesSearch && matchesClass && matchesSubject;
    }).toList();
  }

  // ============================================================
  // PAYMENT INTEGRATION
  // Replace this with actual payment API integration
  // Example: Flutterwave, PayPal, Stripe, etc.
  // ============================================================
  Future<void> _processPayment(Book book) async {
    // Show payment dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purchase Premium Book'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${book.title}'),
            const SizedBox(height: 8),
            Text('Price: MWK ${book.price?.toStringAsFixed(2) ?? "0.00"}'),
            const SizedBox(height: 16),
            const Text(
              'This will process payment through the integrated payment API.',
              style: TextStyle(fontSize: 12, color: AppColors.text2),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Integrate with a payment API when payments are available.
      // Example with Flutterwave:
      // await PaymentService.initializePayment(
      //   amount: book.price!,
      //   currency: 'MWK',
      //   bookId: book.id,
      // );
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment successful! You can now access ${book.title}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _readBook(Book book) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${book.title} for reading...')),
    );
  }

  void _downloadBook(Book book) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading ${book.title}...')),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Book Type Selection (Free/Premium)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.border),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Book Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildBookTypeButton(
                      title: 'Free Books',
                      icon: Icons.book_outlined,
                      isSelected: _selectedBookType == BookType.free,
                      onTap: () => setState(() => _selectedBookType = BookType.free),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBookTypeButton(
                      title: 'Premium',
                      icon: Icons.star,
                      isSelected: _selectedBookType == BookType.premium,
                      onTap: () => setState(() => _selectedBookType = BookType.premium),
                      isPremium: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for a book...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.surface2,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),

        // Compact Filter Bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.border),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedClass,
                  isDense: true,
                  decoration: InputDecoration(
                    labelText: 'Class',
                    prefixIcon: const Icon(Icons.school_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  items: _classes.map((classItem) {
                    return DropdownMenuItem(
                      value: classItem,
                      child: Text(classItem),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedClass = val!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSubject,
                  isDense: true,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    prefixIcon: const Icon(Icons.category_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  items: _subjects.map((subjectItem) {
                    return DropdownMenuItem(
                      value: subjectItem,
                      child: Text(
                        subjectItem,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedSubject = val!),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Books List
        Expanded(
          child: _filteredBooks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: AppColors.text2),
                      const SizedBox(height: 16),
                      Text(
                        'No books found',
                        style: TextStyle(fontSize: 18, color: AppColors.text2),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredBooks.length,
                  itemBuilder: (context, index) {
                    final book = _filteredBooks[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Stack(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: book.isPremium 
                                    ? Colors.amber.withValues(alpha: 0.2)
                                    : AppColors.primary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.menu_book, 
                                color: book.isPremium ? Colors.amber[700] : AppColors.primary,
                              ),
                            ),
                            if (book.isPremium)
                              const Positioned(
                                right: -5,
                                top: -5,
                                child: Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                              ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                book.title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (book.isPremium)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'MWK ${book.price?.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.background,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          '${book.subject} • ${book.classLevel} • ${book.docType}',
                          style: TextStyle(color: AppColors.text2, fontSize: 12),
                        ),
                        trailing: book.isPremium
                            ? IconButton(
                                tooltip: 'Purchase',
                                icon: const Icon(Icons.lock, color: Colors.amber),
                                onPressed: () => _processPayment(book),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () => _readBook(book),
                                    child: const Text(
                                      'Read',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Download',
                                    icon: const Icon(
                                      Icons.download,
                                      color: AppColors.primary,
                                    ),
                                    onPressed: () => _downloadBook(book),
                                  ),
                                ],
                              ),
                        onTap: () {
                          if (book.isPremium) {
                            _processPayment(book);
                          } else {
                            _readBook(book);
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Helper method to build book type selection buttons
  Widget _buildBookTypeButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    bool isPremium = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isPremium ? Colors.amber : AppColors.primary)
              : AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? (isPremium ? Colors.amber : AppColors.primary)
                : AppColors.border,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.background : AppColors.text2,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.background : AppColors.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
