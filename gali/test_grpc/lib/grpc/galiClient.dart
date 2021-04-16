import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:grpc/service_api.dart' as $grpc;
import 'package:chunked_stream/chunked_stream.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'protos/gali.pb.dart';
import 'protos/gali.pbgrpc.dart';

class GaliClient {
  final GaliChannel channel;

  String _accessToken;
  Int64 tokenExpiresOn;
  String _refreshToken;

  gali_authClient _unauthenticatedClient;
  galiClient _authenticatedClient;

  bool
      _cachedBalance; // this is true when the client class has cached the user's balance
  String _balance;

  bool
      _cachedInfo; // this is true when the client class has cached the user info from the server
  String _firstName;
  String _lastName;

  List<UserInfoResponse> _topUsers;
  List<String> _profileImages;

  String _mail;
  int _imageID;

  // ctor
  GaliClient(this.channel) {
    _cachedInfo = false;
    _unauthenticatedClient = gali_authClient(channel);
  }

  bool get cachedBalance => _cachedBalance;
  String get getCachedBalance => _balance;

  bool get cachedInfo => _cachedInfo;
  String get getCachedFirstName => _firstName;
  String get getCachedLastName => _lastName;

  List<String> get getCachedProfileImages => _profileImages;
  List<UserInfoResponse> get getTopUsers => _topUsers;
  String get getCachedMail => _mail;
  int get getCachedImageID => _imageID;

  Future<LoginResponse> login(String mail, String password) async {
    LoginResponse response;

    String identifier = '48kg840';
    String deviceName = 'Iphone';
    // final DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();
    // try {
    //   if (Platform.isAndroid) {
    //     var data = await deviceInfoPlugin.androidInfo;
    //     identifier = data.androidId; // ID for Android
    //     deviceName = data.brand + ' ' + data.model; // brand and model. eg: "Xiaomi MI 8"
    //   } else if (Platform.isIOS) {
    //     var data = await deviceInfoPlugin.iosInfo;
    //     identifier = data.identifierForVendor; // ID for iOS
    //     deviceName = data.utsname.machine; // model. eg: "iphone 7"
    //   }
    // } on PlatformException {
    //   print('Failed to get platform version');
    // }

    try {
      response = await _unauthenticatedClient.login(LoginRequest()
        ..mail = mail
        ..password = password
        ..identifier = identifier
        ..deviceName = deviceName);
    } catch (e) {
      rethrow; // cant login so throw the error
    }

    _accessToken = response.accessToken;
    tokenExpiresOn = response.expiresOn;
    _refreshToken = response.refreshToken;

    channel.setAccessTokenMetadata(_accessToken);
    _authenticatedClient =
        galiClient(channel); // create the authenticated client

    await getUserInfo();

    return response;
  }

  Future<bool> loginWithRefresh() async {
    LoginResponse response;

    try {
      response = await _unauthenticatedClient
          .refreshToken(RefreshTokenRequest()..refreshToken = _refreshToken);
    } catch (e) {
      //rethrow; // cant login so throw the error
      return false;
    }

    _accessToken = response.accessToken;
    tokenExpiresOn = response.expiresOn;
    _refreshToken = response.refreshToken;

    channel.setAccessTokenMetadata(_accessToken);
    _authenticatedClient =
        galiClient(channel); // create the authenticated client

    await getUserInfo();

    return true;
  }

  Future<StatusResponse> register(
      String firstName, String lastName, String mail, String password) async {
    final response = await _unauthenticatedClient.register(RegisterRequest()
          ..firstName = firstName
          ..lastName = lastName
          ..mail = mail
          ..password =
              password // add a small hash logic as sending a plain text password isnt a good practice
        );

    return response;
  }

  // resendCode asks the server to send the given mail a new otp code
  // getVerifyCode may fail and return Unavailable because the user is on timeout.
  Future<StatusResponse> resendCode(String mail) async {
    final response =
        await _unauthenticatedClient.getVerifyCode(CodeRequest()..mail = mail);
    return response;
  }

  Future<LoginResponse> refreshAccessToken() async {
    final response = await _unauthenticatedClient
        .refreshToken(RefreshTokenRequest()..refreshToken = _refreshToken);

    _accessToken = response.accessToken;
    tokenExpiresOn = response.expiresOn;
    _refreshToken = response.refreshToken;
    channel.setAccessTokenMetadata(_accessToken);

    return response;
  }

  Future<UserInfoResponse> getUserInfo() async {
    final response = await _authenticatedClient.getUserInfo(UserInfoRequest());

    // caching the user info
    _firstName = response.firstName;
    _lastName = response.lastName;
    _mail = response.mail;

    return response;
  }

  Future<StatusResponse> verify(String code, String mail) async {
    final response = await _unauthenticatedClient.verify(VerifyRequest()
      ..code = code
      ..mail = mail);

    return response;
  }

  // fragFile returns a stream of file chunks of the given file.
  Stream<FileChunk> fragFile(String filename) async* {

    // sending the first Chunk with the metadata
    yield FileChunk(metadata: FileInfo(name: filename, type: ".png")); // maybe remove the type ?

    // opening the file as stream
    var reader = ChunkedStreamIterator(File(filename).openRead());

    
    while (true) {
      var data = await reader.read(512); // reading 512 bytes from the stream
      
      // contiune to read untill the end of the file has been reached.
      if (data.length == 0) {
        print('End of file reached');
        break;
      }

      yield FileChunk(content: data);

    }

  }

  Future<StatusResponse> upload(String filename) async {
    final response = await _authenticatedClient.upload(fragFile(filename));

    return response;
  }

  Future<StatusResponse> resetPassword(
      String mail, String password, String code) async {
    final response =
        await _unauthenticatedClient.resetPassword(ResetPasswordRequest()
          ..mail = mail
          ..password = password
          ..code = code);

    return response;
  }
}

// implementing the ClientChannel to have an interceptor to set the authorization
// metadata header when each request is invoked
class GaliChannel implements $grpc.ClientChannel {
  final $grpc.ClientChannel channel;
  CallOptions _options;

  GaliChannel(this.channel); // ctor

  @override
  Future<void> shutdown() => channel.shutdown();

  @override
  Future<void> terminate() => channel.terminate();

  @override
  ClientCall<Q, R> createCall<Q, R>(
      ClientMethod<Q, R> method, Stream<Q> requests, CallOptions options) {
    return channel.createCall<Q, R>(
        method, requests, options.mergedWith(_options));
  }

  void setAccessTokenMetadata(String accessToken) {
    _options = CallOptions(metadata: {'authorization': accessToken});
  }
}
