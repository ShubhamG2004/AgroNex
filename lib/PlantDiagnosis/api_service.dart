import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

// Replace with your actual constants
const String BASE_URL = 'https://api.openai.com/v1'; // Correct OpenAI API base URL
const String API_KEY = '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'; // Replace with your API key

class ApiService {
  final Dio _dio = Dio();

  /// Encodes an image file to a Base64 string
  Future<String> encodeImage(File image) async {
    final bytes = await image.readAsBytes();
    return base64Encode(bytes);
  }

  /// Sends a disease name to GPT and retrieves the response with precautions
  Future<String> sendMessageGPT({required String diseaseName}) async {
    try {
      final response = await _dio.post(
        "$BASE_URL/chat/completions",
        options: Options(
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $API_KEY',
            HttpHeaders.contentTypeHeader: "application/json",
          },
        ),
        data: jsonEncode({
          "model": "gpt-4o", // Use the correct model name
          "messages": [
            {
              "role": "user",
              "content":
              "GPT, upon receiving the name of a plant disease, provide three precautionary measures to prevent or manage the disease. These measures should be concise, clear, and limited to one sentence each. No additional information or context is needed—only the three precautions in bullet-point format. The disease is $diseaseName.",
            }
          ],
          "max_tokens": 100, // Adjust token limit as needed
        }),
      );

      final jsonResponse = response.data;

      if (jsonResponse['error'] != null) {
        throw HttpException(jsonResponse['error']["message"]);
      }

      return jsonResponse["choices"][0]["message"]["content"];
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  /// Sends an image to GPT-4 Vision for analysis
  Future<String> sendImageToGPT4Vision({
    required File image,
    int maxTokens = 50,
    String model = "gpt-4o",
  }) async {
    final String base64Image = await encodeImage(image);

    try {
      final response = await _dio.post(
        "$BASE_URL/chat/completions",
        options: Options(
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $API_KEY',
            HttpHeaders.contentTypeHeader: "application/json",
          },
        ),
        data: jsonEncode({
          "model": model,
          "messages": [
            {
              "role": "user",
              "content":
              "GPT, your task is to identify plant health issues with precision. Analyze the following image, and detect all abnormal conditions, whether they are diseases, pests, deficiencies, or decay. Respond strictly with the name of the condition identified, and nothing else—no explanations, no additional text. If a condition is unrecognizable, reply with 'I don’t know'. If the image is not plant-related, say 'Please pick another image'.",
            }
          ],
          "images": [
            {
              "type": "image/jpeg",
              "data": base64Image,
            }
          ],
          "max_tokens": maxTokens,
        }),
      );

      final jsonResponse = response.data;

      if (jsonResponse['error'] != null) {
        throw HttpException(jsonResponse['error']["message"]);
      }

      return jsonResponse["choices"][0]["message"]["content"];
    } catch (error) {
      throw Exception('Error: $error');
    }
  }
}
