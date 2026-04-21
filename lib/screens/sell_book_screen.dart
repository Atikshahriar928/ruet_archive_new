import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../managers/database_manager.dart';
import '../widgets/custom_components.dart';

// RUET Theme Colors
const Color backgroundBlack = Color(0xFF000000);
const Color zinc900 = Color(0xFF09090B);
const Color zinc800 = Color(0xFF18181B);
const Color zinc500 = Color(0xFF71717A);
const Color emerald500 = Color(0xFF10B981);
const Color blue500 = Color(0xFF3B82F6);
const Color blue400 = Color(0xFF60A5FA);

class SellBookScreen extends StatefulWidget {
  final String? editItemId;

  const SellBookScreen({
    super.key,
    this.editItemId,
  });

  @override
  State<SellBookScreen> createState() => _SellBookScreenState();
}

class _SellBookScreenState extends State<SellBookScreen> {
  final _bookNameController = TextEditingController();
  final _authorNameController = TextEditingController();
  final _deptNameController = TextEditingController();
  final _courseCodeController = TextEditingController();
  final _courseNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedYear = "Select Year";
  String _selectedSemester = "Select";
  String _selectedCondition = "Select Condition";

  bool _isLoading = false;
  bool _isSuccess = false;
  List<String> _imagePreviewList = []; // Base64 strings
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.editItemId != null && widget.editItemId != "new") {
      _loadExistingData();
    }
  }

  void _loadExistingData() async {
    setState(() => _isLoading = true);
    // Simulation
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 50,
        maxWidth: 800,
      );
      
      if (images.isNotEmpty) {
        for (var image in images) {
          final bytes = await image.readAsBytes();
          final String base64 = base64Encode(bytes);
          setState(() {
            if (_imagePreviewList.length < 5) {
              _imagePreviewList.add(base64);
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }

  void _handlePublish() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_bookNameController.text.isEmpty || _priceController.text.isEmpty || _deptNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all required fields")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final book = BookListing(
        id: widget.editItemId ?? "",
        bookName: _bookNameController.text.trim(),
        authorName: _authorNameController.text.trim(),
        deptName: _deptNameController.text.trim(),
        courseCode: _courseCodeController.text.trim(),
        courseName: _courseNameController.text.trim(),
        year: _selectedYear,
        semester: _selectedSemester,
        condition: _selectedCondition,
        price: double.tryParse(_priceController.text) ?? 0.0,
        description: _descriptionController.text.trim(),
        imageBase64List: _imagePreviewList,
        ownerUid: user.uid,
        reporterName: user.displayName ?? "User",
      );

      await DatabaseManager.saveBookListing(book);
      
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Error publishing listing: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlack,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: zinc900,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        widget.editItemId != null && widget.editItemId != "new" ? "Edit Listing" : "Sell Your Book",
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Photo Upload Section
                  const Text(
                    "Book Photos",
                    style: TextStyle(color: blue400, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: zinc900,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: zinc800),
                      ),
                      child: _imagePreviewList.isEmpty 
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: emerald500.withAlpha(13),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.add_photo_alternate_rounded, color: emerald500, size: 32),
                              ),
                              const SizedBox(height: 16),
                              const Text("Add Photos", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              const Text("Up to 5 images", style: TextStyle(color: zinc500, fontSize: 12)),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: AppImage(source: _imagePreviewList.first),
                          ),
                    ),
                  ),

                  if (_imagePreviewList.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imagePreviewList.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: AppImage(
                                  source: _imagePreviewList[index],
                                  width: 80,
                                  height: 80,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => setState(() => _imagePreviewList.removeAt(index)),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Form Fields
                  _ruetTextField(label: "Book Name", controller: _bookNameController, placeholder: "Enter book title"),
                  _ruetTextField(label: "Author Name", controller: _authorNameController, placeholder: "Enter author name"),

                  Row(
                    children: [
                      Expanded(child: _ruetTextField(label: "Dept Name", controller: _deptNameController, placeholder: "e.g. CSE")),
                      const SizedBox(width: 16),
                      Expanded(child: _ruetTextField(label: "Course Code", controller: _courseCodeController, placeholder: "e.g. CSE-2101")),
                    ],
                  ),

                  _ruetTextField(label: "Course Name", controller: _courseNameController, placeholder: "e.g. Data Structures"),

                  Row(
                    children: [
                      Expanded(
                        child: _ruetDropdown(
                          label: "Year",
                          options: ["1st Year", "2nd Year", "3rd Year", "4th Year"],
                          selectedOption: _selectedYear,
                          onChanged: (val) => setState(() => _selectedYear = val!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ruetDropdown(
                          label: "Semester",
                          options: ["Odd", "Even"],
                          selectedOption: _selectedSemester,
                          onChanged: (val) => setState(() => _selectedSemester = val!),
                        ),
                      ),
                    ],
                  ),

                  _ruetDropdown(
                    label: "Book Condition",
                    options: ["New", "Like New", "Good", "Fair", "Poor"],
                    selectedOption: _selectedCondition,
                    onChanged: (val) => setState(() => _selectedCondition = val!),
                  ),

                  _ruetTextField(
                    label: "Price (BDT)",
                    controller: _priceController,
                    placeholder: "0.00",
                    prefixText: "৳ ",
                    keyboardType: TextInputType.number,
                  ),

                  // Description
                  const Text(
                    "Description (Optional)",
                    style: TextStyle(color: blue400, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Add details about the book...",
                      hintStyle: const TextStyle(color: Color(0xFF3F3F46)),
                      filled: true,
                      fillColor: zinc900,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 72,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handlePublish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: emerald500,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : Text(
                              widget.editItemId != null && widget.editItemId != "new" ? "UPDATE LISTING" : "PUBLISH LISTING",
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Success Overlay
          if (_isSuccess)
            Container(
              color: Colors.black.withAlpha(230),
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(color: emerald500, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.black, size: 60),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.editItemId != null && widget.editItemId != "new" ? "Listing Updated!" : "Listing Published!",
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _ruetTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    String? prefixText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: blue400, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(color: Color(0xFF3F3F46)),
            prefixText: prefixText,
            prefixStyle: const TextStyle(color: emerald500, fontWeight: FontWeight.bold),
            filled: true,
            fillColor: zinc900,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: zinc800)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: zinc800)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _ruetDropdown({
    required String label,
    required List<String> options,
    required String selectedOption,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: blue400, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: options.contains(selectedOption) ? selectedOption : null,
          dropdownColor: zinc900,
          style: const TextStyle(color: Colors.white),
          icon: const Icon(Icons.keyboard_arrow_right, color: Color(0xFF3F3F46)),
          decoration: InputDecoration(
            hintText: selectedOption,
            hintStyle: const TextStyle(color: Color(0xFF3F3F46)),
            filled: true,
            fillColor: zinc900,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: zinc800)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: zinc800)),
          ),
          items: options.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val),
            );
          }).toList(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
