import 'package:cloud_firestore/cloud_firestore.dart';

/**
 * 회고 제목 관리 모델
 */
class ReviewTitleModel {
  final String userId;
  final int? seq;
  final String? titleId;
  final String titleNm;
  final String hintText;
  late final String useYn;

  ReviewTitleModel({
    required this.userId,
    this.seq,
    this.titleId,
    required this.titleNm,
    required this.hintText,
    required this.useYn,
  });

  /**
   * JSON으로부터 모델로 변환
   */
  ReviewTitleModel.fromJson({
    required Map<String, dynamic> json,
  })
      : userId = json['userId'],
        seq = json['seq'],
        titleId = json['titleId'],
        titleNm = json['titleNm'],
        hintText = json['hintText'],
        useYn = json['useYn']
  ;

  factory ReviewTitleModel.fromDocument(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;

    return ReviewTitleModel(
        userId: data['userId'],
        seq: data['seq'],
        titleId: data['titleId'],
        titleNm: data['titleNm'],
        hintText: data['hintText'],
        useYn: data['useYn'],
    );
  }

  /**
   * 모델을 JSON으로 변환
   */
  Map<String, dynamic> toJson () {
    return {
      'type' : 'title',
      'userId' : userId,
      'seq' : seq,
      'titleId': titleId,
      'titleNm': titleNm,
      'hintText': hintText,
      'useYn': useYn,
    };
  }

  /**
   * 현재 모델을 특정 속성만 변환해서 새로 생성
   */
  ReviewTitleModel copyWith({
    String? userId,
    int? seq,
    String? titleId,
    String? titleNm,
    String? hintText,
    String? useYn,
  }) {
    return ReviewTitleModel(
        userId: userId ?? this.userId,
        seq: seq ?? this.seq,
        titleId: titleId ?? this.titleId,
        titleNm: titleNm ?? this.titleNm,
        hintText: hintText ?? this.hintText,
        useYn: useYn ?? this.useYn
    );
  }
}
