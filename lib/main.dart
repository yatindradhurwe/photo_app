import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/gallery_provider.dart';
import 'providers/google_drive_provider.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const PhotoApp());
}

class PhotoApp extends StatelessWidget {
  const PhotoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GalleryProvider()),
        ChangeNotifierProvider(create: (_) => GoogleDriveProvider()),
      ],
      child: MaterialApp(
        title: 'PhotoApp',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
