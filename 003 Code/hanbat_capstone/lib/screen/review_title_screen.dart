import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hanbat_capstone/model/review_title_model.dart';

class ReviewTitleScreen extends StatefulWidget {
  const ReviewTitleScreen({Key? key}) : super(key:key);

  @override
  State createState() => _ReviewTitleScreenState();
}

class _ReviewTitleScreenState extends State<ReviewTitleScreen> {

  int maxSeq = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('기록하고 싶은 항목'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 15,),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                alignment: Alignment.centerLeft,
                height: 70,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "\u{1F4D6} 일기 항목",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text("기록하고 싶은 일기 항목을 정리해보아요.")
                  ],
                ),
              ),
              Expanded(child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reviewTitle')
                    .where('userId', isEqualTo: 'yjkoo')
                    .snapshots(),

                builder: (context, snapshot){

                  if(snapshot.hasError){
                    return Center(
                      child: Text('일기 항목들을 가져오지 못했습니다.'),
                    );
                  }

                  if(snapshot.connectionState == ConnectionState.waiting){
                    return Container();
                  }

                  final reviewTitles = snapshot.data!.docs
                      .map((QueryDocumentSnapshot e) => ReviewTitleModel.fromJson(
                      json: (e.data() as Map<String, dynamic>)
                  )).toList();

                  return ListView.builder(
                      itemCount: reviewTitles.length,
                      itemBuilder: (context, index) {
                        final reviewTitle = reviewTitles[index];
                        bool _useYn = reviewTitle.useYn == "Y" ? true : false;
                        return Container(
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: IntrinsicHeight(
                              child:
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  IconButton(onPressed: (){}, icon: Icon(Icons.menu)),
                                  SizedBox(width: 15,),
                                  Expanded(child:
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      reviewTitle.titleNm,
                                    ),
                                  )
                                  ),
                                  SizedBox(width: 15,),
                                  Switch(
                                      value: _useYn,
                                      activeColor: Colors.green,
                                      onChanged: (bool value){
                                        setState(() {
                                          _useYn = value;
                                          FirebaseFirestore.instance
                                              .collection("reviewTitle")
                                              .doc(reviewTitle.titleId)
                                              .update({
                                            'useYn' : _useYn ? "Y" : "N"
                                          });
                                        });
                                      })
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                  );
                },
              )),
              SizedBox(height: 15,),
              /* TODO 추가하기
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onCreateTitleBtn,
                    child: Text('추가하기')
                ),
              ),

               */
              SizedBox(height: 5,)
            ],
          ),
        )
    );
  }

  void onCreateTitleBtn() async {

  }
}