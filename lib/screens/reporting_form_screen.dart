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
const Color orange500 = Color(0xFFF97316);
const Color blue500 = Color(0xFF3B82F6);

class ReportingFormScreen extends StatefulWidget {
  final ReportMode mode;
  final String? editItemId;

  const ReportingFormScreen({
    super.key,
    required this.mode,
    this.editItemId,
  });

  @override
  State<ReportingFormScreen> createState() => _ReportingFormScreenState();
}

class _ReportingFormScreenState extends State<ReportingFormScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _dateController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedCategory;
  bool _isLoading = false;
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
    try {
      final item = await DatabaseManager.getLostFoundItem(widget.editItemId!);
      if (item != null && mounted) {
        setState(() {
          _titleController.text = item.title;
          _locationController.text = item.location;
          _dateController.text = item.date;
          _descriptionController.text = item.description;
          _selectedCategory = item.category;
          _imagePreviewList = List.from(item.imageBase64List);
        });
      }
    } catch (e) {
      debugPrint("Error loading item: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: widget.mode == ReportMode.lost ? orange500 : blue500,
              onPrimary: Colors.black,
              surface: zinc900,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _handleSubmit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_titleController.text.isEmpty || _selectedCategory == null || _locationController.text.isEmpty || _dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all required fields")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final item = LostFoundItem(
        id: widget.editItemId ?? "",
        title: _titleController.text.trim(),
        category: _selectedCategory!,
        location: _locationController.text.trim(),
        date: _dateController.text.trim(),
        description: _descriptionController.text.trim(),
        imageBase64List: _imagePreviewList,
        type: widget.mode == ReportMode.lost ? "LOST" : "FOUND",
        ownerUid: user.uid,
        reporterName: user.displayName ?? "User",
      );

      await DatabaseManager.saveLostFoundItem(item);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report submitted successfully!")));
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error submitting report: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeColor = widget.mode == ReportMode.lost ? orange500 : blue500;

    return Scaffold(
      backgroundColor: backgroundBlack,
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: emerald500))
          : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: zinc900, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    widget.editItemId != null ? "Edit Report" : (widget.mode == ReportMode.lost ? "Report Lost" : "Report Found"),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Image Upload Section
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: zinc900,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: zinc800),
                  ),
                  child: _imagePreviewList.isEmpty 
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded, color: modeColor, size: 48),
                          const SizedBox(height: 12),
                          const Text("Add Photos", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const Text("Up to 5 images", style: TextStyle(color: zinc500, fontSize: 12)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(24),
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

              _buildLabel("Item Title"),
              _buildTextField(
                controller: _titleController,
                placeholder: "e.g. iPhone 13 Pro",
                icon: Icons.label_rounded,
              ),

              _buildLabel("Category"),
              _buildCategoryDropdown(modeColor),

              _buildLabel("Last Seen Location"),
              _buildTextField(
                controller: _locationController,
                placeholder: "e.g. Auditorium",
                icon: Icons.map_rounded,
              ),

              _buildLabel("Date"),
              _buildTextField(
                controller: _dateController,
                placeholder: "YYYY-MM-DD",
                icon: Icons.calendar_month_rounded,
                readOnly: true,
                onTap: _selectDate,
                trailing: Icon(Icons.calendar_today_rounded, color: modeColor, size: 20),
              ),

              _buildLabel("Description (Optional)"),
              _buildTextField(
                controller: _descriptionController,
                placeholder: "Provide details like color, brand, or unique marks...",
                maxLines: 5,
              ),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: modeColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          widget.editItemId != null ? "Update Report" : "Submit Report",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        label,
        style: const TextStyle(color: zinc500, fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    IconData? icon,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? trailing,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(color: zinc500, fontSize: 14),
          prefixIcon: icon != null ? Icon(icon, color: zinc500, size: 20) : null,
          suffixIcon: trailing,
          filled: true,
          fillColor: zinc900,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(Color modeColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        dropdownColor: zinc900,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Select category",
          hintStyle: const TextStyle(color: zinc500, fontSize: 14),
          prefixIcon: const Icon(Icons.category_rounded, color: zinc500, size: 20),
          filled: true,
          fillColor: zinc900,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        items: itemCategories.map((String category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(category),
          );
        }).toList(),
        onChanged: (val) => setState(() => _selectedCategory = val),
      ),
    );
  }
}
