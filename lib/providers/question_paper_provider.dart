import 'package:flutter/material.dart';
import '../models/question_paper.dart';
import '../services/api_service.dart';

class QuestionPaperProvider extends ChangeNotifier {
  final _api = ApiService();

  List<QuestionPaper> _papers = [];
  bool _isLoading = false;
  String? _error;

  List<QuestionPaper> get papers => _papers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPapers({String? className}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.getQuestionPapers(className: className);
      _papers = data.map((d) => QuestionPaper.fromMap(d)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<QuestionPaper?> createPaper(QuestionPaper paper) async {
    try {
      final data = await _api.createQuestionPaper(paper.toMap());
      final created = QuestionPaper.fromMap(data);
      _papers.insert(0, created);
      notifyListeners();
      return created;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deletePaper(int id) async {
    try {
      await _api.deleteQuestionPaper(id);
      _papers.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> togglePublish(int id, bool publish, {bool? includeAnswerKey}) async {
    try {
      final data = await _api.publishQuestionPaper(
        id,
        isPublished: publish,
        includeAnswerKey: includeAnswerKey,
      );
      final idx = _papers.indexWhere((p) => p.id == id);
      if (idx >= 0) {
        _papers[idx] = QuestionPaper.fromMap(data);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<QuestionPaperQuestion>?> aiGenerate(Map<String, dynamic> params) async {
    try {
      final data = await _api.aiGenerateQuestions(params);
      if (data['questions'] != null) {
        return (data['questions'] as List)
            .map((q) => QuestionPaperQuestion.fromMap(q))
            .toList();
      }
      return null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
