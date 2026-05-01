import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'csv_service.dart';

class GoogleDriveService {
  // Use the Client ID provided by the developer
  static const String _clientId =
      '282796857388-5o24fa436mvb9g5ajgop0iu0onbfnh0k.apps.googleusercontent.com';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: _clientId,
    scopes: [drive.DriveApi.driveFileScope],
  );

  /// Sign in the user (if not already signed in) and return an authenticated client.
  static Future<dynamic> _getAuthenticatedClient() async {
    try {
      var account = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();

      if (account == null) return null; // User canceled sign-in

      final authClient = await _googleSignIn.authenticatedClient();
      return authClient;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return null;
    }
  }

  /// Uploads the current database state as a backup to Google Drive.
  static Future<bool> backupToDrive(BuildContext context) async {
    try {
      final client = await _getAuthenticatedClient();
      if (client == null) {
        if (context.mounted) _showSnack(context, 'Google Sign-in failed or was canceled.');
        return false;
      }

      if (context.mounted) _showSnack(context, 'Starting backup to Google Drive...');

      final driveApi = drive.DriveApi(client);
      
      // We will look for an existing backup file to update, or create a new one.
      const fileName = 'hermyonies_wallet_backup.json';
      
      final fileList = await driveApi.files.list(
        q: "name = '$fileName' and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      final jsonString = CsvService.exportAllToJson();
      final bytes = utf8.encode(jsonString);
      final media = drive.Media(Stream.value(bytes), bytes.length);

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // Update existing file
        final existingFileId = fileList.files!.first.id!;
        await driveApi.files.update(
          drive.File(),
          existingFileId,
          uploadMedia: media,
        );
      } else {
        // Create new file
        final file = drive.File()..name = fileName;
        await driveApi.files.create(
          file,
          uploadMedia: media,
        );
      }

      if (context.mounted) _showSnack(context, 'Backup saved to Google Drive! ☁️✨');
      return true;
    } catch (e) {
      debugPrint('Backup Error: $e');
      if (context.mounted) _showSnack(context, 'Failed to save backup. 😔');
      return false;
    }
  }

  static void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFD4537E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
