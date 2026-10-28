import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _favoriteController = TextEditingController();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _controllersInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controllersInitialized) return;
    final provider = context.read<UserProvider>();
    _nameController = TextEditingController(text: provider.user.name);
    _emailController = TextEditingController(text: provider.user.email);
    _controllersInitialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _favoriteController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<UserProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    // [Latihan 5] validasi keamanan sebelum menyimpan
    final error = await provider.validateProfile(name, email);
    if (error != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    await provider.updateUser(
      provider.user.copyWith(name: name, email: email, isLoggedIn: true),
    );
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Profil berhasil disimpan'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _logout() {
    final screenContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              screenContext.read<UserProvider>().logout();
              Navigator.pop(screenContext);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // [Latihan 3] tambah favorit
  Future<void> _addFavorite() async {
    final provider = context.read<UserProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final item = _favoriteController.text.trim();
    if (item.isEmpty) return;

    final exists =
        provider.favorites.any((f) => f.toLowerCase() == item.toLowerCase());
    if (exists) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Item sudah ada di daftar favorit')),
      );
      return;
    }

    await provider.addFavorite(item);
    if (!mounted) return;
    _favoriteController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (provider.user.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.deepPurple,
                        child: Icon(Icons.person, size: 60, color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      CustomTextField(
                        controller: _nameController,
                        label: 'Nama',
                        prefixIcon: Icons.person,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email',
                        prefixIcon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save),
                        label: const Text('Simpan Profil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),

                      // [Latihan 3] daftar favorit
                      const SizedBox(height: 24),
                      const Text(
                        'Daftar Favorit (Hobi)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _favoriteController,
                              decoration: const InputDecoration(
                                hintText: 'Tambah hobi baru',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onSubmitted: (_) => _addFavorite(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _addFavorite,
                            icon: const Icon(Icons.add),
                            tooltip: 'Tambah',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (provider.favorites.isEmpty)
                        const Text(
                          'Belum ada favorit',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        ...provider.favorites.map(
                          (item) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading:
                                const Icon(Icons.favorite, color: Colors.pink),
                            title: Text(item),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Hapus',
                              onPressed: () => provider.removeFavorite(item),
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),
                      Card(
                        color: Colors.amber[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info, color: Colors.amber[800]),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Catatan Keamanan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Data disimpan di SharedPreferences '
                                '(plaintext). Jangan simpan password atau data '
                                'sensitif di sini. Gunakan secure storage '
                                'untuk data sensitif.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
