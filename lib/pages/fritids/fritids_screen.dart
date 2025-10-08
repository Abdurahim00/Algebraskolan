import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import '../../provider/fritids_provider.dart';
import '../../domain/models/fritids_group.dart';
import '../../domain/models/pass_type.dart';
import '../../domain/models/student_model.dart';
import '../teacherPage/widget/drawer.dart';
import 'widgets/fritids_student_list.dart';
import 'fritids_history_screen.dart';
import '../../core/di/injection_container.dart';
import '../../domain/usecases/fritids/revert_fritids_registration_usecase.dart';
import '../../domain/usecases/fritids/get_today_fritids_registrations_usecase.dart';
import '../../widgets/revert_fritids_dialog.dart';

class FritidsScreen extends StatefulWidget {
  const FritidsScreen({super.key});

  @override
  State<FritidsScreen> createState() => _FritidsScreenState();
}

class _FritidsScreenState extends State<FritidsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

  Future<void> _handleRevertTransaction() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Get today's Fritids registrations
      final getTodayRegistrationsUseCase =
          InjectionContainer.getTodayFritidsRegistrationsUseCase;
      final result = await getTodayRegistrationsUseCase(
        const GetTodayFritidsRegistrationsParams(),
      );

      await result.fold(
        onSuccess: (registrations) async {
          if (!mounted) return;

          // Filter out already reverted registrations
          final activeRegistrations =
              registrations.where((r) => !r.isReverted).toList();

          // Show the revert dialog
          await showDialog(
            context: context,
            builder: (context) => RevertFritidsDialog(
              todayRegistrations: activeRegistrations,
              onRevert: (registrationId) async {
                await _revertSingleRegistration(registrationId);
              },
            ),
          );
        },
        onFailure: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Fel: ${error.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ett oväntat fel uppstod: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _revertSingleRegistration(String registrationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!mounted) return;

    // Show loading indicator
    final navigatorContext = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Lottie.asset(
            "assets/images/Circle Loading.json",
            width: MediaQuery.of(context).size.width * 0.3,
          ),
        ),
      ),
    );

    // Revert the registration
    final revertUseCase = InjectionContainer.revertFritidsRegistrationUseCase;
    final revertResult = await revertUseCase(
      RevertFritidsRegistrationParams(registrationId: registrationId),
    );

    // Close loading dialog
    if (mounted) navigatorContext.pop();

    if (mounted) {
      await revertResult.fold(
        onSuccess: (_) async {
          // Show success dialog with animation and text
          print('Showing success dialog...');
          showDialog(
            context: navigatorContext.context,
            barrierDismissible: false,
            builder: (successContext) => WillPopScope(
              onWillPop: () async => false,
              child: Dialog(
                backgroundColor: Colors.transparent,
                child: GestureDetector(
                  onTap: () {
                    print('Dialog tapped, closing...');
                    Navigator.of(successContext).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 150,
                          width: 150,
                          child: Lottie.asset(
                            "assets/images/checkmark (2).json",
                            repeat: false,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Registreringen har ångrats!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Eleven kan registreras igen\noch 1 algebrona har dragits av',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Tryck för att stänga',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );

          // Close success dialog after animation
          print('Waiting 2.5 seconds before auto-close...');
          await Future.delayed(const Duration(milliseconds: 2500));
          print('Attempting to close dialog... mounted: $mounted');
          if (mounted) {
            try {
              navigatorContext.pop();
              print('Dialog closed successfully');
            } catch (e) {
              print('Error closing dialog: $e');
            }
          }

          // Refresh the view to show unlocked student
          if (mounted) {
            context.read<FritidsProvider>().refresh();
          }
        },
        onFailure: (error) async {
          // Show error dialog with animation and text
          showDialog(
            context: navigatorContext.context,
            barrierDismissible: false,
            builder: (errorContext) => WillPopScope(
              onWillPop: () async => false,
              child: Dialog(
                backgroundColor: Colors.transparent,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(errorContext).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 150,
                          width: 150,
                          child: Lottie.asset(
                            "assets/images/canceled.json",
                            repeat: false,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Något gick fel!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          error.message,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Tryck för att stänga',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );

          // Close error dialog after animation
          await Future.delayed(const Duration(milliseconds: 2500));
          if (mounted) navigatorContext.pop();
        },
      );
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
    final fritidsProvider = context.read<FritidsProvider>();

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
      drawer: AppDrawer(
        onRevertTransaction: _handleRevertTransaction,
      ),
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
                    child: Selector<FritidsProvider, PassType>(
                      selector: (_, provider) => provider.selectedPassType,
                      builder: (_, selectedPassType, __) => _PassTypeButton(
                        label: 'FM',
                        isSelected: selectedPassType == PassType.fm,
                        onTap: () =>
                            fritidsProvider.selectPassType(PassType.fm),
                        isLeft: true,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Selector<FritidsProvider, PassType>(
                      selector: (_, provider) => provider.selectedPassType,
                      builder: (_, selectedPassType, __) => _PassTypeButton(
                        label: 'EM',
                        isSelected: selectedPassType == PassType.em,
                        onTap: () =>
                            fritidsProvider.selectPassType(PassType.em),
                        isLeft: false,
                      ),
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
          _GroupCardsWidget(
            initialGroup: FritidsGroup.solen,
            onGroupSelected: (group) {
              fritidsProvider.selectGroup(group);
            },
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
                width:
                    _isTablet(context) ? screenWidth * 0.18 : screenWidth * 0.4,
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
          Selector<FritidsProvider, String?>(
            selector: (_, provider) => provider.errorMessage,
            builder: (_, errorMessage, __) {
              if (errorMessage == null) return const SizedBox.shrink();
              return Positioned(
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
                            errorMessage,
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
              );
            },
          ),
          // Success indicator
          Selector<FritidsProvider, bool>(
            selector: (_, provider) => provider.registrationSuccess,
            builder: (_, registrationSuccess, __) {
              if (!registrationSuccess) return const SizedBox.shrink();
              return Positioned(
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
              );
            },
          ),
          // Bekräfta button with smooth animations
          Selector<FritidsProvider,
              ({List<StudentModel> selected, bool isRegistering})>(
            selector: (_, provider) => (
              selected: provider.selectedStudents,
              isRegistering: provider.isRegistering
            ),
            builder: (_, data, __) {
              if (data.selected.isEmpty || data.isRegistering)
                return const SizedBox.shrink();
              return Positioned(
                top: screenHeight * 0.22 - 50,
                left: 0,
                right: 0,
                child: Center(
                  child: _BekraftaButton(
                    onPressed: () async {
                      // Haptic feedback for important action
                      HapticFeedback.mediumImpact();
                      final success =
                          await fritidsProvider.registerSelectedStudents();
                      if (success && context.mounted) {
                        // Show success animation with overlay
                        showDialog(
                          context: context,
                          barrierColor: Colors.black.withOpacity(0.3),
                          barrierDismissible: false,
                          builder: (context) {
                            Future.delayed(const Duration(milliseconds: 1500),
                                () {
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
                                            color:
                                                Colors.green.withOpacity(0.5),
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
              );
            },
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

// Group cards widget - exact replication of class cards
class _GroupCardsWidget extends StatefulWidget {
  final FritidsGroup? initialGroup;
  final Function(FritidsGroup) onGroupSelected;

  const _GroupCardsWidget({
    required this.initialGroup,
    required this.onGroupSelected,
  });

  @override
  State<_GroupCardsWidget> createState() => _GroupCardsWidgetState();
}

class _GroupCardsWidgetState extends State<_GroupCardsWidget> {
  late FritidsGroup? selectedGroup;

  @override
  void initState() {
    super.initState();
    selectedGroup = widget.initialGroup;
  }

  bool _isTablet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > 600;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Larger sizing for better visibility
    const double maxCardWidth = 180.0;
    double cardWidth = math.min(screenWidth * 0.30, maxCardWidth);
    const double maxCardHeight = 280.0;
    double cardHeight = math.min(cardWidth * 3.5, maxCardHeight);

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

    return Positioned(
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
            children: groupCards
                .map((groupData) => GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedGroup = groupData["group"] as FritidsGroup;
                        });
                        widget.onGroupSelected(
                            groupData["group"] as FritidsGroup);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(
                          right: 10.0,
                          top: selectedGroup == groupData['group'] ? 10 : 0,
                        ),
                        width: cardWidth,
                        height: cardHeight,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30.0),
                          boxShadow: selectedGroup == groupData['group']
                              ? [
                                  BoxShadow(
                                    color: Colors.blue.shade100,
                                    offset: const Offset(0, 2),
                                    blurRadius: 10.0,
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
                              Text(
                                groupData['icon'] as String,
                                style: TextStyle(
                                  fontSize: cardWidth * 0.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Flexible(
                                child: AutoSizeText(
                                  "${groupData["name"]}",
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
                    ))
                .toList(),
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
              bottomLeft:
                  widget.isLeft ? const Radius.circular(30) : Radius.zero,
              topRight:
                  !widget.isLeft ? const Radius.circular(30) : Radius.zero,
              bottomRight:
                  !widget.isLeft ? const Radius.circular(30) : Radius.zero,
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
