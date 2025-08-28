import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('Custom Authentication Tests', () {
    test('Email validation should only allow algebraskolan domains', () {
      // Valid emails
      expect(isValidEmail('test@algebraskolan.se'), true);
      expect(isValidEmail('user@algebrautbildning.se'), true);
      
      // Invalid emails
      expect(isValidEmail('test@gmail.com'), false);
      expect(isValidEmail('user@example.com'), false);
    });

    test('Role mapping should convert Swedish to English', () {
      expect(mapRole('lärare'), 'teacher');
      expect(mapRole('elev'), 'student');
    });
  });
}

bool isValidEmail(String email) {
  return email.endsWith('@algebraskolan.se') || 
         email.endsWith('@algebrautbildning.se');
}

String mapRole(String swedishRole) {
  return swedishRole == 'lärare' ? 'teacher' : 'student';
}