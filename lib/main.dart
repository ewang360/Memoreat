import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primaryColor: const Color.fromARGB(255, 221, 101, 2)),
      home: const FoodJournal(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// storage for each food item
class ImageItem {
  final String path;  // File path or URL
  String name;
  String restaurant;
  DateTime date;
  String description;

  ImageItem({
    required this.path, 
    this.name = '', 
    this.restaurant = '',
    DateTime? date,
    this.description = ''
  }) : date = date ?? DateTime.now();
}

// list of entries
List<ImageItem> imageItems = [];

// image picker object
final ImagePicker _picker = ImagePicker();


class FoodJournal extends StatefulWidget {
  const FoodJournal({super.key});

  @override
  State<FoodJournal> createState() => _FoodJournalState();
}

class _FoodJournalState extends State<FoodJournal> {
  List<File> selectedImages = []; // List of selected images
  final picker = ImagePicker(); // Instance of Image picker 
  @override
  Widget build(BuildContext context) {
    // display image selected from gallery
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memoreat'),
        backgroundColor: const Color.fromARGB(255, 221, 101, 2),
        actions: const [],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(const Color.fromARGB(255, 224, 136, 4))),
              child: const Text('Add Entree'),
              onPressed: () {
                addEntry();
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18.0),
            ),
            Expanded(
              child: SizedBox(
                width: 500.0, // To show images in particular area only 
                child: imageItems.isEmpty // If no images selected
                    ? const Center(child: Text('No food here yet!'))
                    // If atleast 1 images is selected
                    : GridView.builder(
                        itemCount: imageItems.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, // 2 images per row
                                crossAxisSpacing: 10, 
                                mainAxisSpacing: 10),
                        itemBuilder: (BuildContext context, int index) {
                          final item = imageItems[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ImageDetailPage(
                                    imageItem: imageItems[index],
                                    onDelete: () {
                                      setState(() {
                                        imageItems.removeAt(index);
                                      });
                                    },
                                    onEdit: (updatedItem) {
                                      setState(() {
                                        imageItems[index] = updatedItem;
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                            child: kIsWeb 
                              ? Image.network(File(item.path).path, fit: BoxFit.cover)
                              : Image.file(File(item.path), fit: BoxFit.cover),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> addEntry() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery); // opens phone's image gallery
    if (pickedImage == null) return; // User cancelled

    // Navigate to the form page to fill info
    final newItem = await Navigator.push<ImageItem>(
        context,
        MaterialPageRoute(
          builder: (_) => ItemInfoFormPage(imagePath: pickedImage.path),
        ),
    );

    // If form submitted, add new item to your list and refresh UI
    if (newItem != null) {
      setState(() {
        imageItems.add(newItem);
      });
    }
  }

  Future<bool> confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ).then((value) => value ?? false);
  }

  void handleDelete(BuildContext context, int index) async {
    final shouldDelete = await confirmDelete(context);
    if (shouldDelete) {
      setState(() {
        imageItems.removeAt(index);
      });
    }
  }
}

class ImageDetailPage extends StatefulWidget {
  final ImageItem imageItem;
  final VoidCallback onDelete;
  final Function(ImageItem updatedItem) onEdit;

  ImageDetailPage({
    required this.imageItem,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  _ImageDetailPageState createState() => _ImageDetailPageState();
}

class _ImageDetailPageState extends State<ImageDetailPage> {
  late ImageItem currentItem;

  @override
  void initState() {
    super.initState();
    currentItem = widget.imageItem;
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMMM d, yyyy').format(currentItem.date);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentItem.name),
        actions: [
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              // Navigate to your form page with current details for editing
              final updatedItem = await Navigator.push<ImageItem>(
                context,
                MaterialPageRoute(
                  builder: (_) => ItemInfoFormPage(
                    imagePath: currentItem.path,
                    existingItem: currentItem,
                  ),
                ),
              );

              if (updatedItem != null) {
                setState(() {
                  currentItem = updatedItem;  // update local state to refresh UI
                });
                widget.onEdit(updatedItem);  // notify home page of changes
              }
            },
          ),

          // Delete button
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              widget.onDelete(); // Call delete handler passed from home
              Navigator.pop(context); // Close detail page after deletion
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Display image
            AspectRatio(
              aspectRatio: 1.5,
              child: kIsWeb
                  ? Image.network(currentItem.path, fit: BoxFit.cover)
                  : Image.file(File(currentItem.path), fit: BoxFit.cover),
            ),

            // Card for details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        currentItem.name.isNotEmpty
                            ? currentItem.name
                            : 'Untitled',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 221, 101, 2),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Restaurant and Date Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.restaurant,
                                  size: 18, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                currentItem.restaurant.isNotEmpty
                                    ? currentItem.restaurant
                                    : 'Unknown Restaurant',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 18, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Description
                      Text(
                        currentItem.description.isNotEmpty
                            ? currentItem.description
                            : 'No description available for this entry.',
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class ItemInfoFormPage extends StatefulWidget {
  final String imagePath;
  final ImageItem? existingItem;  // Optional: existing data to edit

  const ItemInfoFormPage({required this.imagePath, this.existingItem, Key? key}) : super(key: key);

  @override
  _ItemInfoFormPageState createState() => _ItemInfoFormPageState();
}

class _ItemInfoFormPageState extends State<ItemInfoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _restaurantController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    _nameController.text = widget.existingItem?.name ?? '';
    _restaurantController.text = widget.existingItem?.restaurant ?? '';
    _descriptionController.text = widget.existingItem?.description ?? '';
    _selectedDate = widget.existingItem?.date ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Write Food Details')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // IMAGE PREVIEW SECTION
              fadedImageBasic(widget.imagePath),

              // FORM FIELDS BELOW
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextFormField(
                controller: _restaurantController,
                decoration: InputDecoration(labelText: 'Restaurant'),
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              ListTile(
                title: Text(
                  'Date: ${DateFormat('MMMM d, yyyy').format(_selectedDate)}',
                  style: const TextStyle(fontSize: 16),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );

                  // Update date if the user selected one
                  if (pickedDate != null && pickedDate != _selectedDate) {
                    setState(() {
                      _selectedDate = pickedDate;
                    });
                  }
                },
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final newItem = ImageItem(
                      path: widget.imagePath,
                      name: _nameController.text,
                      restaurant: _restaurantController.text,
                      date: _selectedDate,
                      description: _descriptionController.text,
                    );
                    Navigator.pop(context, newItem); // Return the new item
                  }
                },
                child: Text('Save to Journal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget fadedImageBasic(String path) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(15),
    child: Stack(
      children: [
        kIsWeb
            ? Image.network(path, fit: BoxFit.cover)
            : Image.file(File(path), fit: BoxFit.cover),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.white.withOpacity(0.4)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}