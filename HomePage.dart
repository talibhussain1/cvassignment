

import 'package:flutter/material.dart';
import 'package:shoaib/main.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';


class HomePage extends StatefulWidget {
  //const HomePage({ Key? key }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  bool isWorking = false;
  String res = "";
   CameraController  cameraController; 
   CameraImage imageCamera;

   loadModel() async{
     await Tflite.loadModel(
       model:"assets/model_unquant.tflite",
       labels:"assets/labels.txt",
     );
   }
  initCamera(){
    
    cameraController = CameraController(cameras[0],ResolutionPreset.medium);
    cameraController.initialize().then((value){
      if (!mounted) {
        return;
      }

      setState((){
        cameraController.startImageStream((imageFromStream) => 
        {
          if (!isWorking) {
              isWorking = true,
              imageCamera = imageFromStream,
              runModelonStreamFrames(),
          }
        });
      });
    });

  }
runModelonStreamFrames() async{
  if(imageCamera != null){
    var recognitions = await Tflite.runModelOnFrame(
      bytesList: imageCamera.planes.map((plane){
        return plane.bytes;
      }).toList(),
      imageHeight: imageCamera.height,
      imageWidth: imageCamera.width,
      imageMean: 127.5,
      imageStd: 127.5,
      rotation: 90,
      numResults: 2,
      threshold: 0.1,
      asynch: true,
    );

    res = '';

    recognitions.forEach((response){
      res+= response['label']+ "  " + (response["confidence"]*100 as double).toStringAsFixed(2) + "%\n\n";
    });

    setState(() {
      res;
    });

    isWorking = false;

    }
}
  @override
  void initState(){
    super.initState();
    loadModel();
  }
  
 @override
 void dispose() async{
   super.dispose();
   await Tflite.close();
   cameraController?.dispose();
 }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SafeArea(
        child: Scaffold(
          body:  Container(
            child: Column(children: [
              Stack(
                children: [
                  Center(
                child: Container(
                  color: Colors.black26,
                  height: 320,
                  width: 360,
                  ),
              ),
              Center(
                child: TextButton(
                  onPressed: ()
                  {
                    
                    initCamera();
                  },
                  child: Container(
                    margin:EdgeInsets.only(top:35) ,
                    height: 270,
                    width: 360,
                    child: imageCamera == null
                    ? Container(
                      height: 270,
                      width: 360,
                      child: Icon(Icons.photo_camera_front, color:Colors.blueAccent, size:40),
                    )
                    : AspectRatio(
                      aspectRatio: cameraController.value.aspectRatio,
                      child: CameraPreview(cameraController),
                    ),
                    ),
                    ),
              )
                ],
              ),
              Center(
                child: Container(
                  margin: EdgeInsets.only(top:55.0),
                  child:SingleChildScrollView(
                    child: Text(
                      res,
                      style: TextStyle(
                        backgroundColor: Colors.black87,
                        fontSize: 30,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                )
            ],),
          ),
        )
        
      )
    );
  }
}