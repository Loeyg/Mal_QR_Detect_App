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
  String? _qrInfo = '스캔할 QR 코드를 준비해주세요';
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

  /// 초기화 함수
  _init() async {
    bool canVibrate = await Vibrate.canVibrate;
    setState(() {
      // 화면 꺼짐 방지
      Wakelock.enable();

      // QR 코드 스캔 관련
      _camState = true;

      // 진동 관련
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

  ///url 전송을 위한 함수
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
        desc: "스캔하신 QR은 실행파일을 포함하고 있습니다.",
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
          body: { //여기에 전송할 데이터를 json 형식으로 포함해서 전송한다.
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
          desc: "스캔하신 QR은 악성코드를 포함하고 있습니다.",
          btnOkOnPress: () {},
          btnOkIcon: Icons.cancel,
          btnOkColor: Colors.red,
        ).show();
      }
      return list['mal']; //가져올 데이터인 String 값을 리턴
    }
  }


/*
  Future<String> getData(String url) async {
    //http.get은 리턴값이 Future이기 때문에 async 함수 내에서 await로 호출할 수 있다.
    http.Response res = await http.get(Uri.parse('https://a0db-220-123-168-138.jp.ngrok.io/test/'));
    List<dynamic> list = jsonDecode(res.body);
    print(list[0]['mal'].runtimeType);
    String mal = list[0]['mal'];
    if(mal.compareTo("0")!=0)
      _launchUrl(url);
    else
      showAlertDialog(context);
    return list[0]['mal'].toString(); //가져올 데이터인 String 값을 리턴

  }
*/

  ///url 실행
  Future<void> _launchUrl(String? url) async {
    if (!await launchUrl(Uri.parse(url! ?? 'default'))) {
      throw 'Could not launch $url';
    }
  }

  /// QR/Bar Code 스캔 성공시 호출
  _qrCallback(String? code) {
    if (code != _qrInfo) {
      _qrInfo = code;
      print("scanData:  ");
      print(code);
      IsLoadingController.to.isLoading = true;// 로딩 바
      FlutterBeep.beep(); // 비프음

      setState((){
        _dataString = code ?? 'default';
      });
      if (_canVibrate) Vibrate.feedback(FeedbackType.heavy); // 진동
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


            /// 사이즈 자동 조절을 위해 FittedBox 사용
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
                    child: SpinKitCubeGrid(//요기요기요기
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


