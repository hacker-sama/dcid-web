import 'package:dcid_app/data/models/answer_result.dart';
import 'package:dcid_app/data/models/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UserRole maps backend wire values', () {
    expect(UserRole.fromWire('ENGINEER'), UserRole.engineer);
    expect(UserRole.fromWire('QA_ADMIN'), UserRole.qaAdmin);
    expect(UserRole.fromWire('UNKNOWN'), UserRole.operatorRole);
    expect(UserRole.qaAdmin.isAdminLevel, isTrue);
    expect(UserRole.engineer.isAdminLevel, isFalse);
  });

  test('AnswerResult parses guard + citations', () {
    final result = AnswerResult.fromJson({
      'answer': 'ok',
      'confidence': 0.83,
      'guard': {'locked': false, 'numericRule': true},
      'citations': [
        {'versionId': 'v1', 'pageNo': 12, 'bboxKey': 'crops/x.png'},
      ],
    });
    expect(result.confidence, 0.83);
    expect(result.locked, isFalse);
    expect(result.numericRule, isTrue);
    expect(result.citations.single.pageNo, 12);
  });
}
