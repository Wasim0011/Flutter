import 'dart:math';

class CalculatorBrain{
  CalculatorBrain({required this.height, required this.weight});
  final int height;
  final int weight;

  double _bmi=0; //now bmi will be private

  String calculateBMI(){
    _bmi=weight/pow(height/100, 2);

    return _bmi.toStringAsFixed(1);
  }

  String getResult(){
    if(_bmi>=25){
      return 'Overweight';
    }else if(_bmi>18.5){
      return 'Normal';
    }else{
      return 'Underweight';
    }
  }

  String getInterpretation(){
    if(_bmi>=25){
      return 'You have a higher weight than normal body weight.\nTry to exercise more.';
    }else if(_bmi>18.5){
      return 'You have a normal body weight.\nGood job!';
    }else{
      return 'You have a lower weight than normal body weight.\nYou can eat more.';
    }
  }
}