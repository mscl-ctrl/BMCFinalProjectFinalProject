import 'package:ecommerce_app/providers/cart_provider.dart'; // 1. Need this
import 'package:ecommerce_app/providers/wishlist_provider.dart'; // ADD THIS
import 'package:ecommerce_app/screens/auth_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart'; // 2. Need this
import 'package:google_fonts/google_fonts.dart'; // 1. ADD THIS IMPORT

// 2. --- ADD OUR NEW APP COLOR PALETTE ---
const Color kRichBlack = Color(0xFF1D1F24); // A dark, rich black
const LinearGradient kBrown = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [
    Color(0xFF00F7FF), // Cyan
    Color(0xFF0094FF), // Blue
  ],
);
const Color kBrownPrimary = Color(0xFF00F7FF); // Primary color from gradient (for places that need a Color)
const Color kLightBrown = Color(0xFFD2B48C);  // A lighter tan/beige
const Color kOffWhite = Color(0xFFF8F4F0);    // A warm, off-white background
const LinearGradient kBackgroundGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [
    Color(0xFF0E3B49),
    Color(0xFF1E1B52),
  ],
);
const LinearGradient kSplashGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [
    Color(0xFF42283C), // Purple-brown
    Color(0xFF2F1D5F), // Deep purple
  ],
);
// --- END OF COLOR PALETTE ---

void main() async {
  // 1. Preserve splash screen (Unchanged)
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // 2. Initialize Firebase (Unchanged)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, 
  );

  // 3. Set web persistence (only for web platform)
  // Note: This might cause logout issues on web, so we'll handle it differently
  // await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

  // 4. --- THIS IS THE FIX ---
  // We manually create the CartProvider instance *before* runApp
  final cartProvider = CartProvider();
  final wishlistProvider = WishlistProvider();
  
  // 5. We call our new initialize method *before* runApp
  cartProvider.initializeAuthListener();
  wishlistProvider.initializeAuthListener();

  // 6. This is the old, buggy code we are replacing:
  /*
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartProvider(), // <-- This was the problem
      child: const MyApp(),
    ),
  );
  */
  
  // 7. This is the NEW code for runApp
  runApp(
    // 8. We use MultiProvider to provide both providers
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: cartProvider),
        ChangeNotifierProvider.value(value: wishlistProvider),
      ],
      child: const MyApp(),
    ),
  );
  
  // 10. Remove native splash screen (will be replaced by custom gradient splash)
  FlutterNativeSplash.remove();
}

// Custom Splash Screen Widget with Gradient
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait for next frame to ensure smooth transition from native splash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AuthWrapper()),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: kSplashGradient,
        ),
        child: Center(
          child: Image.asset(
            'assets/images/splash_logo.png',
            width: 250,
            height: 250,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'eCommerce App',
      builder: (context, child) {
        // Apply background gradient to all screens except splash (which has its own)
        // The splash screen's full-screen container will cover this anyway
        return Container(
          decoration: const BoxDecoration(
            gradient: kBackgroundGradient,
          ),
          child: child,
        );
      },
      
      // 1. --- THIS IS THE NEW, COMPLETE THEME ---
      theme: ThemeData(
        // 2. Set the main color scheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: kBrownPrimary, // Our new primary color
          brightness: Brightness.light,
          primary: kBrownPrimary,
          onPrimary: Colors.white,
          secondary: kLightBrown,
          background: Colors.transparent, // Use gradient for background
        ),
        useMaterial3: true,
        
        // 3. Set the background color for all screens
        scaffoldBackgroundColor: Colors.transparent,
        // 4. --- (FIX) APPLY THE GOOGLE FONT ---
        // This applies "Lato" to all text in the app
        textTheme: GoogleFonts.latoTextTheme(
          Theme.of(context).textTheme,
        ),
        // 5. --- (FIX) GLOBAL BUTTON STYLE ---
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kBrownPrimary, // Use primary color from gradient
            foregroundColor: Colors.white, // Text color
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Rounded corners
            ),
          ),
        ),
        // 6. --- (FIX) GLOBAL TEXT FIELD STYLE ---
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          labelStyle: TextStyle(color: kBrownPrimary.withOpacity(0.8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBrownPrimary, width: 2.0),
          ),
        ),
        // 7. --- (FIX) GLOBAL CARD STYLE ---
        cardTheme: CardThemeData(
          elevation: 1, // A softer shadow
          color: Colors.white, // Pure white cards on the off-white bg
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          // 8. This ensures the images inside the card are rounded
          clipBehavior: Clip.antiAlias, 
        ),
        
        // 9. --- (NEW) GLOBAL APPBAR STYLE ---
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, // Clean white AppBar
          foregroundColor: kRichBlack, // Black icons and text
          elevation: 0, // No shadow, modern look
          centerTitle: true,
        ),
      ),
      // --- END OF NEW THEME ---
      home: const SplashScreen(),
    );
  }
}

