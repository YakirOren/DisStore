import 'package:file_picker/file_picker.dart';
import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:grpc/service_api.dart' as $grpc;
import 'package:chunked_stream/chunked_stream.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/services.dart';
import 'protos/gali.pb.dart';
import 'protos/gali.pbgrpc.dart';
import 'package:device_info/device_info.dart';
import 'package:gali/secure_storage.dart';

//import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';
import 'package:permission_handler/permission_handler.dart';

class GaliClient {
  final SecureStorage secureStorage = SecureStorage();
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

    String identifier = '';
    String deviceName = '';
    final DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        var data = await deviceInfoPlugin.androidInfo;
        identifier = data.androidId; // ID for Android
        deviceName =
            data.brand + ' ' + data.model; // brand and model. eg: "Xiaomi MI 8"
      } else if (Platform.isIOS) {
        var data = await deviceInfoPlugin.iosInfo;
        identifier = data.identifierForVendor; // ID for iOS
        deviceName = data.utsname.machine; // model. eg: "iphone 7"
      }
    } on PlatformException {
      print('Failed to get platform version');
    }

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

    await SecureStorage.writeSecureData('refreshToken', _refreshToken);

    channel.setAccessTokenMetadata(_accessToken);
    _authenticatedClient =
        galiClient(channel); // create the authenticated client

    await getUserInfo();

    return response;
  }

  Future<bool> loginWithRefresh() async {
    _refreshToken = await SecureStorage.readSecureData('refreshToken');
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

    await SecureStorage.writeSecureData('refreshToken', _refreshToken);
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
  Stream<FileChunk> fragFile(PlatformFile file) async* {
    // sending the first Chunk with the metadata
    yield FileChunk(
        metadata: FileInfo(name: file.name)); // maybe remove the type ?

    // opening the file as stream
    var reader = ChunkedStreamIterator(File(file.path).openRead());

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

  Future<StatusResponse> upload(PlatformFile file) async {
    final response = await _authenticatedClient.upload(fragFile(file));

    return response;
  }

  Stream<FileInfo> getAllFiles() {
    final response = _authenticatedClient.getAllFiles(FileRequest());

    return response;
  }

  
  // request storage permissions
  Future<bool> _requestPermissions() async {
    var permission = await Permission.storage.isGranted;

    if (permission != true) {
      permission = await Permission.storage.request().isGranted;
    }

    return permission == true;
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<GenericFile> getFile(String _fileName, String id) async {
    final isPermissionStatusGranted = await _requestPermissions();

    if (isPermissionStatusGranted) {
      final path = await _localPath;
      final response =
          await _authenticatedClient.getFile(FileInfo(id: id, name: _fileName));

      if (response.fragments.length == 1) {
        print("getting one file");
        final request =
            await HttpClient().getUrl(Uri.parse(response.fragments[0]));

        final r = await request.close();
        r.pipe(File('$path/${response.metadata.name}').openWrite());

        print('$path/${response.metadata.name}');
      } else {
        print(response.fragments.length);

        int i = 0;
        for (var url in response.fragments) {
          i++;

          final request = await HttpClient().getUrl(Uri.parse(url));

          final r = await request.close();
          r.pipe(File('$path/${response.metadata.name}')
              .openWrite(mode: FileMode.append));
          print((i / response.fragments.length * 100).toStringAsFixed(0) + "%");

          // download all the files
          //
          // combine them using bytes buffer
          // save the file.

        }
      }
      return response;
    } else {
      return null;
      // handle the scenario when user declines the permissions
    }
  }

  Future<StatusResponse> deleteFile(String name, String id) async {
    final response =
        _authenticatedClient.deleteFile(FileInfo(id: id, name: name));

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