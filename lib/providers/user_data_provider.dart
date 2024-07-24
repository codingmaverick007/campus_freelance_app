import 'package:flutter/material.dart';
import 'dart:io';

class UserData with ChangeNotifier {
  String userId = '';
  String email = '';
  String password = '';
  String title = '';
  String programme = '';
  String studentId = '';
  File? studentIdImage;
  bool isFreelancer = false;
  List<String> services = [];
  String fullName = '';
  File? profileImage;
  String bio = '';
  List<String> skills = [];
  List<String> interests = [];
  List<String> socialMediaLinks = [];
  String portfolioUrl = '';
  String workExperience = '';

  // Getter to check if user is registered
  bool get isRegistered {
    return userId.isNotEmpty; // Example condition based on userId
  }

  void updateEmail(String email) {
    this.email = email;
    notifyListeners();
  }

  void updatePassword(String password) {
    this.password = password;
    notifyListeners();
  }

  void setUserId(String id) {
    userId = id;
    notifyListeners();
  }

  void updateTitle(String title) {
    this.title = title;
    notifyListeners();
  }

  void updateProgramme(String programme) {
    this.programme = programme;
    notifyListeners();
  }

  void updateStudentId(String studentId) {
    this.studentId = studentId;
    notifyListeners();
  }

  void updateStudentIdImage(File? studentIdImage) {
    this.studentIdImage = studentIdImage;
    notifyListeners();
  }

  void updateIsFreelancer(bool isFreelancer) {
    this.isFreelancer = isFreelancer;
    notifyListeners();
  }

  void updateServices(List<String> services) {
    this.services = services;
    notifyListeners();
  }

  void updateFullName(String fullName) {
    this.fullName = fullName;
    notifyListeners();
  }

  void updateProfileImage(File? profileImage) {
    this.profileImage = profileImage;
    notifyListeners();
  }

  void updateBio(String bio) {
    this.bio = bio;
    notifyListeners();
  }

  void updateSkills(List<String> skills) {
    this.skills = skills;
    notifyListeners();
  }

  void updateInterests(List<String> interests) {
    this.interests = interests;
    notifyListeners();
  }

  void updateSocialMediaLinks(List<String> socialMediaLinks) {
    this.socialMediaLinks = socialMediaLinks;
    notifyListeners();
  }

  void updatePortfolioUrl(String portfolioUrl) {
    this.portfolioUrl = portfolioUrl;
    notifyListeners();
  }

  void updateWorkExperience(String workExperience) {
    this.workExperience = workExperience;
    notifyListeners();
  }
}
