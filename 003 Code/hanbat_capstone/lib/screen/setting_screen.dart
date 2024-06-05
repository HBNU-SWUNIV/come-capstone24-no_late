import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hanbat_capstone/model/category_model.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key:key);

  @override
  State createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text('설정'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){

        },
        child: Icon(
            Icons.add
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 15,),
            Expanded(child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('category')
                  .where('userId', isEqualTo: 'yjkoo')
                  .snapshots(),

              builder: (context, snapshot) {
                if(snapshot.hasError){
                  return Center(child: Text('카테고리 정보를 가져오지 못했습니다.'),);
                }

                if(snapshot.connectionState == ConnectionState.waiting){
                  return Center(child: CircularProgressIndicator(),);
                }

                if(snapshot.data!.docs.isNotEmpty){
                  final categories = snapshot.data!.docs
                      .map((QueryDocumentSnapshot e) => CategoryModel.fromJson(
                      json: (e.data() as Map<String, dynamic>)
                  )).toList();

                  return ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: IntrinsicHeight(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 15,
                                  child: Container(
                                    color: Color(int.parse(category.colorCode)),
                                  ),
                                ),
                                SizedBox(width: 15,),
                                Expanded(
                                    child: Container(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                          category.categoryName
                                      ),
                                    )
                                ),
                                SizedBox(
                                  child: IconButton(onPressed: (){}, icon: Icon(Icons.navigate_next)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }else{
                  return Center(child: CircularProgressIndicator(),);
                }
              },
            )),
          ],
        )
      )
    );
  }
}