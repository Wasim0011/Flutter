// import 'dart:io';

void main() {
  performTasks();
}

void performTasks() async{
  task1();
  print(task2());
  // String tast2Result=await task2();
  // task3(tast2Result);
}

void task1(){
  String result='Task 1 data';
  print('Task 1 completed');
}
Future<String> task2() async{
  Duration threeSecond=Duration(seconds:3);
  String result='';
  await Future.delayed(threeSecond, (){
    result='Task 2 data';
    print('Task 2 completed');
  });
  return result;
}
void task3(String task2Data){
  String result='Task 3 data';
  print('Task 3 completed with $task2Data');
}
