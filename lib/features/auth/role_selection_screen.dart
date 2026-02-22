import 'package:flutter/material.dart';
import 'package:pulsecare/core/constants/app_colors.dart';
import 'package:pulsecare/features/auth/widgets/role_card.dart';
import 'package:pulsecare/features/auth/login_screen.dart';
import 'package:pulsecare/core/services/auth_service.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary.withOpacity(0.1), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Spacer(),
                          // Logo or Header
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.health_and_safety,
                                size: 64,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Welcome to Pulsecare',
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Choose how you want to continue',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),

                          // Role Selection Cards
                          RoleCard(
                            title: 'I am a Patient',
                            description: 'Find doctors and book consultations',
                            icon: Icons.person_outline,
                            color: AppColors.primary,
                            isSelected: _selectedRole == UserRole.patient,
                            onTap: () {
                              setState(() {
                                _selectedRole = UserRole.patient;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          RoleCard(
                            title: 'I am a Doctor',
                            description:
                                'Provide consultations and manage appointments',
                            icon: Icons.medical_services_outlined,
                            color: AppColors.accent,
                            isSelected: _selectedRole == UserRole.doctor,
                            onTap: () {
                              setState(() {
                                _selectedRole = UserRole.doctor;
                              });
                            },
                          ),

                          const Spacer(),

                          // Continue Button
                          ElevatedButton(
                            onPressed: _selectedRole != null
                                ? () {
                                    // Navigate to Login/Signup based on role
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            LoginScreen(role: _selectedRole!),
                                      ),
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedRole == UserRole.doctor
                                  ? AppColors.accent
                                  : AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
