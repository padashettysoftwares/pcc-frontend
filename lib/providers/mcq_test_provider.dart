import 'package:flutter/material.dart';
import '../models/mcq_question.dart';
import '../services/api_service.dart';

// ── Static CBSE Science chapter data (no server needed) ──────────
const Map<String, dynamic> _kCbseChapters = {
  '8': {
    'Science': [
      'Crop Production and Management',
      'Microorganisms: Friend and Foe',
      'Synthetic Fibres and Plastics',
      'Materials: Metals and Non-Metals',
      'Coal and Petroleum',
      'Combustion and Flame',
      'Conservation of Plants and Animals',
      'Cell: Structure and Functions',
      'Reproduction in Animals',
      'Reaching the Age of Adolescence',
      'Force and Pressure',
      'Friction',
      'Sound',
      'Chemical Effects of Electric Current',
      'Some Natural Phenomena',
      'Light',
      'Stars and the Solar System',
      'Pollution of Air and Water',
    ],
  },
  '9': {
    'Science': [
      'Matter in Our Surroundings',
      'Is Matter Around Us Pure',
      'Atoms and Molecules',
      'Structure of the Atom',
      'The Fundamental Unit of Life',
      'Tissues',
      'Motion',
      'Force and Laws of Motion',
      'Gravitation',
      'Work and Energy',
      'Sound',
      'Improvement in Food Resources',
    ],
  },
  '10': {
    'Science': [
      'Chemical Reactions and Equations',
      'Acids, Bases and Salts',
      'Metals and Non-metals',
      'Carbon and its Compounds',
      'Life Processes',
      'Control and Coordination',
      'How do Organisms Reproduce',
      'Heredity',
      'Light: Reflection and Refraction',
      'The Human Eye and the Colourful World',
      'Electricity',
      'Magnetic Effects of Electric Current',
      'Our Environment',
    ],
  },
};

class McqTestProvider extends ChangeNotifier {
  final _api = ApiService();

  Map<String, dynamic>? _chapterData;
  List<McqQuestion> _questions = [];
  List<McqScore> _scores = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;

  Map<String, dynamic>? get chapterData => _chapterData;
  List<McqQuestion> get questions => _questions;
  List<McqScore> get scores => _scores;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get error => _error;

  Future<void> loadChapters() async {
    // Chapter list is static CBSE data — no server call needed.
    _isLoading = false;
    _error = null;
    _chapterData = Map<String, dynamic>.from(_kCbseChapters);
    notifyListeners();
  }

  List<String> getChaptersForClass(String className, String subject) {
    if (_chapterData == null) return [];
    final classData = _chapterData![className];
    if (classData == null) return [];
    if (classData is Map) {
      final list = classData[subject];
      if (list is List) return list.map((e) => e.toString()).toList();
    }
    return [];
  }

  Future<bool> generateQuestions({
    required String className,
    required String subject,
    required String chapter,
  }) async {
    _isGenerating = true;
    _error = null;
    _questions = [];
    notifyListeners();
    try {
      final data = await _api.generateMcqQuestions(
        className: className,
        subject: subject,
        chapter: chapter,
      );
      if (data['questions'] != null) {
        _questions = (data['questions'] as List)
            .map((q) => McqQuestion.fromMap(q))
            .toList();
      }
      _isGenerating = false;
      notifyListeners();
      return _questions.isNotEmpty;
    } catch (e) {
      _error = e.toString();
      _isGenerating = false;
      notifyListeners();
      return false;
    }
  }

  void selectAnswer(int questionIndex, String answer) {
    if (questionIndex >= 0 && questionIndex < _questions.length) {
      _questions[questionIndex].selectedAnswer = answer;
      notifyListeners();
    }
  }

  int get score => _questions.where((q) => q.isCorrect).length;
  int get totalAnswered => _questions.where((q) => q.isAnswered).length;
  bool get allAnswered => _questions.every((q) => q.isAnswered);

  Future<bool> submitTest({
    required String studentId,
    required String className,
    required String subject,
    required String chapter,
  }) async {
    try {
      await _api.submitMcqTest(
        studentId: studentId,
        className: className,
        subject: subject,
        chapter: chapter,
        score: score,
        total: _questions.length,
        questionsData: _questions.map((q) => q.toMap()).toList(),
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadScores(String studentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.getMcqScores(studentId);
      _scores = data.map((d) => McqScore.fromMap(d)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  void resetTest() {
    _questions = [];
    _error = null;
    notifyListeners();
  }
}
