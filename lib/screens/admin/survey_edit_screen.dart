import 'package:anket/models/survey_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SurveyEditScreen extends StatefulWidget {
  final String surveyId;
  const SurveyEditScreen({super.key, required this.surveyId});

  @override
  State<SurveyEditScreen> createState() => _SurveyEditScreenState();
}

class _SurveyEditScreenState extends State<SurveyEditScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String searchQuery = '';
  List<QuestionData> questions = [QuestionData()];

  final Set<String> selectedGroups = {};
  final Set<String> selectedUsers = {};

  Survey? _survey;

  @override
  void initState() {
    super.initState();
    _loadSurvey();
  }

  Future<void> _loadSurvey() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('surveys')
              .doc(widget.surveyId)
              .get();

      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Anket bulunamadı')));
          Navigator.pop(context);
        }
        return;
      }

      final survey = Survey.fromDoc(doc);

      _titleController.text = survey.title;

      final loadedQuestions = <QuestionData>[];
      for (final q in survey.questions) {
        final qd = QuestionData();
        qd.textController.text = q.questionText;
        qd.type = q.type;
        qd.allowMultiple = q.allowMultipleAnswers;
        if (q.type == 'multiple_choice') {
          qd.options =
              q.options.map((opt) => TextEditingController(text: opt)).toList();
          if (qd.options.isEmpty) {
            qd.options.add(TextEditingController());
          }
        }
        loadedQuestions.add(qd);
      }
      if (loadedQuestions.isEmpty) {
        loadedQuestions.add(QuestionData());
      }

      selectedGroups
        ..clear()
        ..addAll(survey.allowedGroups);
      selectedUsers
        ..clear()
        ..addAll(survey.allowedUsers);

      setState(() {
        questions = loadedQuestions;
        _survey = survey;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Yükleme hatası: $e')));
      Navigator.pop(context);
    }
  }

  void addQuestion() {
    setState(() {
      questions.add(QuestionData());
    });
  }

  Future<void> updateSurvey() async {
    try {
      if (_titleController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen anket adını girin')),
        );
        return;
      }

      final surveyQuestions =
          questions.where((q) => q.textController.text.trim().isNotEmpty).map((
            q,
          ) {
            return {
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
            };
          }).toList();

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

      await FirebaseFirestore.instance
          .collection('surveys')
          .doc(widget.surveyId)
          .update({
            'title': _titleController.text.trim(),
            'questions': surveyQuestions,
            'visibleToGroups': selectedGroups.toList(),
            'visibleToUsers': selectedUsers.toList(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Anket güncellendi')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Güncelleme hatası: $e')));
    }
  }

  Widget _buildAudienceSelector() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(tabs: [Tab(text: "Gruplar"), Tab(text: "Kullanıcılar")]),
          SizedBox(
            height: 300,
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
                          final name =
                              (g['name'] ?? '').toString().toLowerCase();
                          return name.contains(searchQuery);
                        }).toList();

                    return ListView(
                      children:
                          groups.map((g) {
                            final id = g.id;
                            final name = g['name'] ?? '';
                            return CheckboxListTile(
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
                          final name =
                              (u['name'] ?? '').toString().toLowerCase();
                          return name.contains(searchQuery);
                        }).toList();

                    return ListView(
                      children:
                          users.map((u) {
                            final id = u.id;
                            final name = u['name'] ?? '';
                            final dept = u['department'] ?? '';
                            return CheckboxListTile(
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

  Future<void> toggleVisibility() async {
    if (_survey == null) return;

    try {
      final newVisibility = !(_survey!.isVisible ?? true);

      await FirebaseFirestore.instance
          .collection('surveys')
          .doc(_survey!.id)
          .update({'isVisible': newVisibility});

      setState(() {
        _survey = _survey!.copyWith(isVisible: newVisibility);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newVisibility ? 'Anket artık görünür' : 'Anket artık gizli',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _searchController.dispose();
    for (final q in questions) {
      q.textController.dispose();
      for (final oc in q.options) {
        oc.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Anketi Düzenle')),
        body: const Center(child: CircularProgressIndicator()),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Anketi Düzenle'),
          actions: [
            IconButton(
              onPressed: toggleVisibility,
              icon: Icon(
                _survey?.isVisible ?? true
                    ? Icons.remove_red_eye
                    : Icons.visibility_off,
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Anket Adı",
                  border: OutlineInputBorder(),
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
                        onDismissed: (_) {
                          setState(() {
                            questions.removeAt(index);
                          });
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                TextField(
                                  controller: q.textController,
                                  decoration: InputDecoration(
                                    labelText: 'Soru ${index + 1}',
                                    border: const OutlineInputBorder(),
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
                                      if (q.type == 'open_ended') {
                                        q.options.clear();
                                        q.allowMultiple = false;
                                      }
                                    });
                                  },
                                ),
                                if (q.type == 'multiple_choice') ...[
                                  Column(
                                    children:
                                        q.options.asMap().entries.map((
                                          optEntry,
                                        ) {
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
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText: 'Seçenek',
                                                          border:
                                                              OutlineInputBorder(),
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
                                        icon: const Icon(Icons.playlist_add),
                                        tooltip: 'Seçenek Ekle',
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
              tooltip: 'Soru Ekle',
              child: const Icon(Icons.add),
            ),
            const SizedBox(height: 12),
            FloatingActionButton(
              heroTag: "guncelleBtn",
              onPressed: updateSurvey,
              backgroundColor: Colors.blueAccent,
              tooltip: 'Anketi Güncelle',
              child: const Icon(Icons.save),
            ),
          ],
        ),
      );
    }
  }
}
