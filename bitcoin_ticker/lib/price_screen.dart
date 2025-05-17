import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'dart:io' show Platform; //for identifying platform(android, ios....)
import 'coin_data.dart';

class PriceScreen extends StatefulWidget {
  @override
  _PriceScreenState createState() => _PriceScreenState();
}

class _PriceScreenState extends State<PriceScreen> {
  String selectedCurrency = 'AUD';

  DropdownButton<String> androidDropdown() {
    List<DropdownMenuItem<String>> dropdownItems = [];
    for (String currency in currenciesList) {
      var newItem = DropdownMenuItem(
        child: Text(currency),
        value: currency,
      );
      dropdownItems.add(newItem);
    }

    return DropdownButton<String>(
      value: selectedCurrency,
      items: dropdownItems,
      onChanged: (value) {
        setState(() {
          selectedCurrency = value ?? 'INR';
          getData();
        });
      },
    );
  }

  CupertinoPicker iOSPicker(){
    List<Text> pickerItems = [];
    for (String currency in currenciesList) {
      pickerItems.add(
          Text(
          currency,
          style: TextStyle(
            color: Colors.yellowAccent,
                fontWeight: FontWeight.bold
          ),));
    }

    return CupertinoPicker(
      // backgroundColor: Colors.b,
      magnification: 1.0,
      itemExtent: 32.0,
      onSelectedItemChanged: (selectedIndex) {
        // print(selectedIndex);
        setState(() {
          selectedCurrency=currenciesList[selectedIndex];
          getData();
        });
      },
      children: pickerItems,
    );
  }

  Map<String, String> coinValues={};
  bool isWaiting=true;

  void getData() async{
    try{
      var data=await CoinData().getCoinData(selectedCurrency);
      isWaiting=false;
      setState(() {
        coinValues=data;
      });
    }catch(e){
      print(e);
    }
  }

  @override
  void initState(){
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xDF5d1eb5),
        title: Text('🤑 Coin Ticker'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              CryptoCard(
                  value: isWaiting? '?': coinValues['BTC'], selectedCurrency: selectedCurrency, cryptoCurrency: 'BTC',
                color: Colors.blue,
              ),
              CryptoCard(
                value: isWaiting? '?': coinValues['ETH'], selectedCurrency: selectedCurrency, cryptoCurrency: 'ETH',
                color: Colors.teal,
              ),
              CryptoCard(
                value: isWaiting? '?': coinValues['LTC'], selectedCurrency: selectedCurrency, cryptoCurrency: 'LTC',
                color: Colors.purple,
              ),
      Padding(
        padding: EdgeInsets.fromLTRB(18.0, 18.0, 18.0, 0),
        child: Card(
          color: Colors.white,
          elevation: 5.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 28.0),
            child: Text(
              'BTC: Bitcoin\n'
                  'ETH: Ethereum\nLTC: Litecoin',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 20.0,
                color: Colors.orange,
              ),
            ),
          ),
        ),
      ),
            ],
          ),
          Container(
              height: 150.0,
              alignment: Alignment.center,
              // padding: EdgeInsets.only(bottom: 10.0),
              color: Colors.lightBlue,
              child:iOSPicker(),
              // Platform.isIOS? iOSPicker(): androidDropdown(), //if we want platform specific picking style
          ),
        ],
      ),
    );
  }
}

class CryptoCard extends StatelessWidget {
  const CryptoCard({
    required this.value,
    required this.selectedCurrency,
    required this.cryptoCurrency,
    required this.color
  });

  final String? value;
  final String selectedCurrency;
  final String cryptoCurrency;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18.0, 18.0, 18.0, 0),
      child: Card(
        color: color,
        elevation: 5.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 28.0),
          child: Text(
            '1 $cryptoCurrency = $value $selectedCurrency',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20.0,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
