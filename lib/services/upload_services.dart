import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<String> uploadImageToCloudinary(File imageFile) async {
  // Replace with your Cloudinary credentials
  // ignore: unused_local_variable
  final cloudName = 'duwjdqbdh'; // Your Cloudinary cloud name
  // ignore: unused_local_variable
  final apiKey = '827531881732142'; // Your Cloudinary API key
  final uploadPreset = 'events'; // Your unsigned upload preset name

  // Cloudinary API endpoint
  final url = Uri.parse(
    'https://api.cloudinary.com/v1_1/duwjdqbdh/image/upload',
  );

  // Create a multipart request
  final request =
      http.MultipartRequest('POST', url)
        ..fields['upload_preset'] =
            uploadPreset // Add the upload preset
        ..files.add(
          await http.MultipartFile.fromPath('file', imageFile.path),
        ); // Add the image file

  // Send the request
  final response = await request.send();

  // Check the response status
  if (response.statusCode == 200) {
    final responseData = await response.stream.bytesToString();
    final jsonResponse = jsonDecode(responseData);
    return jsonResponse['secure_url']; // Return the public URL of the uploaded image
  } else {
    throw Exception('Failed to upload image');
  }
}
