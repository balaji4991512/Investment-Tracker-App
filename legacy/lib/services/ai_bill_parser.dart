import 'package:tesseract_ocr/tesseract_ocr.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show Directory, File;
import 'package:image/image.dart' as img_pkg;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// AI-powered bill parsing using OpenAI GPT-5 mini with raw OCR output
class AIBillParser {

    /// Use Tesseract OCR Flutter plugin to extract text from images, then send to OpenAI for field extraction
    static Future<Map<String, dynamic>> parseBillWithTesseractOCR(List<Uint8List> imageBytesList) async {
      try {
        final buffer = StringBuffer();
        for (int i = 0; i < imageBytesList.length; i++) {
          // Save imageBytes to a temporary file
          final tempDir = await Directory.systemTemp.createTemp();
          final file = File('${tempDir.path}/ocr_page_$i.png');
          await file.writeAsBytes(imageBytesList[i]);
          // Use tesseract_ocr plugin to extract text
          final text = await TesseractOcr.extractText(file.path);
          buffer.writeln(text.trim());
          buffer.writeln('\n----PAGE----\n');
          await file.delete();
          await tempDir.delete();
        }
        final ocrText = buffer.toString().trim();
        if (ocrText.isEmpty) {
          return {'error': 'Tesseract OCR did not extract any text.'};
        }
        final aiResult = await parseBillWithAI(ocrText);
        return aiResult;
      } catch (e, st) {
        print('❌ Tesseract OCR + AI pipeline failed: $e');
        print(st);
        return {'error': 'Tesseract OCR + AI pipeline failed: $e'};
      }
    }
  static String? _apiKey;
  
  static String _getApiKey() {
    if (_apiKey != null) return _apiKey!;
    
    final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (apiKey.isEmpty || apiKey == 'your_openai_api_key_here') {
      throw Exception('OpenAI API key not found. Please add OPENAI_API_KEY to assets/.env file');
    }
    
    _apiKey = apiKey;
    return _apiKey!;
  }

  /// The extraction prompt for jewellery bills - returns raw OCR + extracted fields
  static const String _extractionPrompt = '''
You are an expert at extracting structured data from Indian jewelry/gold bill receipts and invoices.
Analyze this bill image carefully, including any TABLES.

Return ONLY valid JSON with TWO sections:

{
  "rawText": "Complete OCR text from the bill. Preserve table structure using | as column separator. Include ALL text you can read.",
  
  "extracted": {
    "vendor": "Store/Company name (e.g., Tanishq, GRT, CaratLane, Kalyan, Joyalukkas)",
    "productDescription": "Full product description from the bill exactly as written",
    "weight": "Gross Weight in grams - TOTAL weight including stones (look for Gr.Wt, Gross Wt)",
    "netWeight": "Net Weight in grams - PURE GOLD/METAL weight only (look for Net Wt, Gold Wt, Metal Wt)",
    "purity": "Purity (22K, 18K, 14K, 24K, 916, 750, etc)",
    "metalType": "Metal type (Gold/Platinum/Silver)",
    "finalAmount": "Final amount PAID by customer in rupees (after GST, discounts - the largest total)",
    
    "stoneWeight": "Stone weight in GRAMS if mentioned",
    "stoneCost": "Stone cost/value in rupees if mentioned",
    "diamondCarats": "Diamond weight in CARATS (look for Dia, Cts, Ct)",
    "diamondCost": "Diamond cost/value in rupees",
    "diamondClarity": "Diamond clarity grade (FG-SI, IJ-SI, EF-VVS, etc)",
    "diamondColor": "Diamond color grade (D, E, F, G, H, etc)",
    "diamondCut": "Diamond cut quality (Ideal, Excellent, Very Good, Good)",
    "certificateNumber": "Certificate number (GIA/IGI/HRD) if present",
    "certificateAgency": "Certificate issuing agency (GIA, IGI, HRD, etc)",
    
    "goldRate": "Gold rate per gram used in the bill",
    "makingCharges": "Making/Labour charges in rupees",
    "gst": "Total GST amount in rupees",
    "discount": "Any discount applied in rupees",
    "billNumber": "Invoice/Bill number",
    "date": "Date in YYYY-MM-DD format",
    "gstin": "Store's GSTIN number",
    "lineItems": [
      {
        "description": "Item description",
        "grossWeight": "Gross weight",
        "netWeight": "Net weight", 
        "rate": "Rate per gram",
        "amount": "Line item amount"
      }
    ]
  }
}

CRITICAL EXTRACTION RULES:
1. rawText: Include EVERYTHING readable, preserve table layout with | separators
2. netWeight is MOST IMPORTANT - this is pure gold weight used for valuation
3. finalAmount = Amount PAID by customer (largest total after tax/discount)
4. Stones: Extract EITHER stoneWeight (grams) OR diamondCarats (carats) - NOT both unless bill has both
5. stoneCost/diamondCost = Value of stones/diamonds shown on bill
6. productDescription = Copy EXACT item description from bill (not generic names)
7. Purity: Keep as shown (916, 750) OR convert (916→22K, 750→18K, 999→24K)
8. All amounts = NUMBERS only (no commas, no ₹ symbol)
9. If a field is not found, use null
''';
  
  /// Parse bill using GPT-5 mini Vision (returns raw OCR + extracted fields)
  static Future<Map<String, dynamic>> parseBillFromImages(List<Uint8List> imageBytesList) async {
    print('🤖 Tesseract OCR Parser: Extracting text from images...');
    return await parseBillWithTesseractOCR(imageBytesList);
  }
  
  /// Call the chat completions endpoint with compressed images (single attempt).
  /// Returns parsed result map on success, or null if the vision response was empty.
  static Future<Map<String, dynamic>?> _callVisionWithCompressedImages(
      List<Uint8List> images, String apiKey) async {
    // Downscale/compress images to limit request size
    final compressedImages = <Uint8List>[];
    for (final bytes in images) {
      try {
        final img = img_pkg.decodeImage(bytes);
        if (img == null) {
          compressedImages.add(bytes);
          continue;
        }
        // Resize to max width 1000 while preserving aspect ratio
        const int maxWidth = 1000;
        img_pkg.Image resized = img;
        if (img.width > maxWidth) {
          resized = img_pkg.copyResize(img, width: maxWidth);
        }
        // Encode to JPEG with medium quality
        final jpg = img_pkg.encodeJpg(resized, quality: 60);
        compressedImages.add(Uint8List.fromList(jpg));
      } catch (e) {
        // On any failure, use original bytes
        compressedImages.add(bytes);
      }
    }

    // Build the content with compressed base64 images
    final content = <Map<String, dynamic>>[
      {'type': 'text', 'text': _extractionPrompt},
    ];
    for (int i = 0; i < compressedImages.length; i++) {
      final b64 = base64Encode(compressedImages[i]);
      content.add({
        'type': 'image_url',
        'image_url': {'url': 'data:image/jpeg;base64,$b64'},
      });
    }

    final userMessageContent = jsonEncode(content);

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-5-mini',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a JSON extraction expert. Return ONLY valid JSON following the schema exactly. Do not include any explanatory text.'
          },
          {
            'role': 'user',
            'content': userMessageContent,
          },
        ],
        'temperature': 1.0,
        'max_completion_tokens': 1200,
      }),
    ).timeout(const Duration(seconds: 120));

    if (response.statusCode != 200) {
      print('❌ Vision API Error: ${response.statusCode} - ${response.body}');
      return null;
    }

    final jsonResponse = jsonDecode(response.body);
    final responseText = (jsonResponse['choices']?[0]?['message']?['content'])?.toString() ?? '';
    print('🤖 Vision-first response length: ${responseText.length}');
    if (responseText.trim().isEmpty) {
      return null;
    }

    try {
      return _parseResponse(responseText);
    } catch (e) {
      print('❌ Failed to parse vision-first response: $e');
      return null;
    }
  }

  /// Run OCR on images using Google Cloud Vision API when API key is provided.
  /// Returns concatenated extracted text for all images.
  static Future<String> _runOcrOnImages(List<Uint8List> images) async {
    final visionKey = dotenv.env['GOOGLE_VISION_API_KEY'] ?? '';
    if (visionKey.isEmpty) {
      throw Exception('GOOGLE_VISION_API_KEY not set in .env; cannot run OCR');
    }

    final uri = Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$visionKey');

    final requests = <Map<String, dynamic>>[];
    for (final img in images) {
      final base64Image = base64Encode(img);
      requests.add({
        'image': {'content': base64Image},
        'features': [
          {'type': 'DOCUMENT_TEXT_DETECTION', 'maxResults': 1}
        ],
      });
    }

    final body = jsonEncode({'requests': requests});

    final resp = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: body).timeout(const Duration(seconds: 60));
    if (resp.statusCode != 200) {
      throw Exception('Google Vision API error ${resp.statusCode}: ${resp.body}');
    }

    final Map<String, dynamic> decoded = jsonDecode(resp.body);
    final List<dynamic>? responses = decoded['responses'] as List<dynamic>?;
    if (responses == null) return '';

    final pieces = <String>[];
    for (final r in responses) {
      final fullText = (r as Map<String, dynamic>)['fullTextAnnotation']?['text'] as String?;
      if (fullText != null && fullText.trim().isNotEmpty) {
        pieces.add(fullText.trim());
      } else {
        final annotations = r['textAnnotations'] as List<dynamic>?;
        if (annotations != null && annotations.isNotEmpty) {
          final t = annotations[0]['description'] as String?;
          if (t != null && t.trim().isNotEmpty) pieces.add(t.trim());
        }
      }
    }

    return pieces.join('\n\n----PAGE----\n\n');
  }

  /// Fallback: Parse bill from OCR text (if images fail)
  static Future<Map<String, dynamic>> parseBillWithAI(String extractedText) async {
    print('🤖 AI Text Parser: Checking API key...');
    
    final apiKey = _getApiKey();
    
    print('🤖 AI Text Parser: API key found, sending request to OpenAI...');
    
    final prompt = '''
$_extractionPrompt

Bill Text:
$extractedText
''';

    try {
      print('🤖 AI Parser: Sending prompt to OpenAI GPT-5 mini...');
      
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-5-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a JSON extraction expert. Extract data from bills and return ONLY valid JSON.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'max_completion_tokens': 2000,
        }),
      ).timeout(const Duration(seconds: 60));
      
      if (response.statusCode != 200) {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        throw Exception('OpenAI API error: ${response.statusCode}');
      }
      
      final jsonResponse = jsonDecode(response.body);
      final responseText = (jsonResponse['choices']?[0]?['message']?['content'])?.toString() ?? '';

      print('🤖 AI Parser: Raw response length: ${responseText.length}');

      if (responseText.trim().isEmpty) {
        throw Exception('Empty response from AI');
      }

      return _parseResponse(responseText);
    } catch (e) {
      print('❌ AI parsing error: $e');
      // Throw exception instead of returning error silently
      throw Exception('AI parsing failed: $e');
    }
  }
  
  /// Parse the AI response and extract JSON (handles new format with rawText + extracted)
  static Map<String, dynamic> _parseResponse(String responseText) {
    // Extract JSON from response (handle markdown code blocks)
    String jsonText = responseText.trim();
    if (jsonText.startsWith('```json')) {
      jsonText = jsonText.substring(7);
    } else if (jsonText.startsWith('```')) {
      jsonText = jsonText.substring(3);
    }
    if (jsonText.endsWith('```')) {
      jsonText = jsonText.substring(0, jsonText.length - 3);
    }
    jsonText = jsonText.trim();
    
    print('🤖 AI Parser: Cleaned JSON length: ${jsonText.length}');

    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(jsonText) as Map<String, dynamic>;
    } catch (e) {
      print('❌ Failed to parse JSON from AI response. Length=${jsonText.length}');
      print('---AI raw start---');
      print(responseText.length > 1000 ? responseText.substring(0, 1000) : responseText);
      print('---AI raw end---');
      rethrow;
    }
    
    // Handle new format: { "rawText": "...", "extracted": {...} }
    final String? rawText = parsed['rawText'] as String?;
    final Map<String, dynamic> extracted = 
        (parsed['extracted'] as Map<String, dynamic>?) ?? parsed;
    
    if (rawText != null) {
      print('🤖 AI Parser: Raw OCR text (${rawText.length} chars):\n$rawText');
    }
    
    print('🤖 AI Response extracted fields: ${extracted.keys.toList()}');
    
    final result = _buildResult(extracted);
    
    // Add raw text to result for storage
    result['rawOcrText'] = rawText;
    
    return result;
  }
  
  /// Build the result map from parsed JSON
  static Map<String, dynamic> _buildResult(Map<String, dynamic> parsed) {
    // NET WEIGHT is the main weight used for valuation (pure gold weight)
    // GROSS WEIGHT is total weight including stones (optional)
    final netWeight = _parseNumber(parsed['netWeight']);
    final grossWeight = _parseNumber(parsed['weight']);
    
    return {
      'vendor': parsed['vendor']?.toString(),
      'productDescription': parsed['productDescription']?.toString(),
      'productType': parsed['productDescription']?.toString(), // For backward compatibility
      'weight': netWeight, // Main field = Net Weight for valuation
      'netWeight': netWeight,
      'grossWeight': grossWeight, // Optional: total with stones
      'weightUnit': 'grams',
      'purity': parsed['purity']?.toString(),
      'metalType': parsed['metalType']?.toString() ?? 'Gold',
      'finalAmount': _parseNumber(parsed['finalAmount']),
      
      // Stone details
      'stoneWeight': _parseNumber(parsed['stoneWeight']),
      'stoneCost': _parseNumber(parsed['stoneCost']),
      
      // Diamond details
      'diamondCarats': _parseNumber(parsed['diamondCarats']),
      'diamondCost': _parseNumber(parsed['diamondCost']),
      'diamondClarity': parsed['diamondClarity']?.toString(),
      'diamondColor': parsed['diamondColor']?.toString(),
      'diamondCut': parsed['diamondCut']?.toString(),
      'certificateNumber': parsed['certificateNumber']?.toString(),
      'certificateAgency': parsed['certificateAgency']?.toString(),
      
      // Bill details
      'goldRate': _parseNumber(parsed['goldRate']),
      'makingCharges': _parseNumber(parsed['makingCharges']),
      'gst': _parseNumber(parsed['gst']),
      'discount': _parseNumber(parsed['discount']),
      'billNumber': parsed['billNumber']?.toString(),
      'date': parsed['date']?.toString(),
      'gstin': parsed['gstin']?.toString(),
      'lineItems': parsed['lineItems'], // Store table data as-is
    };
  }
  
  static double? _parseNumber(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      // Remove commas and parse
      final cleaned = value.replaceAll(',', '').replaceAll(' ', '');
      return double.tryParse(cleaned);
    }
    return null;
  }
}
