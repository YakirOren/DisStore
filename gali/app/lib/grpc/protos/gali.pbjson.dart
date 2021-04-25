///
//  Generated code. Do not modify.
//  source: gali.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use registerRequestDescriptor instead')
const RegisterRequest$json = const {
  '1': 'RegisterRequest',
  '2': const [
    const {'1': 'FirstName', '3': 1, '4': 1, '5': 9, '10': 'FirstName'},
    const {'1': 'LastName', '3': 2, '4': 1, '5': 9, '10': 'LastName'},
    const {'1': 'Mail', '3': 3, '4': 1, '5': 9, '10': 'Mail'},
    const {'1': 'Password', '3': 4, '4': 1, '5': 9, '10': 'Password'},
  ],
};

/// Descriptor for `RegisterRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List registerRequestDescriptor = $convert.base64Decode('Cg9SZWdpc3RlclJlcXVlc3QSHAoJRmlyc3ROYW1lGAEgASgJUglGaXJzdE5hbWUSGgoITGFzdE5hbWUYAiABKAlSCExhc3ROYW1lEhIKBE1haWwYAyABKAlSBE1haWwSGgoIUGFzc3dvcmQYBCABKAlSCFBhc3N3b3Jk');
@$core.Deprecated('Use statusResponseDescriptor instead')
const StatusResponse$json = const {
  '1': 'StatusResponse',
};

/// Descriptor for `StatusResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statusResponseDescriptor = $convert.base64Decode('Cg5TdGF0dXNSZXNwb25zZQ==');
@$core.Deprecated('Use refreshTokenRequestDescriptor instead')
const RefreshTokenRequest$json = const {
  '1': 'RefreshTokenRequest',
  '2': const [
    const {'1': 'RefreshToken', '3': 1, '4': 1, '5': 9, '10': 'RefreshToken'},
  ],
};

/// Descriptor for `RefreshTokenRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshTokenRequestDescriptor = $convert.base64Decode('ChNSZWZyZXNoVG9rZW5SZXF1ZXN0EiIKDFJlZnJlc2hUb2tlbhgBIAEoCVIMUmVmcmVzaFRva2Vu');
@$core.Deprecated('Use loginRequestDescriptor instead')
const LoginRequest$json = const {
  '1': 'LoginRequest',
  '2': const [
    const {'1': 'Mail', '3': 1, '4': 1, '5': 9, '10': 'Mail'},
    const {'1': 'Password', '3': 2, '4': 1, '5': 9, '10': 'Password'},
    const {'1': 'Identifier', '3': 3, '4': 1, '5': 9, '10': 'Identifier'},
    const {'1': 'DeviceName', '3': 4, '4': 1, '5': 9, '10': 'DeviceName'},
  ],
};

/// Descriptor for `LoginRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loginRequestDescriptor = $convert.base64Decode('CgxMb2dpblJlcXVlc3QSEgoETWFpbBgBIAEoCVIETWFpbBIaCghQYXNzd29yZBgCIAEoCVIIUGFzc3dvcmQSHgoKSWRlbnRpZmllchgDIAEoCVIKSWRlbnRpZmllchIeCgpEZXZpY2VOYW1lGAQgASgJUgpEZXZpY2VOYW1l');
@$core.Deprecated('Use loginResponseDescriptor instead')
const LoginResponse$json = const {
  '1': 'LoginResponse',
  '2': const [
    const {'1': 'AccessToken', '3': 1, '4': 1, '5': 9, '10': 'AccessToken'},
    const {'1': 'ExpiresOn', '3': 2, '4': 1, '5': 3, '10': 'ExpiresOn'},
    const {'1': 'RefreshToken', '3': 3, '4': 1, '5': 9, '10': 'RefreshToken'},
  ],
};

/// Descriptor for `LoginResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loginResponseDescriptor = $convert.base64Decode('Cg1Mb2dpblJlc3BvbnNlEiAKC0FjY2Vzc1Rva2VuGAEgASgJUgtBY2Nlc3NUb2tlbhIcCglFeHBpcmVzT24YAiABKANSCUV4cGlyZXNPbhIiCgxSZWZyZXNoVG9rZW4YAyABKAlSDFJlZnJlc2hUb2tlbg==');
@$core.Deprecated('Use userInfoResponseDescriptor instead')
const UserInfoResponse$json = const {
  '1': 'UserInfoResponse',
  '2': const [
    const {'1': 'FirstName', '3': 1, '4': 1, '5': 9, '10': 'FirstName'},
    const {'1': 'LastName', '3': 2, '4': 1, '5': 9, '10': 'LastName'},
    const {'1': 'Mail', '3': 4, '4': 1, '5': 9, '10': 'Mail'},
    const {'1': 'usedStorage', '3': 5, '4': 1, '5': 1, '10': 'usedStorage'},
  ],
};

/// Descriptor for `UserInfoResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userInfoResponseDescriptor = $convert.base64Decode('ChBVc2VySW5mb1Jlc3BvbnNlEhwKCUZpcnN0TmFtZRgBIAEoCVIJRmlyc3ROYW1lEhoKCExhc3ROYW1lGAIgASgJUghMYXN0TmFtZRISCgRNYWlsGAQgASgJUgRNYWlsEiAKC3VzZWRTdG9yYWdlGAUgASgBUgt1c2VkU3RvcmFnZQ==');
@$core.Deprecated('Use fileRequestDescriptor instead')
const FileRequest$json = const {
  '1': 'FileRequest',
  '2': const [
    const {'1': 'Id', '3': 1, '4': 1, '5': 9, '10': 'Id'},
  ],
};

/// Descriptor for `FileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fileRequestDescriptor = $convert.base64Decode('CgtGaWxlUmVxdWVzdBIOCgJJZBgBIAEoCVICSWQ=');
@$core.Deprecated('Use genericFileDescriptor instead')
const GenericFile$json = const {
  '1': 'GenericFile',
  '2': const [
    const {'1': 'metadata', '3': 1, '4': 1, '5': 11, '6': '.gali.FileInfo', '10': 'metadata'},
    const {'1': 'fragments', '3': 2, '4': 3, '5': 9, '10': 'fragments'},
  ],
};

/// Descriptor for `GenericFile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List genericFileDescriptor = $convert.base64Decode('CgtHZW5lcmljRmlsZRIqCghtZXRhZGF0YRgBIAEoCzIOLmdhbGkuRmlsZUluZm9SCG1ldGFkYXRhEhwKCWZyYWdtZW50cxgCIAMoCVIJZnJhZ21lbnRz');
@$core.Deprecated('Use verifyRequestDescriptor instead')
const VerifyRequest$json = const {
  '1': 'VerifyRequest',
  '2': const [
    const {'1': 'Mail', '3': 1, '4': 1, '5': 9, '10': 'Mail'},
    const {'1': 'code', '3': 2, '4': 1, '5': 9, '10': 'code'},
  ],
};

/// Descriptor for `VerifyRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List verifyRequestDescriptor = $convert.base64Decode('Cg1WZXJpZnlSZXF1ZXN0EhIKBE1haWwYASABKAlSBE1haWwSEgoEY29kZRgCIAEoCVIEY29kZQ==');
@$core.Deprecated('Use codeRequestDescriptor instead')
const CodeRequest$json = const {
  '1': 'CodeRequest',
  '2': const [
    const {'1': 'Mail', '3': 1, '4': 1, '5': 9, '10': 'Mail'},
  ],
};

/// Descriptor for `CodeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List codeRequestDescriptor = $convert.base64Decode('CgtDb2RlUmVxdWVzdBISCgRNYWlsGAEgASgJUgRNYWls');
@$core.Deprecated('Use resetPasswordRequestDescriptor instead')
const ResetPasswordRequest$json = const {
  '1': 'ResetPasswordRequest',
  '2': const [
    const {'1': 'Mail', '3': 1, '4': 1, '5': 9, '10': 'Mail'},
    const {'1': 'Password', '3': 2, '4': 1, '5': 9, '10': 'Password'},
    const {'1': 'Code', '3': 3, '4': 1, '5': 9, '10': 'Code'},
  ],
};

/// Descriptor for `ResetPasswordRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resetPasswordRequestDescriptor = $convert.base64Decode('ChRSZXNldFBhc3N3b3JkUmVxdWVzdBISCgRNYWlsGAEgASgJUgRNYWlsEhoKCFBhc3N3b3JkGAIgASgJUghQYXNzd29yZBISCgRDb2RlGAMgASgJUgRDb2Rl');
@$core.Deprecated('Use fileChunkDescriptor instead')
const FileChunk$json = const {
  '1': 'FileChunk',
  '2': const [
    const {'1': 'fileName', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'fileName'},
    const {'1': 'Content', '3': 2, '4': 1, '5': 12, '9': 0, '10': 'Content'},
  ],
  '8': const [
    const {'1': 'data'},
  ],
};

/// Descriptor for `FileChunk`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fileChunkDescriptor = $convert.base64Decode('CglGaWxlQ2h1bmsSHAoIZmlsZU5hbWUYASABKAlIAFIIZmlsZU5hbWUSGgoHQ29udGVudBgCIAEoDEgAUgdDb250ZW50QgYKBGRhdGE=');
@$core.Deprecated('Use fileInfoDescriptor instead')
const FileInfo$json = const {
  '1': 'FileInfo',
  '2': const [
    const {'1': 'Name', '3': 1, '4': 1, '5': 9, '10': 'Name'},
    const {'1': 'Id', '3': 2, '4': 1, '5': 9, '10': 'Id'},
    const {'1': 'creationTime', '3': 3, '4': 1, '5': 3, '10': 'creationTime'},
    const {'1': 'fileSize', '3': 4, '4': 1, '5': 2, '10': 'fileSize'},
  ],
};

/// Descriptor for `FileInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fileInfoDescriptor = $convert.base64Decode('CghGaWxlSW5mbxISCgROYW1lGAEgASgJUgROYW1lEg4KAklkGAIgASgJUgJJZBIiCgxjcmVhdGlvblRpbWUYAyABKANSDGNyZWF0aW9uVGltZRIaCghmaWxlU2l6ZRgEIAEoAlIIZmlsZVNpemU=');
@$core.Deprecated('Use emptyDescriptor instead')
const Empty$json = const {
  '1': 'Empty',
};

/// Descriptor for `Empty`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List emptyDescriptor = $convert.base64Decode('CgVFbXB0eQ==');
