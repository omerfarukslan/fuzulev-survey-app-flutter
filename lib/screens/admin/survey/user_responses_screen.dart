import 'package:anket/models/survey_model.dart';
import 'package:flutter/cupertino.dart';

class UserResponsesScreen extends StatelessWidget {
  final Survey survey;
  final Map<String, dynamic> responseData;
  final String userName;

  const UserResponsesScreen({
    super.key,
    required this.survey,
    required this.responseData,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final answers = responseData['answers'] as Map<String, dynamic>? ?? {};

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text("$userName'nin Yanıtları"),
      ),
      child: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: survey.questions.length,
          itemBuilder: (context, index) {
            final q = survey.questions[index];
            final answer = answers['q${index + 1}'];

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemGrey3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.questionText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (answer == null)
                    const Text(
                      "Cevap yok",
                      style: TextStyle(color: CupertinoColors.systemGrey),
                    )
                  else if (answer is List)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          answer.map<Widget>((opt) {
                            return Text("• $opt");
                          }).toList(),
                    )
                  else
                    Text("• $answer"),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
