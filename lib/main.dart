// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

// NOTICE : Part of the code here was copy/pasted from the Google Sign In
// flutter library.

import 'dart:async';
import 'dart:convert' show json;
import 'dart:io';

import "package:http/http.dart" as http;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: <String>[
    'email',
    'https://www.googleapis.com/auth/drive.readonly',
  ],
);

void main() {
  runApp(
    MaterialApp(
      title: 'Google Sign In',
      home: SignInDemo(),
    ),
  );
}

class SignInDemo extends StatefulWidget {
  @override
  State createState() => SignInDemoState();
}

class AuthClient extends http.BaseClient {
  final http.Client _baseClient;
  final Map<String, String> _headers;

  AuthClient(this._baseClient, this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _baseClient.send(request);
  }
}

class SignInDemoState extends State<SignInDemo> {
  GoogleSignInAccount _currentUser;
  List<drive.File> _documents = List();

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      setState(() {
        _currentUser = account;
      });
      if (_currentUser != null) {
        _getDocuments();
      }
    });
    _googleSignIn.signInSilently();
  }

  void _getDocuments() async {
    final client = http.Client();
    var header = await _currentUser.authHeaders;
    var authClient = AuthClient(client, header);
    var api = new drive.DriveApi(authClient);

    var calendar = CalendarApi(authClient);

    calendar.events.quickAdd(calendarId, "")

    var pageToken = null;
    _documents.clear();
    do {
      // TODO: Change q to search for files, like "name contains 'pdf'"
      var fileList = await api.files.list(
          q: null,
          pageSize: 20,
          pageToken: pageToken,
          supportsAllDrives: false,
          spaces: "drive",
          $fields: "nextPageToken, files(id, name, mimeType, thumbnailLink)");
      pageToken = fileList.nextPageToken;

      _documents.addAll(fileList.files);
    } while (pageToken != null);


    setState(() {});
  }

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }

  Future<void> _handleSignOut() => _googleSignIn.disconnect();

  Widget _buildBody() {
    if (_currentUser != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          ListTile(
            leading: GoogleUserCircleAvatar(
              identity: _currentUser,
            ),
            title: Text(_currentUser.displayName ?? ''),
            subtitle: Text(_currentUser.email ?? ''),
          ),
          const Text("Signed in successfully."),
          Expanded(
            child: ListView.builder(
              itemCount: _documents.length,
              itemBuilder: (BuildContext context, int index) {
                var file = _documents[index];
                if (file.thumbnailLink != null && file.mimeType.contains("image")) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: double.infinity,
                            child: Image.network(
                              file.thumbnailLink,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(file.name),
                          )
                        ],
                      ),
                    ),
                  );
                } else {
                  Widget leadingIcon;
                  if (file.mimeType.contains("folder")) {
                    leadingIcon = Icon(Icons.folder);
                  }

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      child: ListTile(
                        leading: leadingIcon,
                        title: Text(file.name),
                        subtitle: Text(file.mimeType),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          RaisedButton(
            child: const Text('SIGN OUT'),
            onPressed: _handleSignOut,
          ),
          RaisedButton(
            child: const Text('REFRESH'),
            onPressed: null,
          ),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          const Text("You are not currently signed in."),
          RaisedButton(
            child: const Text('SIGN IN'),
            onPressed: _handleSignIn,
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Google Sign In'),
        ),
        body: ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: _buildBody(),
        ));
  }
}
