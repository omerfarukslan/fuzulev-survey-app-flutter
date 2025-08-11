import 'package:anket/models/survey_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddSurveyScreen extends StatefulWidget {
  const AddSurveyScreen({super.key});

  @override
  State<AddSurveyScreen> createState() => _AddSurveyScreenState();
}

class _AddSurveyScreenState extends State<AddSurveyScreen> {
  List<QuestionData> questions = [QuestionData()];

  final TextEditingController _titleController = TextEditingController();

  final Set<String> selectedGroups = {};
  final Set<String> selectedUsers = {};

  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  void addQuestion() {
    setState(() {
      questions.add(QuestionData());
    });
  }

  Future<void> saveSurvey() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      if (_titleController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen anket adını girin')),
        );
        return;
      }

      final surveyQuestions =
          questions
              .where((q) => q.textController.text.trim().isNotEmpty)
              .map(
                (q) => {
                  "questionText": q.textController.text.trim(),
                  "type": q.type,
                  "options":
                      q.type == "multiple_choice"
                          ? q.options
                              .map((o) => o.text.trim())
                              .where((t) => t.isNotEmpty)
                              .toList()
                          : [],
                  "allowMultipleAnswers":
                      q.type == "multiple_choice" ? q.allowMultiple : false,
                },
              )
              .toList();

      if (surveyQuestions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen en az bir soru girin')),
        );
        return;
      }

      if (selectedGroups.isEmpty && selectedUsers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen hedef kitle seçin')),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('surveys').add({
        'title': _titleController.text.trim(),
        'questions': surveyQuestions,
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'visibleToGroups': selectedGroups.toList(),
        'visibleToUsers': selectedUsers.toList(),
        'isVisible': true,
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  Widget _buildAudienceSelector() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.lightBlueAccent],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: [Tab(text: "Gruplar"), Tab(text: "Kullanıcılar")],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            child: TabBarView(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('groups')
                          .orderBy('name')
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final groups =
                        snapshot.data!.docs.where((g) {
                          final name = g['name'].toString().toLowerCase();
                          return name.contains(searchQuery);
                        }).toList();

                    return ListView(
                      children:
                          groups.map((g) {
                            final id = g.id;
                            final name = g['name'];
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              child: CheckboxListTile(
                                title: Text(name),
                                value: selectedGroups.contains(id),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      selectedGroups.add(id);
                                    } else {
                                      selectedGroups.remove(id);
                                    }
                                  });
                                },
                              ),
                            );
                          }).toList(),
                    );
                  },
                ),
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('users')
                          .orderBy('name')
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final users =
                        snapshot.data!.docs.where((u) {
                          final name = u['name'].toString().toLowerCase();
                          return name.contains(searchQuery);
                        }).toList();

                    return ListView(
                      children:
                          users.map((u) {
                            final id = u.id;
                            final name = u['name'];
                            final dept = u['department'] ?? '';
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              child: CheckboxListTile(
                                title: Text(name),
                                subtitle: Text(dept),
                                value: selectedUsers.contains(id),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      selectedUsers.add(id);
                                    } else {
                                      selectedUsers.remove(id);
                                    }
                                  });
                                },
                              ),
                            );
                          }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Anket Oluştur'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Anket Adı",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  ...questions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final q = entry.value;

                    return Dismissible(
                      key: ValueKey("question_$index"),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              TextField(
                                controller: q.textController,
                                decoration: InputDecoration(
                                  labelText: 'Soru ${index + 1}',
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButton<String>(
                                value: q.type,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'open_ended',
                                    child: Text('Açık Uçlu'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'multiple_choice',
                                    child: Text('Çoktan Seçmeli'),
                                  ),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    q.type = val!;
                                    if (q.type == 'multiple_choice' &&
                                        q.options.isEmpty) {
                                      q.options.add(TextEditingController());
                                    }
                                  });
                                },
                              ),
                              if (q.type == 'multiple_choice') ...[
                                Column(
                                  children:
                                      q.options.asMap().entries.map((optEntry) {
                                        final optIndex = optEntry.key;
                                        final optController = optEntry.value;
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: TextField(
                                                  controller: optController,
                                                  decoration: InputDecoration(
                                                    labelText: 'Seçenek',
                                                    filled: true,
                                                    fillColor: Colors.grey[50],
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    q.options.removeAt(
                                                      optIndex,
                                                    );
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          q.options.add(
                                            TextEditingController(),
                                          );
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.playlist_add,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: CheckboxListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text(
                                          'Birden fazla seçilebilir',
                                        ),
                                        value: q.allowMultiple,
                                        onChanged: (value) {
                                          setState(() {
                                            q.allowMultiple = value ?? false;
                                          });
                                        },
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      "Hedef Kitle",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: "Ara",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildAudienceSelector(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "ekleBtn",
            onPressed: addQuestion,
            backgroundColor: Colors.green,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "kaydetBtn",
            onPressed: saveSurvey,
            backgroundColor: Colors.blueAccent,
            child: const Icon(Icons.save),
          ),
        ],
      ),
    );
  }
}
