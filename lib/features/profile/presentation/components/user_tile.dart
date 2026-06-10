import 'package:e_sera/features/profile/domain/entities/profile_user.dart';
import 'package:e_sera/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:e_sera/features/message/presentation/pages/thread_page.dart';
import 'package:e_sera/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserTile extends StatelessWidget {
  final ProfileUser user;
  const UserTile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthCubit>().currentUser;
    final canMessage = currentUser != null && currentUser.uid != user.uid;

    return ListTile(
      title: Text(user.name),
      subtitle: Text(user.email),
      subtitleTextStyle: TextStyle(
        color: Theme.of(context).colorScheme.primary,
      ),
      leading: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canMessage)
            IconButton(
              tooltip: "Message",
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ThreadPage(
                    currentUserId: currentUser.uid,
                    otherUserId: user.uid,
                    otherUserName: user.name,
                  ),
                ),
              ),
              icon: Icon(
                Icons.chat_bubble_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          Icon(
            Icons.arrow_forward,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage(uid: user.uid)),
      ),
    );
  }
}
