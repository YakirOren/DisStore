///
//  Generated code. Do not modify.
//  source: gali.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:async' as $async;

import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'gali.pb.dart' as $0;
export 'gali.pb.dart';

class gali_authClient extends $grpc.Client {
  static final _$login = $grpc.ClientMethod<$0.LoginRequest, $0.LoginResponse>(
      '/gali.gali_auth/Login',
      ($0.LoginRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.LoginResponse.fromBuffer(value));
  static final _$refreshToken =
      $grpc.ClientMethod<$0.RefreshTokenRequest, $0.LoginResponse>(
          '/gali.gali_auth/RefreshToken',
          ($0.RefreshTokenRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $0.LoginResponse.fromBuffer(value));
  static final _$register =
      $grpc.ClientMethod<$0.RegisterRequest, $0.StatusResponse>(
          '/gali.gali_auth/Register',
          ($0.RegisterRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $0.StatusResponse.fromBuffer(value));
  static final _$verify =
      $grpc.ClientMethod<$0.VerifyRequest, $0.StatusResponse>(
          '/gali.gali_auth/Verify',
          ($0.VerifyRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $0.StatusResponse.fromBuffer(value));
  static final _$getVerifyCode =
      $grpc.ClientMethod<$0.CodeRequest, $0.StatusResponse>(
          '/gali.gali_auth/GetVerifyCode',
          ($0.CodeRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $0.StatusResponse.fromBuffer(value));
  static final _$resetPassword =
      $grpc.ClientMethod<$0.ResetPasswordRequest, $0.StatusResponse>(
          '/gali.gali_auth/ResetPassword',
          ($0.ResetPasswordRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) => $0.StatusResponse.fromBuffer(value));

  gali_authClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$0.LoginResponse> login($0.LoginRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$login, request, options: options);
  }

  $grpc.ResponseFuture<$0.LoginResponse> refreshToken(
      $0.RefreshTokenRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$refreshToken, request, options: options);
  }

  $grpc.ResponseFuture<$0.StatusResponse> register($0.RegisterRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$register, request, options: options);
  }

  $grpc.ResponseFuture<$0.StatusResponse> verify($0.VerifyRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$verify, request, options: options);
  }

  $grpc.ResponseFuture<$0.StatusResponse> getVerifyCode($0.CodeRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getVerifyCode, request, options: options);
  }

  $grpc.ResponseFuture<$0.StatusResponse> resetPassword(
      $0.ResetPasswordRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$resetPassword, request, options: options);
  }
}

abstract class gali_authServiceBase extends $grpc.Service {
  $core.String get $name => 'gali.gali_auth';

  gali_authServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.LoginRequest, $0.LoginResponse>(
        'Login',
        login_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LoginRequest.fromBuffer(value),
        ($0.LoginResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RefreshTokenRequest, $0.LoginResponse>(
        'RefreshToken',
        refreshToken_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.RefreshTokenRequest.fromBuffer(value),
        ($0.LoginResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RegisterRequest, $0.StatusResponse>(
        'Register',
        register_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.RegisterRequest.fromBuffer(value),
        ($0.StatusResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.VerifyRequest, $0.StatusResponse>(
        'Verify',
        verify_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.VerifyRequest.fromBuffer(value),
        ($0.StatusResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CodeRequest, $0.StatusResponse>(
        'GetVerifyCode',
        getVerifyCode_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CodeRequest.fromBuffer(value),
        ($0.StatusResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ResetPasswordRequest, $0.StatusResponse>(
        'ResetPassword',
        resetPassword_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ResetPasswordRequest.fromBuffer(value),
        ($0.StatusResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.LoginResponse> login_Pre(
      $grpc.ServiceCall call, $async.Future<$0.LoginRequest> request) async {
    return login(call, await request);
  }

  $async.Future<$0.LoginResponse> refreshToken_Pre($grpc.ServiceCall call,
      $async.Future<$0.RefreshTokenRequest> request) async {
    return refreshToken(call, await request);
  }

  $async.Future<$0.StatusResponse> register_Pre(
      $grpc.ServiceCall call, $async.Future<$0.RegisterRequest> request) async {
    return register(call, await request);
  }

  $async.Future<$0.StatusResponse> verify_Pre(
      $grpc.ServiceCall call, $async.Future<$0.VerifyRequest> request) async {
    return verify(call, await request);
  }

  $async.Future<$0.StatusResponse> getVerifyCode_Pre(
      $grpc.ServiceCall call, $async.Future<$0.CodeRequest> request) async {
    return getVerifyCode(call, await request);
  }

  $async.Future<$0.StatusResponse> resetPassword_Pre($grpc.ServiceCall call,
      $async.Future<$0.ResetPasswordRequest> request) async {
    return resetPassword(call, await request);
  }

  $async.Future<$0.LoginResponse> login(
      $grpc.ServiceCall call, $0.LoginRequest request);
  $async.Future<$0.LoginResponse> refreshToken(
      $grpc.ServiceCall call, $0.RefreshTokenRequest request);
  $async.Future<$0.StatusResponse> register(
      $grpc.ServiceCall call, $0.RegisterRequest request);
  $async.Future<$0.StatusResponse> verify(
      $grpc.ServiceCall call, $0.VerifyRequest request);
  $async.Future<$0.StatusResponse> getVerifyCode(
      $grpc.ServiceCall call, $0.CodeRequest request);
  $async.Future<$0.StatusResponse> resetPassword(
      $grpc.ServiceCall call, $0.ResetPasswordRequest request);
}

class galiClient extends $grpc.Client {
  static final _$getUserInfo =
      $grpc.ClientMethod<$0.UserInfoRequest, $0.UserInfoResponse>(
          '/gali.gali/GetUserInfo',
          ($0.UserInfoRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $0.UserInfoResponse.fromBuffer(value));
  static final _$getFiles = $grpc.ClientMethod<$0.FileRequest, $0.GenericFile>(
      '/gali.gali/GetFiles',
      ($0.FileRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.GenericFile.fromBuffer(value));

  galiClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$0.UserInfoResponse> getUserInfo(
      $0.UserInfoRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getUserInfo, request, options: options);
  }

  $grpc.ResponseStream<$0.GenericFile> getFiles($0.FileRequest request,
      {$grpc.CallOptions? options}) {
    return $createStreamingCall(
        _$getFiles, $async.Stream.fromIterable([request]),
        options: options);
  }
}

abstract class galiServiceBase extends $grpc.Service {
  $core.String get $name => 'gali.gali';

  galiServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.UserInfoRequest, $0.UserInfoResponse>(
        'GetUserInfo',
        getUserInfo_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.UserInfoRequest.fromBuffer(value),
        ($0.UserInfoResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.FileRequest, $0.GenericFile>(
        'GetFiles',
        getFiles_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.FileRequest.fromBuffer(value),
        ($0.GenericFile value) => value.writeToBuffer()));
  }

  $async.Future<$0.UserInfoResponse> getUserInfo_Pre(
      $grpc.ServiceCall call, $async.Future<$0.UserInfoRequest> request) async {
    return getUserInfo(call, await request);
  }

  $async.Stream<$0.GenericFile> getFiles_Pre(
      $grpc.ServiceCall call, $async.Future<$0.FileRequest> request) async* {
    yield* getFiles(call, await request);
  }

  $async.Future<$0.UserInfoResponse> getUserInfo(
      $grpc.ServiceCall call, $0.UserInfoRequest request);
  $async.Stream<$0.GenericFile> getFiles(
      $grpc.ServiceCall call, $0.FileRequest request);
}
