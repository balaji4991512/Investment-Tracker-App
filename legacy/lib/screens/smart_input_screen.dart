import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';
import '../services/investment_parser.dart';
import '../services/ai_bill_parser.dart';
import '../utils/cred_theme.dart';
import 'confirm_investment_screen.dart';

class SmartInputScreen extends StatefulWidget {
  final String category;
  final String title;
  final String? initialMethod;
  
  const SmartInputScreen({
    super.key,
    required this.category,
    required this.title,
    this.initialMethod,
  });

  @override
  State<SmartInputScreen> createState() => _SmartInputScreenState();
}

class _SmartInputScreenState extends State<SmartInputScreen> {
  final _textController = TextEditingController();
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickAndProcessPDF() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      print('📄 Step 1: Opening file picker for PDF...');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true, // Important for web
      );
      
      if (result == null || result.files.isEmpty) {
        print('⚠️ User cancelled file picker');
        setState(() => _isProcessing = false);
        return;
      }

      print('📄 Step 2: File selected - ${result.files.single.name}');
      
      // Get bytes directly (works on all platforms including web)
      final bytes = result.files.single.bytes;
      
      if (bytes == null) {
        print('❌ Step 3: Failed to read file bytes');
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Could not read PDF file.';
        });
        return;
      }
      
      print('✅ Step 3: File bytes loaded - ${bytes.length} bytes');
      
      Map<String, dynamic> parsedData;
      
      // Check if Google Document AI is configured
      // Use GPT-4o Vision (Document AI pipeline removed)
      print('📄 Step 4: Using GPT-4o Vision pipeline...');
      parsedData = await _processWithVision(bytes, result.files.single.name);
      
      // Check if AI parsing returned an error
      if (parsedData.containsKey('error')) {
        print('❌ AI parsing returned error: ${parsedData['error']}');
        setState(() {
          _isProcessing = false;
          _errorMessage = 'AI could not parse the bill. Please try again or enter details manually.';
        });
        return;
      }
      
      // Check if essential fields were extracted
      final hasWeight = parsedData['weight'] != null || parsedData['netWeight'] != null;
      final hasAmount = parsedData['finalAmount'] != null;
      
      print('✅ AI parsing completed!');
      print('📊 Parsed data: $parsedData');
      print('📊 Has weight: $hasWeight, Has amount: $hasAmount');
      print('📊 OCR text saved: ${parsedData['ocrText']?.toString().length ?? 0} chars');
      
      parsedData['billFileName'] = result.files.single.name;

      setState(() => _isProcessing = false);
      print('📄 Navigating to confirmation screen...');

      // Navigate to confirmation screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmInvestmentScreen(
              category: widget.category,
              parsedData: parsedData,
              inputMethod: 'PDF',
            ),
          ),
        ).then((saved) {
          if (saved == true && mounted) {
            Navigator.pop(context, true);
          }
        });
      }
    } catch (e) {
      print('❌ PDF processing failed: $e');
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Error processing PDF: $e';
      });
    }
  }
  
  /// Process PDF with GPT-4o Vision (fallback method)
  Future<Map<String, dynamic>> _processWithVision(List<int> bytes, String fileName) async {
    List<Uint8List> pageImages = [];
    
    print('📄 Opening PDF for Vision processing...');
    final document = await PdfDocument.openData(Uint8List.fromList(bytes));
    print('✅ PDF opened - ${document.pagesCount} pages');
    
    for (int i = 1; i <= document.pagesCount; i++) {
      final page = await document.getPage(i);
      
      // Render at 2x resolution for good quality
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF',
      );
      
      if (pageImage != null) {
        pageImages.add(Uint8List.fromList(pageImage.bytes));
      }
      
      await page.close();
    }
    
    await document.close();
    
    if (pageImages.isEmpty) {
      throw Exception('Could not render PDF pages');
    }
    
    print('📄 Sending ${pageImages.length} image(s) to GPT-4o Vision...');
    return await AIBillParser.parseBillFromImages(pageImages);
  }

  Future<void> _pickAndProcessBill() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image == null) {
        setState(() => _isProcessing = false);
        return;
      }

      print('🖼️ Image selected: ${image.path}');
      
      // Read image bytes for Vision API
      final imageBytes = await File(image.path).readAsBytes();
      print('🖼️ Image bytes: ${imageBytes.length}');
      
      // Parse with GPT-4o Vision
      final parsedData = await AIBillParser.parseBillFromImages([Uint8List.fromList(imageBytes)]);

      if (parsedData.containsKey('error')) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Could not parse image. Please try again or use text input.';
        });
        return;
      }

      parsedData['billImagePath'] = image.path;

      setState(() => _isProcessing = false);

      // Navigate to confirmation screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmInvestmentScreen(
              category: widget.category,
              parsedData: parsedData,
              inputMethod: 'OCR',
            ),
          ),
        ).then((saved) {
          if (saved == true && mounted) {
            Navigator.pop(context, true);
          }
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Error processing image: $e';
      });
    }
  }

  Future<void> _processCameraImage() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);
      
      if (image == null) {
        setState(() => _isProcessing = false);
        return;
      }

      print('📷 Camera image captured: ${image.path}');
      
      // Read image bytes for Vision API
      final imageBytes = await File(image.path).readAsBytes();
      print('📷 Image bytes: ${imageBytes.length}');
      
      // Parse with GPT-4o Vision
      final parsedData = await AIBillParser.parseBillFromImages([Uint8List.fromList(imageBytes)]);

      if (parsedData.containsKey('error')) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Could not extract text from image. Please try again or use text/voice input.';
        });
        return;
      }

      parsedData['billImagePath'] = image.path;

      setState(() => _isProcessing = false);

      // Navigate to confirmation screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmInvestmentScreen(
              category: widget.category,
              parsedData: parsedData,
              inputMethod: 'Camera',
            ),
          ),
        ).then((saved) {
          if (saved == true && mounted) {
            Navigator.pop(context, true);
          }
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Error processing image: $e';
      });
    }
  }

  Future<void> _processTextInput() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Please enter some text');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Parse the text input
      final parsedData = InvestmentParser.parseInput(text);
      parsedData['originalInput'] = text;

      setState(() => _isProcessing = false);

      // Navigate to confirmation screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmInvestmentScreen(
              category: widget.category,
              parsedData: parsedData,
              inputMethod: 'Text',
            ),
          ),
        ).then((saved) {
          if (saved == true && mounted) {
            Navigator.pop(context, true);
          }
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Error processing text: $e';
      });
    }
  }

  Future<void> _startVoiceInput() async {
    // TODO: Implement speech-to-text
    // For now, show the text input as a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice input - Coming soon! Use text input for now.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Instructions
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Smart Input',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Choose your preferred input method below. '
                            'We need: Product Type, Weight, Final Price, Purity, and Vendor.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Option 1: Upload Bill
                  _buildOptionCard(
                    icon: Icons.upload_file,
                    iconColor: Colors.purple,
                    title: 'Upload Bill',
                    description: 'Photo, PDF, or scan from camera',
                    onTap: _isProcessing ? null : () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.camera_alt),
                                title: const Text('Take Photo'),
                                subtitle: const Text('Capture bill with camera'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _processCameraImage();
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('Choose from Gallery'),
                                subtitle: const Text('Select existing photo'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _pickAndProcessBill();
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.picture_as_pdf),
                                title: const Text('Choose PDF Bill'),
                                subtitle: const Text('Upload PDF document'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _pickAndProcessPDF();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Option 2: Voice Input
                  _buildOptionCard(
                    icon: Icons.mic,
                    iconColor: Colors.red,
                    title: 'Voice Input',
                    description: 'Speak your investment details',
                    onTap: _isProcessing ? null : _startVoiceInput,
                  ),

                  const SizedBox(height: 16),

                  // Option 3: Text Input
                  _buildOptionCard(
                    icon: Icons.edit,
                    iconColor: Colors.green,
                    title: 'Text Input',
                    description: 'Type your investment details',
                    isExpanded: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        TextField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            hintText: 'E.g., "Purchased 10gm Gold Chain 22kt from GRT today for 65000"',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                          enabled: !_isProcessing,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _processTextInput,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Process'),
                        ),
                      ],
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Examples
                  const Text(
                    'Examples:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildExampleCard('Purchased 10gm Gold Chain 22kt from GRT today for 65000'),
                  _buildExampleCard('Bought 5gm 18K gold ring yesterday for Rs 28500'),
                  _buildExampleCard('15 gram 24K gold coin from Tanishq for ₹95000 on 15/01/2026'),
                ],
              ),
            ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    VoidCallback? onTap,
    bool isExpanded = false,
    Widget? child,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isExpanded)
                    Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400),
                ],
              ),
              if (child != null) child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExampleCard(String example) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.orange.shade600, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                example,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
