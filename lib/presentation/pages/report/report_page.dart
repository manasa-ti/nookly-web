import 'package:flutter/material.dart';
import 'package:nookly/core/theme/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nookly/presentation/bloc/report/report_bloc.dart';
import 'package:nookly/presentation/bloc/report/report_event.dart';
import 'package:nookly/presentation/bloc/report/report_state.dart';

class ReportPage extends StatefulWidget {
  final String reportedUserId;
  final String reportedUserName;

  const ReportPage({
    Key? key,
    required this.reportedUserId,
    required this.reportedUserName,
  }) : super(key: key);

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Load report reasons when page initializes
    context.read<ReportBloc>().add(LoadReportReasons());
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _submitReport() {
    if (_formKey.currentState!.validate() && _selectedReason != null) {
      context.read<ReportBloc>().add(
        ReportUser(
          reportedUserId: widget.reportedUserId,
          reason: _selectedReason!,
          details: _detailsController.text.trim().isEmpty 
              ? null 
              : _detailsController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF1d335f),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1d335f),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Report User',
          style: TextStyle(
            color: Colors.white,
            fontSize: (size.width * 0.045).clamp(14.0, 18.0),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: BlocListener<ReportBloc, ReportState>(
        listener: (context, state) {
          if (state is ReportSubmitted) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            
            // Navigate back after successful report
            Navigator.of(context).pop();
          } else if (state is ReportError) {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        child: BlocBuilder<ReportBloc, ReportState>(
          builder: (context, state) {
            if (state is ReportLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            } else if (state is ReportError && state.message.contains('reasons')) {
              // Error loading reasons, show retry option
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load report reasons',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: (size.width * 0.045).clamp(14.0, 18.0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFD6D9E6),
                        fontSize: (size.width * 0.035).clamp(12.0, 15.0),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFf4656f),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                      onPressed: () {
                        context.read<ReportBloc>().add(LoadReportReasons());
                      },
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: (size.width * 0.035).clamp(12.0, 15.0),
                          fontWeight: FontWeight.w500,
                          color: Colors.white
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // Show form with reasons (if loaded) or loading
              return _buildReportForm(state, size);
            }
          },
        ),
      ),
    );
  }

  Widget _buildReportForm(ReportState state, Size size) {
    List<String> reasons = [];
    bool isLoading = false;
    bool isSubmitting = false;

    if (state is ReportReasonsLoaded) {
      reasons = state.reasons;
    } else if (state is ReportSubmitting) {
      reasons = state.reasons;
      isSubmitting = true;
    } else if (state is ReportLoading) {
      isLoading = true;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Report ${widget.reportedUserName}',
              style: TextStyle(
                fontSize: (size.width * 0.05).clamp(16.0, 20.0),
                fontWeight: FontWeight.w500,
                color: Colors.white
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Help us keep our community safe by reporting inappropriate behavior.',
              style: TextStyle(
                fontSize: (size.width * 0.035).clamp(12.0, 15.0),
                color: Color(0xFFD6D9E6),
              ),
            ),
            const SizedBox(height: 24),

            // Report Reason Selection
            Text(
              'Reason for Report *',
              style: TextStyle(
                fontSize: (size.width * 0.04).clamp(14.0, 16.0),
                fontWeight: FontWeight.w500,
                color: Colors.white
              ),
            ),
            const SizedBox(height: 12),
            
            if (isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.white))
            else
              _buildReasonSelection(state is ReportReasonsLoaded ? state.reasons : (state is ReportSubmitting ? state.reasons : []), size),

            const SizedBox(height: 24),

            // Additional Details
            Text(
              'Additional Details (Optional)',
              style: TextStyle(
                fontSize: (size.width * 0.04).clamp(14.0, 16.0),
                fontWeight: FontWeight.w500,
                color: Colors.white
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _detailsController,
              maxLines: 4,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Nunito',
                fontSize: (size.width * 0.035).clamp(12.0, 15.0),
              ),
              decoration: InputDecoration(
                hintText: 'Please provide any additional details about your experience...',
                hintStyle: TextStyle(
                  color: Color(0xFFD6D9E6),
                  fontSize: (size.width * 0.032).clamp(11.0, 13.0),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD6D9E6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF4C5C8A)),
                ),
              ),
              validator: (value) {
                // No validation required for optional field
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (state is ReportSubmitting || _selectedReason == null) 
                    ? null 
                    : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFf4656f),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: state is ReportSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white)
                        ),
                      )
                    : Text(
                        'Submit Report',
                        style: TextStyle(
                          fontSize: (size.width * 0.04).clamp(14.0, 16.0),
                          fontWeight: FontWeight.w500,
                          color: Colors.white
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Warning text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[900]?.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[700] ?? Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange[400],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'False reports may result in your account being suspended.',
                      style: TextStyle(
                        color: Colors.orange[400],
                        fontSize: (size.width * 0.03).clamp(10.0, 13.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonSelection(List<String> reasons, Size size) {
    return Column(
      children: reasons.map((reason) {
        return RadioListTile<String>(
          title: Text(reason, style: TextStyle(fontFamily: 'Nunito', fontSize: (size.width * 0.035).clamp(12.0, 15.0), fontWeight: FontWeight.w500, color: Colors.white)),
          value: reason,
          groupValue: _selectedReason,
          onChanged: (value) {
            setState(() {
              _selectedReason = value;
            });
          },
          activeColor: const Color(0xFFf4656f),
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }
} 