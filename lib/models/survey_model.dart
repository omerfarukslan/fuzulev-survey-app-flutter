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
  final String description;
  final List<Question> questions;
  final Timestamp? createdAt;
  final List<String> allowedGroups;
  final List<String> allowedUsers;
  final List<String> allowedDepartments;
  final bool isVisible;

  final int answeredCount;
  final int targetCount;

  Survey({
    required this.id,
    required this.createdBy,
    required this.title,
    required this.description,
    required this.questions,
    this.createdAt,
    this.allowedGroups = const [],
    this.allowedUsers = const [],
    this.allowedDepartments = const [],
    this.isVisible = true,
    this.answeredCount = 0,
    this.targetCount = 0,
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
      description: data['description'],
      questions: questions,
      createdAt:
          data['createdAt'] is Timestamp
              ? data['createdAt'] as Timestamp
              : null,
      allowedGroups: List<String>.from(data['visibleToGroups'] ?? []),
      allowedUsers: List<String>.from(data['visibleToUsers'] ?? []),
      allowedDepartments: List<String>.from(data['visibleToDepartments'] ?? []),
      isVisible: data['isVisible'] ?? true,
      answeredCount: data['answeredCount'] ?? 0,
      targetCount: data['targetCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'createdBy': createdBy,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toMap()).toList(),
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'visibleToGroups': allowedGroups,
      'visibleToUsers': allowedUsers,
      'visibleToDepartments': allowedDepartments,
      'isVisible': isVisible,
      'answeredCount': answeredCount,
      'targetCount': targetCount,
    };
  }

  Survey copyWith({
    String? id,
    String? createdBy,
    String? title,
    String? description,
    List<Question>? questions,
    Timestamp? createdAt,
    List<String>? allowedGroups,
    List<String>? allowedUsers,
    List<String>? allowedDepartments,
    bool? isVisible,
    int? answeredCount,
    int? targetCount,
  }) {
    return Survey(
      id: id ?? this.id,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      description: description ?? this.description,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
      allowedGroups: allowedGroups ?? this.allowedGroups,
      allowedUsers: allowedUsers ?? this.allowedUsers,
      allowedDepartments: allowedDepartments ?? this.allowedDepartments,
      isVisible: isVisible ?? this.isVisible,
      answeredCount: answeredCount ?? this.answeredCount,
      targetCount: targetCount ?? this.targetCount,
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
