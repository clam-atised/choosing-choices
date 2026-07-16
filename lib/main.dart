import 'package:flutter/material.dart';

import 'data/cards_repository.dart';
import 'data/folders_repository.dart';
import 'data/hive/hive_database.dart';
import 'screens/folder_content_screen.dart';
import 'theme/app_colours.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveDatabase.init();
  await FoldersRepository.instance.load();
  await CardsRepository.instance.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppColours.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Choices',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColours.dark,
            appBarTheme: AppBarTheme(
              backgroundColor: AppColours.light,
              foregroundColor: AppColours.dark,
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
          ),
          home: const FolderContentScreen(
            folderId: FoldersRepository.seedFolderId,
          ),
        );
      },
    );
  }
}
