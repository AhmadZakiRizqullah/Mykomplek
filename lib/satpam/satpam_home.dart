import 'package:flutter/material.dart';
import '../utils/session.dart';
import '../auth/login_page.dart';
import '../services/api_service.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import 'input_tamu_page.dart';
import 'package:intl/intl.dart';
import '../utils/date_helper.dart';

class SatpamHome extends StatefulWidget {
  const SatpamHome({Key? key}) : super(key: key);

  @override
  State<SatpamHome> createState() => _SatpamHomeState();
}

class _SatpamHomeState extends State<SatpamHome> {
  List<dynamic> _tamuToday = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTamuToday();
  }

  Future<void> _loadTamuToday({String search = ''}) async {
    setState(() => _isLoading = true);

    // Kembali ke endpoint asli untuk satpam
    final response = await ApiService.get(
      AppConstants.getTamuTodayEndpoint,
      needsAuth: true,
      queryParams: {
        // Kirim parameter date, jika backend tidak mendukung akan diabaikan
        'date': DateHelper.formatDateForApi(_selectedDate),
        if (search.isNotEmpty) 'search': search,
      },
    );

    setState(() => _isLoading = false);

    if (response['status'] == 200) {
      final allTamu = response['data'] ?? [];

      // Filter di client side:
      // 1. Hanya tamu yang belum check out (status != 'keluar')
      // 2. Yang check_in pada tanggal yang dipilih
      final selectedDateOnly = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );

      setState(() {
        _tamuToday = allTamu.where((tamu) {
          // Filter status
          if (tamu['status'] == 'keluar') return false;

          // Filter berdasarkan tanggal check_in
          try {
            final checkInStr = tamu['check_in'];
            if (checkInStr == null || checkInStr.toString().isEmpty) return false;

            final checkInDate = DateTime.parse(checkInStr);
            final checkInDateOnly = DateTime(
              checkInDate.year,
              checkInDate.month,
              checkInDate.day,
            );

            return checkInDateOnly.isAtSameMomentAs(selectedDateOnly);
          } catch (e) {
            // Jika parsing error, skip tamu ini
            return false;
          }
        }).toList();
      });
    } else {
      setState(() => _tamuToday = []);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('id', 'ID'),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadTamuToday(search: _searchQuery);
    }
  }

  Future<void> _checkoutTamu(int tamuId, String namaTamu) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Konfirmasi Checkout',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text('Checkout tamu "$namaTamu"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Checkout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final response = await ApiService.post(
      AppConstants.checkoutTamuEndpoint,
      {'tamu_id': tamuId},
      needsAuth: true,
    );

    if (response['status'] == 200) {
      _loadTamuToday(search: _searchQuery);
      if (mounted) {
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
      }
    } else {
      if (mounted) {
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
  }

  Future<void> _logout() async {
    await Session.clearSession();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
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
                            'Satpam Dashboard',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 360
                                  ? 18
                                  : 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          InkWell(
                            onTap: _selectDate,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: MediaQuery.of(context).size.width < 360
                                        ? 12
                                        : 13,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                                          .format(_selectedDate),
                                      style: TextStyle(
                                        fontSize: MediaQuery.of(context).size.width < 360
                                            ? 12
                                            : 13,
                                        color: Colors.white.withOpacity(0.85),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_drop_down_rounded,
                                    size: MediaQuery.of(context).size.width < 360
                                        ? 14
                                        : 16,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                ],
                              ),
                            ),
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
              // Stats Card
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width < 360 ? 16 : 20,
                ),
                child: Container(
                  padding: EdgeInsets.all(
                    MediaQuery.of(context).size.width < 360 ? 16 : 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(
                          MediaQuery.of(context).size.width < 360 ? 10 : 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.people_rounded,
                          color: AppColors.textLight,
                          size:
                          MediaQuery.of(context).size.width < 360 ? 24 : 28,
                        ),
                      ),
                      SizedBox(
                          width: MediaQuery.of(context).size.width < 360
                              ? 12
                              : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedDate.year == DateTime.now().year &&
                                  _selectedDate.month == DateTime.now().month &&
                                  _selectedDate.day == DateTime.now().day
                                  ? 'Total Tamu Hari Ini'
                                  : 'Tamu Belum Check Out',
                              style: TextStyle(
                                fontSize:
                                MediaQuery.of(context).size.width < 360
                                    ? 12
                                    : 13,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_tamuToday.length}',
                              style: TextStyle(
                                fontSize:
                                MediaQuery.of(context).size.width < 360
                                    ? 24
                                    : 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                  height: MediaQuery.of(context).size.width < 360 ? 16 : 20),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  MediaQuery.of(context).size.width < 360 ? 16 : 20,
                  16,
                  MediaQuery.of(context).size.width < 360 ? 16 : 20,
                  8,
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
                    decoration: InputDecoration(
                      icon: const Icon(Icons.search_rounded),
                      hintText: 'Cari nama / tujuan / alamat',
                      border: InputBorder.none,
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _searchQuery = '';
                          _loadTamuToday();
                        },
                      )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      _loadTamuToday(search: value);
                    },
                  ),
                ),
              ),

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
                    onRefresh: () => _loadTamuToday(search: _searchQuery),
                    color: AppColors.primary,
                    child: _tamuToday.isEmpty
                        ? ListView(
                      children: [
                        SizedBox(
                            height:
                            MediaQuery.of(context).size.height *
                                0.15),
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(
                                  MediaQuery.of(context)
                                      .size
                                      .width <
                                      360
                                      ? 20
                                      : 24,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.inbox_rounded,
                                  size: MediaQuery.of(context)
                                      .size
                                      .width <
                                      360
                                      ? 56
                                      : 64,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _selectedDate.year == DateTime.now().year &&
                                    _selectedDate.month == DateTime.now().month &&
                                    _selectedDate.day == DateTime.now().day
                                    ? 'Belum ada tamu hari ini'
                                    : 'Belum ada tamu yang belum check out',
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context)
                                      .size
                                      .width <
                                      360
                                      ? 14
                                      : 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedDate.year == DateTime.now().year &&
                                    _selectedDate.month == DateTime.now().month &&
                                    _selectedDate.day == DateTime.now().day
                                    ? 'Tamu yang masuk akan muncul di sini'
                                    : 'Pada tanggal ${DateHelper.formatDate(_selectedDate)}',
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context)
                                      .size
                                      .width <
                                      360
                                      ? 12
                                      : 13,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
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
                      itemCount: _tamuToday.length,
                      itemBuilder: (context, index) {
                        final tamu = _tamuToday[index];
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
                          child: Padding(
                            padding: EdgeInsets.all(
                              isSmallScreen ? 12 : 16,
                            ),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius:
                                      isSmallScreen ? 24 : 28,
                                      backgroundColor: isCheckedOut
                                          ? AppColors.textSecondary
                                          : AppColors.primary,
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
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          Text(
                                            'Check In',
                                            style: TextStyle(
                                              fontSize:
                                              isSmallScreen
                                                  ? 10
                                                  : 11,
                                              color: AppColors
                                                  .textSecondary,
                                              fontWeight:
                                              FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons
                                                    .schedule_rounded,
                                                size: isSmallScreen
                                                    ? 12
                                                    : 14,
                                                color: AppColors
                                                    .textSecondary,
                                              ),
                                              const SizedBox(
                                                  width: 4),
                                              Text(
                                                DateFormat('HH:mm')
                                                    .format(
                                                  DateTime.parse(
                                                    tamu[
                                                    'check_in'],
                                                  ),
                                                ),
                                                style: TextStyle(
                                                  fontSize:
                                                  isSmallScreen
                                                      ? 13
                                                      : 14,
                                                  fontWeight:
                                                  FontWeight
                                                      .w600,
                                                  color: AppColors
                                                      .textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isCheckedOut)
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                          children: [
                                            Text(
                                              'Check Out',
                                              style: TextStyle(
                                                fontSize:
                                                isSmallScreen
                                                    ? 10
                                                    : 11,
                                                color: AppColors
                                                    .textSecondary,
                                                fontWeight:
                                                FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(
                                                height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons
                                                      .schedule_rounded,
                                                  size:
                                                  isSmallScreen
                                                      ? 12
                                                      : 14,
                                                  color: AppColors
                                                      .textSecondary,
                                                ),
                                                const SizedBox(
                                                    width: 4),
                                                Text(
                                                  DateFormat(
                                                      'HH:mm')
                                                      .format(
                                                    DateTime.parse(
                                                      tamu[
                                                      'check_out'],
                                                    ),
                                                  ),
                                                  style: TextStyle(
                                                    fontSize:
                                                    isSmallScreen
                                                        ? 13
                                                        : 14,
                                                    fontWeight:
                                                    FontWeight
                                                        .w600,
                                                    color: AppColors
                                                        .textPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (!isCheckedOut)
                                      Flexible(
                                        child: ElevatedButton.icon(
                                          onPressed: () =>
                                              _checkoutTamu(
                                                tamu['id'],
                                                tamu['nama_tamu'],
                                              ),
                                          icon: Icon(
                                            Icons.logout_rounded,
                                            size: isSmallScreen
                                                ? 14
                                                : 16,
                                          ),
                                          label: Text(
                                            isSmallScreen
                                                ? 'Out'
                                                : 'Checkout',
                                            style: TextStyle(
                                              fontSize:
                                              isSmallScreen
                                                  ? 12
                                                  : 14,
                                            ),
                                          ),
                                          style: ElevatedButton
                                              .styleFrom(
                                            backgroundColor:
                                            AppColors.warning,
                                            foregroundColor:
                                            Colors.white,
                                            padding: EdgeInsets
                                                .symmetric(
                                              horizontal:
                                              isSmallScreen
                                                  ? 12
                                                  : 16,
                                              vertical:
                                              isSmallScreen
                                                  ? 8
                                                  : 10,
                                            ),
                                            shape:
                                            RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius
                                                  .circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InputTamuPage()),
          );
          _loadTamuToday(search: _searchQuery);
        },
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Input Tamu'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}