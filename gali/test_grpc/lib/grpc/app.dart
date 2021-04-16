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

  
    // when logging in we get the auth tokens and we need to send the access token with every request
    print('sendLoginRequest(Correct)...');
    try {
      print('Login response recieved:\n${await client.login('israel@israeli.co.il', '2hard2guess')}');
    } catch (e) {
      print(e);
      e.toString();
    }

    // try {
    //   await client.getUserInfo();
    // } catch (e) {
    // }


    try {
      print('Login response recieved:\n${await client.upload('test.jpg')}');
      print("DONE!");
    } catch (e) {
      print(e);
      e.toString();
    }


    
  await client.channel.shutdown();
}
