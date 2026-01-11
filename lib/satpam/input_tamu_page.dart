// lib/satpam/input_tamu_page.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../services/api_service.dart';
import '../config/constants.dart';
import '../config/theme.dart';

class InputTamuPage extends StatefulWidget {
  const InputTamuPage({Key? key}) : super(key: key);

  @override
  State<InputTamuPage> createState() => _InputTamuPageState();
}

class _InputTamuPageState extends State<InputTamuPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaTamuController = TextEditingController();
  final _nikController = TextEditingController();
  final _tujuanController = TextEditingController();
  final _alamatTujuanController = TextEditingController();

  File? _fotoKtp;
  File? _fotoWajah;
  Uint8List? _fotoKtpBytes;
  Uint8List? _fotoWajahBytes;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _namaTamuController.dispose();
    _nikController.dispose();
    _tujuanController.dispose();
    _alamatTujuanController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isKtp) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        if (isKtp) {
          _fotoKtp = File(image.path);
          _fotoKtpBytes = bytes;
        } else {
          _fotoWajah = File(image.path);
          _fotoWajahBytes = bytes;
        }
      });
    }
  }

  Future<void> _pickImageFromGallery(bool isKtp) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        if (isKtp) {
          _fotoKtp = File(image.path);
          _fotoKtpBytes = bytes;
        } else {
          _fotoWajah = File(image.path);
          _fotoWajahBytes = bytes;
        }
      });
    }
  }

  void _showImageSourceDialog(bool isKtp) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isKtp ? 'Foto KTP' : 'Foto Wajah',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(isKtp);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery(isKtp);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitTamu() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fotoKtpBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Foto KTP harus diupload'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (_fotoWajahBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Foto Wajah harus diupload'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await ApiService.uploadMultipart(
      AppConstants.addTamuEndpoint,
      {
        'nama_tamu': _namaTamuController.text.trim(),
        'nik': _nikController.text.trim(),
        'tujuan': _tujuanController.text.trim(),
        'alamat_tujuan': _alamatTujuanController.text.trim(),
      },
      kIsWeb
          ? {
              'foto_ktp': _fotoKtpBytes!,
              'foto_wajah': _fotoWajahBytes!,
            }
          : {
              'foto_ktp': _fotoKtp!,
              'foto_wajah': _fotoWajah!,
            },
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response['status'] == 201) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Data Tamu'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(
            MediaQuery.of(context).size.width < 360 ? 16 : 20,
          ),
          children: [
            // Header Section
            Container(
              padding: EdgeInsets.all(
                MediaQuery.of(context).size.width < 360 ? 16 : 20,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(
                      MediaQuery.of(context).size.width < 360 ? 10 : 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_add_rounded,
                      color: Colors.white,
                      size: MediaQuery.of(context).size.width < 360 ? 20 : 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Form Input Tamu',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width < 360 ? 16 : 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lengkapi data tamu di bawah',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width < 360 ? 12 : 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.width < 360 ? 20 : 24),
            // Form Fields
            CustomTextField(
              controller: _namaTamuController,
              label: 'Nama Tamu',
              hint: 'Masukkan nama lengkap',
              prefixIcon: Icons.person_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama tamu harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _nikController,
              label: 'NIK',
              hint: 'Nomor Induk Kependudukan',
              prefixIcon: Icons.badge_rounded,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'NIK harus diisi';
                }
                if (value.length != 16) {
                  return 'NIK harus 16 digit';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _tujuanController,
              label: 'Tujuan Kunjungan',
              hint: 'Contoh: Menginap, Bertamu',
              prefixIcon: Icons.location_on_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Tujuan harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _alamatTujuanController,
              label: 'Alamat Tujuan',
              hint: 'Contoh: Blok A No. 12',
              prefixIcon: Icons.home_rounded,
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Alamat tujuan harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            // Foto KTP Section
            Row(
              children: [
                Icon(
                  Icons.credit_card_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Foto KTP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_fotoKtpBytes != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Terupload',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showImageSourceDialog(true),
              child: Container(
                height: MediaQuery.of(context).size.width < 360 ? 180 : 200,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _fotoKtpBytes != null
                        ? AppColors.success
                        : AppColors.textSecondary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: _fotoKtpBytes == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap untuk ambil foto KTP',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: kIsWeb
                            ? Image.memory(
                                _fotoKtpBytes!,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                _fotoKtp!,
                                fit: BoxFit.cover,
                              ),
                      ),
              ),
            ),
            if (_fotoKtpBytes != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'NIK akan otomatis di-mask untuk privasi',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Foto Wajah Section
            Row(
              children: [
                Icon(
                  Icons.face_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Foto Wajah Tamu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_fotoWajahBytes != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Terupload',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showImageSourceDialog(false),
              child: Container(
                height: MediaQuery.of(context).size.width < 360 ? 180 : 200,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _fotoWajahBytes != null
                        ? AppColors.success
                        : AppColors.textSecondary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: _fotoWajahBytes == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.face_rounded,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap untuk ambil foto wajah',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: kIsWeb
                            ? Image.memory(
                                _fotoWajahBytes!,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                _fotoWajah!,
                                fit: BoxFit.cover,
                              ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Simpan Data Tamu',
              onPressed: _submitTamu,
              isLoading: _isLoading,
              icon: Icons.save_rounded,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
