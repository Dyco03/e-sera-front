import 'package:e_sera/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NoInternetPage extends StatefulWidget {
  const NoInternetPage({super.key});

  @override
  State<NoInternetPage> createState() => _NoInternetPageState();
}

class _NoInternetPageState extends State<NoInternetPage> {
  late final AuthCubit authCubit;

  @override
  void initState() {
    super.initState();
    authCubit = context.read<AuthCubit>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // body
      body: SingleChildScrollView(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // logo
                  Image.asset('assets/images/logo.png'),

                  const Icon(Icons.wifi_off, size: 50),
                  const SizedBox(height: 10),
                  const Text("No internet connection"),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      context.read<AuthCubit>().checkAuth();
                    },
                    child: const Text("Retry"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
