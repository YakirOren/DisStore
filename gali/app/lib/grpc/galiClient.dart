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
import 'package:permission_handler/permission_handler.dart';

import 'package:http/http.dart' as http;

class GaliClient {
  final SecureStorage secureStorage = SecureStorage();
  final GaliChannel channel;

  String _accessToken;
  Int64 tokenExpiresOn;
  String _refreshToken;

  gali_authClient _unauthenticatedClient;
  galiClient _authenticatedClient;

  bool
      _cachedInfo; // this is true when the client class has cached the user info from the server
  String _firstName;
  String _lastName;
  double _storage;

  String _mail;

  GaliClient(this.channel) {
    _cachedInfo = false;
    _unauthenticatedClient = gali_authClient(channel);
  }

  bool get cachedInfo => _cachedInfo;
  String get getCachedFirstName => _firstName;
  String get getCachedLastName => _lastName;
  String get getCachedMail => _mail;
  double get getUsedStorage => _storage;

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

    if (_refreshToken != null) {
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

    return false;
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
    final response = await _authenticatedClient.getUserInfo(Empty());

    // caching the user info
    _firstName = response.firstName;
    _lastName = response.lastName;
    _mail = response.mail;
    _storage = response.usedStorage;

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
    yield FileChunk(fileName: file.name);

    // opening the file as stream
    var reader = ChunkedStreamIterator(File(file.path).openRead());

    // send the file as chunks.
    while (true) {
      var data = await reader.read(2048); // reading 2048 bytes from the stream

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
    final response = _authenticatedClient.getAllFiles(Empty());

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

  Stream<double> getFile(String _fileName, String id) async* {
    final isPermissionStatusGranted = await _requestPermissions();

    if (isPermissionStatusGranted) {
      final path = await _localPath;

      if (File('$path/$_fileName').existsSync()) {
        int fileCount = 0;

        while (File('$path/$fileCount$_fileName').existsSync()) {
          fileCount++;
        }
        _fileName = fileCount.toString() + _fileName;
      }

      final response = await _authenticatedClient.getFile(FileRequest(id: id));

      int i = 0;
      for (var url in response.fragments) {
        var bytes = new List<int>.from(await http.readBytes(url));
        bytes.removeRange(0, 14); // remove the gif header from the file.

        await File('$path/$_fileName')
            .writeAsBytes(bytes, mode: FileMode.append);

        yield ((i / response.fragments.length));
        i++;
      }
    } else {
      // handle the scenario when user declines the permissions
    }
  }

  Future<StatusResponse> deleteFile(String id) async {
    final response = _authenticatedClient.deleteFile(FileRequest(id: id));

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
