import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class PhoneNumberInputFormatter extends TextInputFormatter {

  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {

    if(newValue.selection.baseOffset == 0){
      print(newValue.selection.baseOffset);
      return newValue.copyWith(text: '');
    } else if(newValue.text.compareTo(oldValue.text) != 0) {
      int selectionIndexFromTheRight = newValue.text.length - newValue.selection.end;
      final formatter = NumberFormat('#,###');
      int value = int.parse(newValue.text.replaceAll(formatter.symbols.GROUP_SEP, ''));
      String newText = formatter.format(value);

      return newValue.copyWith(
          text: newText,
          selection: new TextSelection.collapsed(offset: newText.length-selectionIndexFromTheRight));
    } else {
      return newValue;
    }
  }
}

class PhoneNumberDisplayFormatter {
  String getPhoneNumberFormat(String onlyNumber) {
    String formatNumber;

    if (onlyNumber.length == 11) {
      RegExp regExp = RegExp(r'(\d{3})(\d{4})(\d{4})');
      var matches = regExp.allMatches(onlyNumber);
      var match = matches.elementAt(0);
      formatNumber = '${match.group(1)}-${match.group(2)}-${match.group(3)}';
    } else if(onlyNumber.length==8) {
      RegExp regExp = RegExp(r'(\d{4})(\d{4})');
      var matches = regExp.allMatches(onlyNumber);
      var match = matches.elementAt(0);
      formatNumber = '${match.group(1)}-${match.group(2)}';
    } else {
      if(onlyNumber.indexOf('02')==0){
        if(onlyNumber.length == 9) {
          RegExp regExp = RegExp(r'(\d{2})(\d{3})(\d{4})');
          var matches = regExp.allMatches(onlyNumber);
          var match = matches.elementAt(0);
          formatNumber = '${match.group(1)}-${match.group(2)}-${match.group(3)}';
        } else {
          RegExp regExp = RegExp(r'(\d{2})(\d{4})(\d{4})');
          var matches = regExp.allMatches(onlyNumber);
          var match = matches.elementAt(0);
          formatNumber = '${match.group(1)}-${match.group(2)}-${match.group(3)}';
        }
      } else {
        RegExp regExp = RegExp(r'(\d{3})(\d{3})(\d{4})');
        var matches = regExp.allMatches(onlyNumber);
        var match = matches.elementAt(0);
        formatNumber = '${match.group(1)}-${match.group(2)}-${match.group(3)}';
      }
    }

    return formatNumber;
  }
}