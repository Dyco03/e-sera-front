import 'package:e_sera/core/config/app_config.dart';
import 'package:e_sera/core/config/repo_factory.dart';
import 'package:e_sera/features/auth/presentation/pages/noInternet_page.dart';
import 'package:e_sera/features/home/presentation/pages/home_page.dart';
import 'package:e_sera/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:e_sera/features/auth/presentation/cubits/auth_states.dart';
import 'package:e_sera/features/auth/presentation/pages/auth_page.dart';
import 'package:e_sera/features/message/presentation/cubits/message_cubit.dart';
import 'package:e_sera/features/post/presentation/cubits/post_cubit.dart';
import 'package:e_sera/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:e_sera/features/search/presentation/cubits/search_cubit.dart';
import 'package:e_sera/themes/light_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/*
App - Root Level

Repositories: for the database
  -firebase

Bloc Providers: for state management
  -auth
  -profile
  -post
  -search
  -theme

Check Auth State
  -unauthenticated -> auth page (login/register)
  -authenticated -> home page

*/

class MyApp extends StatelessWidget {
  // backend type
  final backend = AppConfig.backend;

  // storage repo
  // final supabaseStorageRepo = SupabaseStorageRepo();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // provide cubits to the app
    return MultiBlocProvider(
      providers: [
        // auth cubit
        BlocProvider<AuthCubit>(
          create: (context) =>
              AuthCubit(authRepo: RepoFactory.authRepo())..checkAuth(),
        ),

        // profile cubit
        BlocProvider<ProfileCubit>(
          create: (context) => ProfileCubit(
            profileRepo: RepoFactory.profileRepo(),
            storageRepo: RepoFactory.storageRepo(),
          ),
        ),

        // post cubit
        BlocProvider<PostCubit>(
          create: (context) => PostCubit(
            postRepo: RepoFactory.postRepo(),
            storageRepo: RepoFactory.storageRepo(),
          ),
        ),

        // search cubit
        BlocProvider<SearchCubit>(
          create: (context) =>
              SearchCubit(searchRepo: RepoFactory.searchRepo()),
        ),

        // message cubit
        BlocProvider<MessageCubit>(
          create: (context) =>
              MessageCubit(messageRepo: RepoFactory.messageRepo()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: lightMode,
        home: BlocConsumer<AuthCubit, AuthState>(
          builder: (context, authState) {
            print(authState);
            // authState is a variable; the type remains AuthState
            if (authState is NoInternet) {
              return NoInternetPage();
            }
            // -unauthenticated -> auth page (login/register)
            if (authState is Unauthenticated) {
              return const AuthPage();
            }

            // -authenticated -> home page
            if (authState is Authenticated) {
              return const HomePage();
            }
            // loading
            else {
              print('FFFFFFFFFFFFFFFFFFFFFFFFFFF');
              print(authState);
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()), // loading
              );
            }
          },

          // listen for errors
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
        ),
      ),
    );
  }
}
