import 'package:flutter/material.dart';

class PaymentMethod {
  final String cardNumber;
  final String expiryDate;
  final String cvv;
  final String type;

  PaymentMethod({
    required this.cardNumber,
    required this.expiryDate,
    required this.cvv,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'cardNumber': cardNumber,
      'expiryDate': expiryDate,
      'cvv': cvv,
      'type': type,
    };
  }

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      cardNumber: map['cardNumber'],
      expiryDate: map['expiryDate'],
      cvv: map['cvv'],
      type: map['type'],
    );
  }

  static String detectCardType(String number) {
    if (number.startsWith('4')) return 'Visa';
    if (number.startsWith('5')) return 'Mastercard';
    if (number.startsWith('2')) return 'CIB';
    return 'Inconnu';
  }

  String get maskedNumber {
    return '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';
  }

  LinearGradient get gradient {
    switch (type) {
      case 'Visa':
        return const LinearGradient(
            colors: [Colors.blue, Colors.lightBlueAccent]);
      case 'Mastercard':
        return const LinearGradient(
            colors: [Colors.deepOrange, Colors.orangeAccent]);
      case 'CIB':
        return const LinearGradient(colors: [Colors.green, Colors.lightGreen]);
      default:
        return const LinearGradient(colors: [Colors.grey, Colors.black45]);
    }
  }
}
