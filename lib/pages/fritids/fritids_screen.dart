import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'dart:math' as math;
import '../../provider/fritids_provider.dart';
import '../../domain/models/fritids_group.dart';
import '../../domain/models/pass_type.dart';
import '../teacherPage/widget/drawer.dart';
import 'widgets/fritids_student_list.dart';
import 'widgets/pass_type_selector.dart';
import 'fritids_history_screen.dart';

class FritidsScreen extends StatefulWidget {
  const FritidsScreen({super.key});

  @override
  State<FritidsScreen> createState() => _FritidsScreenState();
}

class _FritidsScreenState extends State<FritidsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  FritidsGroup? selectedGroup = FritidsGroup.solen;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      // Initialize with first group by default
      Future.microtask(() {
        context.read<FritidsProvider>().selectGroup(FritidsGroup.solen);
      });
    }
  }

  bool _isTablet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > 600;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final fritidsProvider = context.watch<FritidsProvider>();

    const double maxCardWidth = 180.0;
    double cardWidth = math.min(screenWidth * 0.30, maxCardWidth);

    const double maxCardHeight = 280.0;
    double cardHeight = math.min(cardWidth * 3.5, maxCardHeight);

    // FM/EM selector dimensions
    double fmEmHeight = screenHeight * 0.08;
    double fmEmWidth = screenWidth * 0.5;

    // Group cards data
    final groupCards = [
      {
        "group": FritidsGroup.solen,
        "name": "Solen",
        "icon": "☀️",
      },
      {
        "group": FritidsGroup.havet,
        "name": "Havet",
        "icon": "🌊",
      },
    ];

    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: true,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // FM/EM selector (positioned like coin calculator)
          Positioned(
            top: screenHeight * 0.65 - (fmEmHeight / 2),
            left: screenWidth * 0.5 - (fmEmWidth / 2),
            child: Container(
              height: fmEmHeight,
              width: fmEmWidth,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _PassTypeButton(
                      label: 'FM',
                      isSelected: fritidsProvider.selectedPassType == PassType.fm,
                      onTap: () => fritidsProvider.selectPassType(PassType.fm),
                      isLeft: true,
                    ),
                  ),
                  Expanded(
                    child: _PassTypeButton(
                      label: 'EM',
                      isSelected: fritidsProvider.selectedPassType == PassType.em,
                      onTap: () => fritidsProvider.selectPassType(PassType.em),
                      isLeft: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  color: const Color.fromARGB(255, 245, 142, 11),
                ),
              ),
              // Student list part
              const FritidsStudentList(),
            ],
          ),
          // Group cards (Solen & Havet)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.28 - 10,
            child: Container(
              padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
              width: MediaQuery.of(context).size.width,
              height: _isTablet(context)
                  ? MediaQuery.of(context).size.width * 0.3 + 10
                  : MediaQuery.of(context).size.width * 0.35 + 20,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: groupCards
                      .map((groupData) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              final group = groupData["group"] as FritidsGroup;
                              setState(() {
                                selectedGroup = group;
                                fritidsProvider.selectGroup(group);
                              });
                            },
                            child: AnimatedScale(
                            scale: selectedGroup == groupData['group'] ? 1.05 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            width: cardWidth,
                            height: cardHeight,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30.0),
                              boxShadow: selectedGroup == groupData['group']
                                  ? [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.4),
                                        blurRadius: 20.0,
                                        spreadRadius: 5.0,
                                      ),
                                    ]
                                  : const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        offset: Offset(0, 2),
                                        blurRadius: 6.0,
                                      ),
                                    ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Emoji icon
                                  Text(
                                    groupData['icon'] as String,
                                    style: TextStyle(
                                      fontSize: cardWidth * 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Flexible(
                                    child: AutoSizeText(
                                      groupData["name"] as String,
                                      style: const TextStyle(
                                        fontFamily: 'montserrat',
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                            ),
                        ),
                      ))
                      .toList(),
                ),
              ),
            ),
          ),
          // AppBar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              elevation: 0,
              backgroundColor: const Color.fromRGBO(245, 142, 11, 1),
              centerTitle: true,
              title: SizedBox(
                width: _isTablet(context) ? screenWidth * 0.18 : screenWidth * 0.4,
                child: Image.asset("assets/images/Algebraskolan4.png"),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const FritidsHistoryScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
            ),
          ),
          // Error message
          if (fritidsProvider.errorMessage != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Material(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          fritidsProvider.errorMessage!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          fritidsProvider.clearError();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Success indicator
          if (fritidsProvider.registrationSuccess)
            Positioned(
              top: screenHeight * 0.4,
              left: 0,
              right: 0,
              child: const Center(
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 80,
                ),
              ),
            ),
          // Bekräfta button with smooth animations
          if (fritidsProvider.selectedStudents.isNotEmpty && !fritidsProvider.isRegistering)
            Positioned(
              top: screenHeight * 0.22 - 50,
              left: 0,
              right: 0,
              child: Center(
                child: _BekraftaButton(
                  onPressed: () async {
                    // Haptic feedback for important action
                    HapticFeedback.mediumImpact();
                    final success = await fritidsProvider.registerSelectedStudents();
                    if (success && context.mounted) {
                      // Show success animation with overlay
                      showDialog(
                        context: context,
                        barrierColor: Colors.black.withOpacity(0.3),
                        barrierDismissible: false,
                        builder: (context) {
                          Future.delayed(const Duration(milliseconds: 1500), () {
                            if (context.mounted) Navigator.of(context).pop();
                          });
                          return Center(
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.elasticOut,
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Container(
                                    width: 200,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.5),
                                          blurRadius: 30,
                                          spreadRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 100,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Smooth animated Bekräfta button
class _BekraftaButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _BekraftaButton({required this.onPressed});

  @override
  State<_BekraftaButton> createState() => _BekraftaButtonState();
}

class _BekraftaButtonState extends State<_BekraftaButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF4CAF50),
                Color(0xFF45A049),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: -2,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                "Bekräfta",
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Smooth animated button for FM/EM selection
class _PassTypeButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isLeft;

  const _PassTypeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isLeft,
  });

  @override
  State<_PassTypeButton> createState() => _PassTypeButtonState();
}

class _PassTypeButtonState extends State<_PassTypeButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color.fromRGBO(245, 142, 11, 1)
                : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: widget.isLeft ? const Radius.circular(30) : Radius.zero,
              bottomLeft: widget.isLeft ? const Radius.circular(30) : Radius.zero,
              topRight: !widget.isLeft ? const Radius.circular(30) : Radius.zero,
              bottomRight: !widget.isLeft ? const Radius.circular(30) : Radius.zero,
            ),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: widget.isSelected
                    ? Colors.white
                    : const Color.fromRGBO(245, 142, 11, 1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
