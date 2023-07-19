import 'dart:convert';

import 'package:whiskeyai/api_key.dart';
import 'package:http/http.dart' as http;

class APIService
{
  Future<http.Response> requestOpenAI(String userInput, String mode, int maximumTokens) async
  {
    const String url = "https://api.openai.com/";
    final String openAiApiUrl = mode == "chat" ? "v1/completions" : "v1/images/generations";

    final body = mode == "chat"
        ?
        {
          "model": "text-davinci-003",
          "prompt": "Me sugira um whiskey com a ou as seguintes notas sensoriais"
              ", ou então, caso eu digite o nome de um whiskey, me conte a "
              "história dele e com o que ele combina, mas se atente"
              "quando eu digitar o nome do whiskey, me conte apenas a"
              "historia resumidamente completa  e com o que "
              "harmoniza, caso eu peça apenas uma indicação"
              "baseada em notas sensoriais, me responda apenas isso"
              "meu pedido é: /n$userInput",
          "max_tokens": 2000,
          "temperature": 0.9,
          "n": 1,
        }
        :
        {
          "prompt": "Me conte a história do seguinte Whiskey: $userInput",
        };
    
    final responseFromOpenAPI = await http.post(
      Uri.parse(url + openAiApiUrl),
      headers:
      {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey"
      },
      body: jsonEncode(body),
    );

    return responseFromOpenAPI;
  }
}