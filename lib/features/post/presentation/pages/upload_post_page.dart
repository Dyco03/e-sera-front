import 'dart:io';
import 'dart:typed_data';
import 'package:e_sera/features/auth/domain/entities/app_user.dart';
import 'package:e_sera/features/auth/presentation/components/my_text_filed.dart';
import 'package:e_sera/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:e_sera/features/post/domain/entitites/post.dart';
import 'package:e_sera/features/post/presentation/cubits/post_cubit.dart';
import 'package:e_sera/features/post/presentation/cubits/post_states.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; // check whether the app is running on the web
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UploadPostPage extends StatefulWidget {
  const UploadPostPage({super.key});

  @override
  State<UploadPostPage> createState() => _UploadPostPageState();
}

class _UploadPostPageState extends State<UploadPostPage> {
  // mobile image pick
  PlatformFile? imagePickedFile;

  // web image pick
  Uint8List? webImage;

  // text controller -> caption
  final textController = TextEditingController();

  // current user
  AppUser? currentUser;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    getCurrentUser();
  }

  // get current user
  void getCurrentUser() async {
    final authCubit = context.read<AuthCubit>();
    currentUser = authCubit.currentUser;
  }

  // pick image
  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: kIsWeb,
    );

    if (result != null) {
      setState(() {
        imagePickedFile = result.files.first;

        if (kIsWeb) {
          webImage = imagePickedFile!.bytes;
        }
      });
    }
  }

  // create & upload post
  void uploadPost() {
    final caption = textController.text.trim();
    final hasImage = imagePickedFile != null;

    // a post can be image-only or caption-only, but not empty
    if (!hasImage && caption.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Add a photo or a caption")));
      return;
    }

    // create a new post object
    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentUser!.uid,
      userName: currentUser!.name,
      text: caption,
      imageUrl: '',
      timestamp: DateTime.now(),
      likes: [],
      comments: [],
    );

    // post cubit
    final postCubit = context.read<PostCubit>();

    // web upload
    if (kIsWeb) {
      postCubit.createPost(newPost, imageBytes: imagePickedFile?.bytes);
    }
    // mobile upload
    else {
      postCubit.createPost(newPost, imagePath: imagePickedFile?.path);
    }
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // BLOC CONSUMER -> builder + listener
    return BlocConsumer<PostCubit, PostStates>(
      builder: (context, state) {
        // loading or uploading
        if (state is PostsLoading || state is PostUploading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // build upload page
        return buildUploadPage();
      },
      // go to previous page when upload is done & posts are loaded
      listener: (context, state) {
        if (state is PostsLoaded) {
          Navigator.pop(context);
        }
      },
    );
  }

  Widget buildUploadPage() {
    // scaffold
    return Scaffold(
      // app bar
      appBar: AppBar(
        title: const Text("Create Post"),
        foregroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          // upload button
          IconButton(onPressed: uploadPost, icon: const Icon(Icons.upload)),
        ],
      ),

      // body
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              // image preview for web
              if (kIsWeb && webImage != null) Image.memory(webImage!),

              // image preview for mobile
              if (!kIsWeb && imagePickedFile != null)
                Image.file(File(imagePickedFile!.path!)),

              // pick image button
              MaterialButton(
                onPressed: pickImage,
                color: Colors.blue,
                child: const Text("Pick Image"),
              ),

              // caption text box
              MyTextFiled(
                controller: textController,
                hintText: "Caption",
                obscureText: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
