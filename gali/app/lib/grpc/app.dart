import 'package:grpc/grpc.dart';

import 'galiClient.dart';

Future<void> main(List<String> args) async {



  var client = GaliClient(
    GaliChannel(
      ClientChannel(
        'localhost',
        port: 6969,
        options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
      ),
    )
  );

  
    // // when logging in we get the auth tokens and we need to send the access token with every request
    // print('sendLoginRequest(Correct)...');
    // try {
    //   print('Login response recieved:\n${await client.login('israel@israeli.co.il', '2hard2guess')}');
    // } catch (e) {
    //   print(e);
    //   e.toString();
    // }

    // try {
    //   await client.getUserInfo();
    // } catch (e) {
    // }


    // try {
    //   print('upload recieved:\n${await client.upload("niv-05.webp")}');
    //   print("DONE!");
    // } catch (e) {
    //   print(e);
    //   e.toString();
    // }
    

    // try{
    //   print('getAllFiles recieved:\n${client.getAllFiles().listen(print)}');
    //   print("func done!");
    // }
    // catch(e){
    //   print(e);
    // }


    try{
      print('getFile recieved:\n${await client.getFile("test", "607abed88bab08dfb4334d44")}');
    }
    catch(e){
      print(e);
    }
    // 
    // 
    // try{
    //   print('del recieved:\n${await client.deleteFile("test", "6079b1aba90cac1a5cb4757a")}');
    // }
    // catch(e){
    //   print(e);
    // }


    //  try{
    //   client.getAllFiles().listen(print);
    // }
    // catch(e){
    //   print(e);
    // }


    
  await client.channel.shutdown();
}
