import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:laundry/models/country_model.dart';
import 'package:laundry/models/incomeandexpensemodel.dart';
import 'package:laundry/providers/country_provider.dart';
import 'package:laundry/providers/nav_provider.dart';
import 'package:laundry/screens/homescreen_widgets/home_header.dart';
import 'package:laundry/services/api_service.dart';
import 'package:laundry/utilities/colors.dart';
import 'package:laundry/utilities/gapfunc.dart';

class IncomeExpense extends ConsumerStatefulWidget {
  const IncomeExpense({super.key});

  @override
  ConsumerState<IncomeExpense> createState() => _IncomeExpenseState();
}

class _IncomeExpenseState extends ConsumerState<IncomeExpense> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  IncomeandExpenseModel? _data;
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 14));
  DateTime _toDate = DateTime.now();
  String _paymentMode = "All";
  final TextEditingController _searchController = TextEditingController();
  List<Report> _filteredReports = [];

  final List<String> _paymentModes = ["All", "Cash", "Online", "Card", "Other"];

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterReports();
  }

  void _filterReports() {
    if (_data == null) return;
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredReports = _data!.report.where((item) {
        return item.description.toLowerCase().contains(query) ||
            item.narration.toLowerCase().contains(query) ||
            item.trnNo.toString().contains(query) ||
            item.enteredBy.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final startDate = DateFormat('yyyy-MM-dd').format(_fromDate);
      final endDate = DateFormat('yyyy-MM-dd').format(_toDate);

      final result = await _apiService.getIncomeandExpense(
        startDate: startDate,
        endDate: endDate,
        paymentMode: _paymentMode,
      );

      setState(() {
        _data = result;
        _filterReports();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: redColor),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor, // Header background color
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: primaryColor),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final countryCodeAsync = ref.watch(countryCodeProvider);
    final countryCode = countryCodeAsync.value;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  HomeHeader(
                    showBack: true,
                    onBack: () {
                      ref.read(navProvider.notifier).state = NavIndex.dashboard;
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    decoration: const BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateSelector(
                                "From",
                                _fromDate,
                                () => _selectDate(context, true),
                              ),
                            ),
                            horiGap(12),
                            Expanded(
                              child: _buildDateSelector(
                                "To",
                                _toDate,
                                () => _selectDate(context, false),
                              ),
                            ),
                          ],
                        ),
                        vertGap(08),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _paymentMode,
                              dropdownColor: primaryColor,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.white,
                              ),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              items: _paymentModes.map((String mode) {
                                return DropdownMenuItem<String>(
                                  value: mode,
                                  child: Text(mode),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _paymentMode = newValue;
                                  });
                                  _fetchData();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_data != null) ...[
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, 05), // Overlap effect
                  child: _buildSummaryCards(countryCode),
                ),
              ),
              SliverToBoxAdapter(child: _buildSearchBar()),
              _buildTransactionListSliver(countryCode),
            ] else
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      vertGap(16),
                      Text(
                        "No data available",
                        style: GoogleFonts.poppins(
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(String label, DateTime date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
                vertGap(2),
                Text(
                  DateFormat('dd MMM yy').format(date),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(CountryCodeModel? countryCode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.15),
            blurRadius: 25,
            // offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              "Income",
              _data!.totalIncome,
              Colors.green,
              Icons.arrow_upward_rounded,
              countryCode,
            ),
          ),
          Container(height: 40, width: 1, color: Colors.grey[100]),
          Expanded(
            child: _buildSummaryItem(
              "Expense",
              _data!.totalExpense,
              Colors.redAccent,
              Icons.arrow_downward_rounded,
              countryCode,
            ),
          ),
          Container(height: 40, width: 1, color: Colors.grey[100]),
          Expanded(
            child: _buildSummaryItem(
              "Balance",
              _data!.closingBalance,
              _data!.closingBalance >= 0
                  ? const Color(0xFF0D47A1)
                  : Colors.orange,
              Icons.account_balance_wallet_rounded,
              countryCode,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    double amount,
    Color color,
    IconData icon,
    CountryCodeModel? countryCode,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        vertGap(8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        vertGap(4),
        Text(
          "${amount.abs().toStringAsFixed(0)} ${countryCode?.currencyCode ?? ''}",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: "Search transactions...",
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.grey[400],
              size: 22,
            ),
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            isDense: true,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionListSliver(CountryCodeModel? countryCode) {
    if (_filteredReports.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize:
                MainAxisSize.min, // Ensure it doesn't expand unnecessarily
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
              vertGap(10),
              Text(
                "No transactions found",
                style: GoogleFonts.poppins(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = _filteredReports[index];
          final isIncome = item.income > 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isIncome
                                      ? Colors.green.withValues(alpha: 0.08)
                                      : Colors.red.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isIncome
                                      ? Icons.arrow_downward_rounded
                                      : Icons.arrow_upward_rounded,
                                  color: isIncome ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                              ),
                              horiGap(12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.description.isNotEmpty
                                          ? item.description
                                          : "No Description",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: const Color(0xFF1E293B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    vertGap(2),
                                    Text(
                                      DateFormat(
                                        'MMM dd, hh:mm a',
                                      ).format(item.entryDate),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        horiGap(8),
                        Text(
                          isIncome
                              ? "+${item.income.toStringAsFixed(0)} ${countryCode?.currencyCode ?? ''}"
                              : "-${item.expense.toStringAsFixed(0)} ${countryCode?.currencyCode ?? ''}",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: isIncome ? Colors.green : Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    if (item.narration.isNotEmpty ||
                        item.paymentMode.isNotEmpty) ...[
                      vertGap(12),
                      Divider(height: 1, color: Colors.grey[100]),
                      vertGap(10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (item.narration.isNotEmpty)
                            Expanded(
                              child: Text(
                                item.narration,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          else
                            const Spacer(), // Keeps alignment if only payment mode exists
                          if (item.paymentMode.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.paymentMode,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFF475569),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }, childCount: _filteredReports.length),
      ),
    );
  }
}
