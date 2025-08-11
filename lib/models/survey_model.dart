import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class QuestionData {
  TextEditingController textController = TextEditingController();
  String type = 'open_ended';
  List<TextEditingController> options = [];
  bool allowMultiple = false;
}

class Survey {
  final String id;
  final String createdBy;
  final String title;
  final List<Question> questions;
  final Timestamp? createdAt;
  final List<String> allowedGroups;
  final List<String> allowedUsers;
  final bool isVisible; // Yeni alan

  Survey({
    required this.id,
    required this.createdBy,
    required this.title,
    required this.questions,
    this.createdAt,
    this.allowedGroups = const [],
    this.allowedUsers = const [],
    this.isVisible = true, // varsayılan görünür
  });

  factory Survey.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('Geçersiz veri yapısı');
    }

    final questionsData = List<Map<String, dynamic>>.from(
      data['questions'] ?? [],
    );
    final questions = questionsData.map((q) => Question.fromMap(q)).toList();

    return Survey(
      id: doc.id,
      createdBy: data['createdBy'] ?? '',
      title: data['title'] ?? 'Adsız Anket',
      questions: questions,
      createdAt: data['createdAt'] as Timestamp?,
      allowedGroups: List<String>.from(data['visibleToGroups'] ?? []),
      allowedUsers: List<String>.from(data['visibleToUsers'] ?? []),
      isVisible: data['isVisible'] ?? true, // firestore’dan oku
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'createdBy': createdBy,
      'title': title,
      'questions': questions.map((q) => q.toMap()).toList(),
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'visibleToGroups': allowedGroups,
      'visibleToUsers': allowedUsers,
      'isVisible': isVisible, // firestore’a kaydet
    };
  }

  // copyWith metodu ile sadece belirli alanları değiştirebilirsin
  Survey copyWith({
    String? id,
    String? createdBy,
    String? title,
    List<Question>? questions,
    Timestamp? createdAt,
    List<String>? allowedGroups,
    List<String>? allowedUsers,
    bool? isVisible,
  }) {
    return Survey(
      id: id ?? this.id,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
      allowedGroups: allowedGroups ?? this.allowedGroups,
      allowedUsers: allowedUsers ?? this.allowedUsers,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

class Question {
  final String questionText;
  final String type; // 'multiple_choice' veya 'open_ended'
  final List<String> options;
  final bool allowMultipleAnswers;

  Question({
    required this.questionText,
    required this.type,
    this.options = const [],
    this.allowMultipleAnswers = false,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      questionText: map['questionText'] ?? '',
      type: map['type'] ?? 'open_ended',
      options: List<String>.from(map['options'] ?? []),
      allowMultipleAnswers: map['allowMultipleAnswers'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionText': questionText,
      'type': type,
      'options': options,
      'allowMultipleAnswers': allowMultipleAnswers,
    };
  }
}
