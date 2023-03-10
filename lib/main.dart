import 'package:flutter/material.dart';
import 'package:flutter_qr_bar_scanner/qr_bar_scanner_camera.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:wakelock/wakelock.dart';
import 'package:http/http.dart' as http;
import 'package:string_splitter/string_splitter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'color_schemes.g.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:awesome_dialog/awesome_dialog.dart';


Future<void> main() async {
  Get.put(IsLoadingController());

  runApp(MyApp());
  /*
  String url = "https://f7cb-203-237-200-29.jp.ngrok.io/abc";
  var response = await http.get(Uri.parse(url));
  var statusCode = response.statusCode;
  var responseHeaders = response.headers;
  String responseBody = utf8.decode(response.bodyBytes);

  List<dynamic> list = jsonDecode(responseBody);
  print(list);
  print(list[0]['id']);
  print(list[0]['title']); */
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qr Code Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        //primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Qr Code Scanner'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class Post {
  final String mal;

  Post({required this.mal});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
        mal: json['mal']
    );
  }
}

class IsLoadingController extends GetxController {
  static IsLoadingController get to => Get.find();

  final _isLoading = false.obs;

  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;
  void setIsLoading(bool value) => _isLoading.value = value;
}

class _MyHomePageState extends State<MyHomePage> {
  String? _qrInfo = '????????? QR ????????? ??????????????????';
  bool _canVibrate = true;
  bool _camState = false;
  String _dataString = "Initial QR Code";
  final GlobalKey qrKey= GlobalKey();
  late QRViewController controller;

  @override
  void initState() {
    super.initState();
    _init();
  }

  /// ????????? ??????
  _init() async {
    bool canVibrate = await Vibrate.canVibrate;
    setState(() {
      // ?????? ?????? ??????
      Wakelock.enable();

      // QR ?????? ?????? ??????
      _camState = true;

      // ?????? ??????
      _canVibrate = canVibrate;
      _canVibrate
          ? debugPrint('This device can vibrate')
          : debugPrint('This device cannot vibrate');
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  ///url ????????? ?????? ??????
  Future<String> send_post(String? url) async {
    final stringParts = StringSplitter.split(
      url!,
      splitters: ['/'],
      trimParts: true,
    );
    final string_exe = StringSplitter.split(
      "temp.temp."+url!,
      splitters: ['.'],
      trimParts: true,
    );

    String? ext = string_exe[string_exe.length-1];
    print("Test-=-=-=-=-"+url);
    print(string_exe.length);
    print(string_exe);
    print("-"+ext+"-");
    print("url: "+url);
    if(ext.compareTo("exe") == 0) {
      IsLoadingController.to.isLoading = false;
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        headerAnimationLoop: false,
        animType: AnimType.topSlide,
        showCloseIcon: true,
        //closeIcon: const Icon(Icons.close_fullscreen_outlined),
        title: 'Warning',
        desc: "???????????? QR??? ??????????????? ???????????? ????????????.",
        btnCancelOnPress: () {},
        onDismissCallback: (type) {
          debugPrint('Dialog Dismiss from callback $type');
        },
        btnOkOnPress: () {},
      ).show();
      return "exe";
    }else {

      http.Response res = await http.post(
          Uri.parse('https://caps-server-jyxtk.run.goorm.io/test'),
          body: { //????????? ????????? ???????????? json ???????????? ???????????? ????????????.
            'domain': stringParts[0]
          });

      print("res  :   " + res.body);
      Map<String, dynamic> list = json.decode(res.body);
      print(list);

      print("list['mal'] : ");
      String mal = list['mal'];

      print("mal: " + mal);
      IsLoadingController.to.isLoading = false;

      if (mal.compareTo("0") == 0) {
        _launchUrl("http://" + url);
      }
      else if (mal.compareTo("0") != 0) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.rightSlide,
          headerAnimationLoop: false,
          title: '! Malware !',
          desc: "???????????? QR??? ??????????????? ???????????? ????????????.",
          btnOkOnPress: () {},
          btnOkIcon: Icons.cancel,
          btnOkColor: Colors.red,
        ).show();
      }
      return list['mal']; //????????? ???????????? String ?????? ??????
    }
  }


/*
  Future<String> getData(String url) async {
    //http.get??? ???????????? Future?????? ????????? async ?????? ????????? await??? ????????? ??? ??????.
    http.Response res = await http.get(Uri.parse('https://a0db-220-123-168-138.jp.ngrok.io/test/'));
    List<dynamic> list = jsonDecode(res.body);
    print(list[0]['mal'].runtimeType);
    String mal = list[0]['mal'];
    if(mal.compareTo("0")!=0)
      _launchUrl(url);
    else
      showAlertDialog(context);
    return list[0]['mal'].toString(); //????????? ???????????? String ?????? ??????

  }
*/

  ///url ??????
  Future<void> _launchUrl(String? url) async {
    if (!await launchUrl(Uri.parse(url! ?? 'default'))) {
      throw 'Could not launch $url';
    }
  }

  /// QR/Bar Code ?????? ????????? ??????
  _qrCallback(String? code) {
    if (code != _qrInfo) {
      _qrInfo = code;
      print("scanData:  ");
      print(code);
      IsLoadingController.to.isLoading = true;// ?????? ???
      FlutterBeep.beep(); // ?????????

      setState((){
        _dataString = code ?? 'default';
      });
      if (_canVibrate) Vibrate.feedback(FeedbackType.heavy); // ??????
      String string = code ?? 'default';
      string = string.toLowerCase().replaceAll('http://', '');
      string = string.toLowerCase().replaceAll('https://', '');
      print(string);
      send_post(string);
    }
    _camState = false;
  }
  //decoding
/*
  Map userMap = jsonDecode(jsonString);
  var user = User.fromJson(userMap);
*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(widget.title!, style: TextStyle(fontWeight: FontWeight.bold),),
          centerTitle: true,
          backgroundColor: Colors.amber [100],
          //leading: Image.asset("assets/images/logo.png"),

          //Image.asset('assets/images/logo.png', scale: 12,)
        ),
        body:
        Stack(
          //crossAxisAlignment: CrossAxisAlignment.center,
          children: [


            /// ????????? ?????? ????????? ?????? FittedBox ??????
            FittedBox(
                fit: BoxFit.fitWidth,
                child: Text(_qrInfo!, style: const TextStyle(fontWeight: FontWeight.bold),)
            ),Expanded(
              flex: 5,
              child: QRView(key: qrKey,
                overlay: QrScannerOverlayShape(
                  borderRadius: 10,
                  borderColor: Colors.red,
                  borderLength: 30,
                  borderWidth: 10,
                  cutOutSize: 300,
                ) ,
                onQRViewCreated: _onQRViewCreated,),
            ),
            Obx(
                  () => Offstage(
                offstage: !IsLoadingController.to.isLoading,
                child: Stack(children: <Widget>[
                  const Opacity(
                    opacity: 0.5,
                    child: ModalBarrier(dismissible: false, color: Colors.black),
                  ),
                  Center(
                    child: SpinKitCubeGrid(//??????????????????
                      itemBuilder: (context, index) {
                        return const DecoratedBox(
                          decoration: BoxDecoration(color: Colors.amber),
                        );
                      },
                    ),
                  ),
                ]),
              ),
            ),
          ],
        )

    );
  }
  void _onQRViewCreated(QRViewController controller) {
    this.controller=controller;
    controller.scannedDataStream.listen((scanData) {
      _qrCallback(scanData.code);
    }
    );
  }

}


