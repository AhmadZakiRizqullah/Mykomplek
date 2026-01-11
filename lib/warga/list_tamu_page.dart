import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../utils/session.dart';
import '../auth/login_page.dart';
import '../services/api_service.dart';
import '../config/constants.dart';
import '../utils/date_helper.dart';
import '../config/theme.dart';

class ListTamuPage extends StatefulWidget {
  const ListTamuPage({Key? key}) : super(key: key);

  @override
  State<ListTamuPage> createState() => _ListTamuPageState();
}

class _ListTamuPageState extends State<ListTamuPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<dynamic> _tamuList = [];
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadTamuList();
  }

  Future<void> _loadTamuList() async {
    if (mounted) setState(() => _isLoading = true);

    final dateStr = DateHelper.formatDateForApi(_selectedDate);

    final response = await ApiService.get(
      AppConstants.listTamuEndpoint,
      needsAuth: true,
      queryParams: {
        'date': dateStr,
        'status': _selectedStatus,
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
      },
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (response['status'] == 200) {
        _tamuList = response['data'] ?? [];
      } else {
        _tamuList = [];
      }
    });
  }

  Future<void> _logout() async {
    await Session.clearSession();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Widget _buildSecureImage(String fileName) {
    return FutureBuilder<Uint8List?>(
      future: _loadSecureImage(fileName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.error_outline_rounded,
                size: 50,
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            snapshot.data!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  Future<Uint8List?> _loadSecureImage(String fileName) async {
    try {
      final token = await Session.getToken();

      final url =
          '${AppConstants.secureFileEndpoint}?type=wajah&file=$fileName';

      final headers = <String, String>{
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception(
          'Failed to load image: ${response.statusCode} | ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading secure image: $e');
      return null;
    }
  }

  void _showTamuDetail(Map<String, dynamic> tamu) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tamu['nama_tamu'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Tujuan', tamu['tujuan']),
              _buildDetailRow('Alamat', tamu['alamat_tujuan']),
              _buildDetailRow(
                'Check In',
                DateHelper.formatDateTime(
                  DateTime.parse(tamu['check_in']),
                ),
              ),
              if (tamu['check_out'] != null)
                _buildDetailRow(
                  'Check Out',
                  DateHelper.formatDateTime(
                    DateTime.parse(tamu['check_out']),
                  ),
                ),
              _buildDetailRow('Status', tamu['status'].toUpperCase()),
              _buildDetailRow('Petugas', tamu['petugas_nama']),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppDecorations.primaryGradient,
        child: SafeArea(
          child: Column(
            children: [
              // Modern Header
              Container(
                padding: EdgeInsets.fromLTRB(
                  MediaQuery.of(context).size.width < 360 ? 16 : 20,
                  16,
                  MediaQuery.of(context).size.width < 360 ? 16 : 20,
                  20,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width < 360 ? 10 : 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo-baru.png',
                          height:
                              MediaQuery.of(context).size.width < 360 ? 36 : 40,
                          width:
                              MediaQuery.of(context).size.width < 360 ? 36 : 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daftar Tamu',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 360
                                  ? 18
                                  : 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Lihat riwayat tamu komplek',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 360
                                  ? 12
                                  : 13,
                              color: AppColors.textLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded),
                      color: AppColors.textLight,
                      onPressed: _logout,
                      tooltip: 'Logout',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Filter Section
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width < 360 ? 16 : 20,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      icon: const Icon(Icons.search_rounded),
                      hintText: 'Cari nama, tujuan, atau alamat',
                      border: InputBorder.none,
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchController.clear();
                                _searchQuery = '';
                                _loadTamuList();
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      _searchQuery = value;
                      _loadTamuList();
                    },
                  ),
                ),
              ),
              SizedBox(
                  height: MediaQuery.of(context).size.width < 360 ? 12 : 16),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadTamuList,
                          color: AppColors.primary,
                          child: _tamuList.isEmpty
                              ? ListView(
                                  children: [
                                    const SizedBox(height: 100),
                                    Center(
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(24),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceMuted,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.inbox_rounded,
                                              size: 64,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          const Text(
                                            'Tidak ada data tamu',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Tamu akan muncul di sini setelah diinput',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.all(
                                    MediaQuery.of(context).size.width < 360
                                        ? 16
                                        : 20,
                                  ),
                                  itemCount: _tamuList.length,
                                  itemBuilder: (context, index) {
                                    final tamu = _tamuList[index];
                                    final isCheckedOut =
                                        tamu['status'] == 'keluar';
                                    final screenWidth =
                                        MediaQuery.of(context).size.width;
                                    final isSmallScreen = screenWidth < 360;

                                    return Container(
                                      margin: EdgeInsets.only(
                                        bottom: isSmallScreen ? 12 : 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.06),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => _showTamuDetail(tamu),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Padding(
                                            padding: EdgeInsets.all(
                                              isSmallScreen ? 12 : 16,
                                            ),
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius:
                                                      isSmallScreen ? 24 : 28,
                                                  backgroundColor: isCheckedOut
                                                      ? AppColors.textSecondary
                                                      : AppColors.success,
                                                  child: Text(
                                                    tamu['nama_tamu'][0]
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: isSmallScreen
                                                          ? 20
                                                          : 22,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                    width: isSmallScreen
                                                        ? 10
                                                        : 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        tamu['nama_tamu'],
                                                        style: TextStyle(
                                                          fontSize:
                                                              isSmallScreen
                                                                  ? 14
                                                                  : 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: AppColors
                                                              .textPrimary,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .location_on_rounded,
                                                            size: isSmallScreen
                                                                ? 12
                                                                : 14,
                                                            color: AppColors
                                                                .textSecondary,
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Expanded(
                                                            child: Text(
                                                              tamu['tujuan'],
                                                              style: TextStyle(
                                                                fontSize:
                                                                    isSmallScreen
                                                                        ? 12
                                                                        : 13,
                                                                color: AppColors
                                                                    .textSecondary,
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        tamu['alamat_tujuan'],
                                                        style: TextStyle(
                                                          fontSize:
                                                              isSmallScreen
                                                                  ? 11
                                                                  : 12,
                                                          color: AppColors
                                                              .textSecondary,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .schedule_rounded,
                                                            size: isSmallScreen
                                                                ? 11
                                                                : 12,
                                                            color: AppColors
                                                                .textSecondary,
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            DateHelper
                                                                .formatTime(
                                                              DateTime.parse(
                                                                tamu[
                                                                    'check_in'],
                                                              ),
                                                            ),
                                                            style: TextStyle(
                                                              fontSize:
                                                                  isSmallScreen
                                                                      ? 11
                                                                      : 12,
                                                              color: AppColors
                                                                  .textSecondary,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal:
                                                        isSmallScreen ? 8 : 10,
                                                    vertical:
                                                        isSmallScreen ? 5 : 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: isCheckedOut
                                                        ? AppColors.surfaceMuted
                                                        : AppColors.success
                                                            .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  child: Text(
                                                    isCheckedOut
                                                        ? 'KELUAR'
                                                        : 'MASUK',
                                                    style: TextStyle(
                                                      color: isCheckedOut
                                                          ? AppColors
                                                              .textSecondary
                                                          : AppColors.success,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: isSmallScreen
                                                          ? 10
                                                          : 11,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                    width:
                                                        isSmallScreen ? 6 : 8),
                                                Icon(
                                                  Icons.chevron_right_rounded,
                                                  color:
                                                      AppColors.textSecondary,
                                                  size: isSmallScreen ? 20 : 24,
                                                ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}