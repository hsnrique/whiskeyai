import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:whiskeyai/api/api_service.dart';
import 'package:whiskeyai/api_key.dart';
import 'package:image_downloader/image_downloader.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  TextEditingController userInputTextEditingController =
      TextEditingController();
  final SpeechToText speechToTextInstance = SpeechToText();
  String recordedAudioString = "";
  bool isLoading = false;
  bool speakFRIDAY = true;
  String modeOpenAI = "chat";
  String imageUrlFromOpenAI = "";
  String answerTextFromOpenAI = "";
  final FlutterTts textToSpeechInstance = FlutterTts();

  void initializeSpeechToText() async {
    await speechToTextInstance.initialize();

    setState(() {});
  }

  void startListeningNow() async {
    FocusScope.of(context).unfocus();

    await speechToTextInstance.listen(onResult: onSpeechToTextResult);

    setState(() {});
  }

  void stopListeningNow() async {
    await speechToTextInstance.stop();

    setState(() {});
  }

  void onSpeechToTextResult(SpeechRecognitionResult recognitionResult) {
    recordedAudioString = recognitionResult.recognizedWords;

    speechToTextInstance.isListening
        ? null
        : sendRequestToOpenAI(recordedAudioString);

    print("Speech Result:");
    print(recordedAudioString);
  }

  Future<void> sendRequestToOpenAI(String userInput) async {
    stopListeningNow();

    setState(() {
      isLoading = true;
    });

    //send the request to openAI using our APIService
    await APIService().requestOpenAI(userInput, modeOpenAI, 2000).then((value) {
      setState(() {
        isLoading = false;
      });

      if (value.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Api Key you are/were using expired or it is not working anymore.",
            ),
          ),
        );
      }

      userInputTextEditingController.clear();

      final responseAvailable = jsonDecode(value.body);

      if (modeOpenAI == "chat") {
        setState(() {
          answerTextFromOpenAI = utf8.decode(
              responseAvailable["choices"][0]["text"].toString().codeUnits);

          print("ChatGPT Chatbot: ");
          print(answerTextFromOpenAI);
        });

        if (speakFRIDAY == true) {
          textToSpeechInstance.speak(answerTextFromOpenAI);
        }
      } else {
        //image generation
        setState(() {
          imageUrlFromOpenAI = responseAvailable["data"][0]["url"];

          print("Generated Dale E Image Url: ");
          print(imageUrlFromOpenAI);
        });
      }
    }).catchError((errorMessage) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error: " + errorMessage.toString(),
          ),
        ),
      );
    });
  }

  @override
  void initState() {
    super.initState();

    initializeSpeechToText();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () {
          if (!isLoading) {
            setState(() {
              speakFRIDAY = !speakFRIDAY;
            });
          }

          textToSpeechInstance.stop();
        },
        child: speakFRIDAY
            ? Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.asset("images/sound.png"),
              )
            : Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.asset("images/mute.png"),
              ),
      ),
      appBar: AppBar(
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [
            Colors.deepPurpleAccent,
            Colors.deepPurpleAccent,
          ])),
        ),
        title: const Text(
          'WhiskeyAI',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontFamily: 'Chelsea',
          ),
        ),
        titleSpacing: 10,
        elevation: 2,
        actions: const [
          //chat
          // Padding(
          //   padding: const EdgeInsets.only(right: 4, top: 4),
          //   child: InkWell(
          //     onTap: () {
          //       setState(() {
          //         modeOpenAI = "chat";
          //       });
          //     },
          //     child: Icon(
          //       Icons.auto_awesome,
          //       size: 30,
          //       color: modeOpenAI == "chat" ? Colors.white : Colors.grey,
          //     ),
          //   ),
          // ),
          //
          // //"image"
          // // Padding(
          // //   padding: const EdgeInsets.only(right: 8, left: 4),
          // //   child: InkWell(
          // //     onTap: () {
          // //       setState(() {
          // //         modeOpenAI = "image";
          // //       });
          // //     },
          // //     child: Icon(
          // //       Icons.history_edu,
          // //       size: 30,
          // //       color: modeOpenAI == "image" ? Colors.white : Colors.grey,
          // //     ),
          // //   ),
          // // ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(
                height: 40,
              ),

              //image
              Center(
                child: InkWell(
                  onTap: () {
                    speechToTextInstance.isListening
                        ? stopListeningNow()
                        : startListeningNow();
                  },
                  child: speechToTextInstance.isListening
                      ? Center(
                          child: LoadingAnimationWidget.beat(
                            size: 200,
                            color: speechToTextInstance.isListening
                                ? Colors.deepPurple
                                : isLoading
                                    ? Colors.deepPurple[400]!
                                    : Colors.deepPurple[200]!,
                          ),
                        )
                      : Image.asset(
                          "images/assistant_icon.png",
                          height: 220,
                          width: 250,
                        ),
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                'Peça uma sugestão baseada em nota sensorial ou insira o nome do Whiskey desejado:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 20),

              //text field with a button
              Row(
                children: [
                  //text field
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: TextField(
                        controller: userInputTextEditingController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Ex: "Nota Amadeirada" ou "Jameson"',
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  //button
                  InkWell(
                    onTap: () {
                      if (userInputTextEditingController.text.isNotEmpty) {
                        sendRequestToOpenAI(
                            userInputTextEditingController.text.toString());
                      }
                    },
                    child: AnimatedContainer(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        color: Colors.deepPurpleAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      duration: const Duration(
                        milliseconds: 1000,
                      ),
                      curve: Curves.bounceInOut,
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              //display result
              modeOpenAI == "chat"
                  ? SelectableText(
                      answerTextFromOpenAI,
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.grey[900],
                      ),
                    )
                  : modeOpenAI == "image" && imageUrlFromOpenAI.isNotEmpty
                      ? Column(
                          //image
                          children: [
                            Image.network(
                              imageUrlFromOpenAI,
                            ),
                            const SizedBox(
                              height: 14,
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                String? imageStatus =
                                    await ImageDownloader.downloadImage(
                                        imageUrlFromOpenAI);

                                if (imageStatus != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "Download efetuado com sucesso."),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                              ),
                              child: const Text(
                                "Download",
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container()
            ],
          ),
        ),
      ),
    );
  }
}
