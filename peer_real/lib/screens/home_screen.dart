import 'package:flutter/material.dart';
import '../services/ditto_service.dart';
import '../services/permission_service.dart';
import '../widgets/file_list_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DittoService _dittoService = DittoService();
  List<Map<String, dynamic>> _files = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await PermissionService.requestP2PPermissions();
    await _dittoService.init(() {
      setState(() => _files = _dittoService.getFiles());
    });

    setState(() => _files = _dittoService.getFiles());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PeerReal"),
        backgroundColor: const Color.fromRGBO(61, 61, 129, 1),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _dittoService.addSampleImage,
        child: const Icon(Icons.cloud_upload),
      ),
      body: ListView.builder(
        itemCount: _files.length,
        itemBuilder: (context, i) =>
            FileListTile(doc: _files[i], dittoService: _dittoService),
      ),
    );
  }

  @override
  void dispose() {
    _dittoService.dispose();
    super.dispose();
  }
}
