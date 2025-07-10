import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hushmate/presentation/bloc/report/report_bloc.dart';
import 'package:hushmate/presentation/bloc/report/report_event.dart';
import 'package:hushmate/presentation/bloc/report/report_state.dart';

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Report User',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
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
                child: CircularProgressIndicator(),
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
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ReportBloc>().add(LoadReportReasons());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else {
              // Show form with reasons (if loaded) or loading
              return _buildReportForm(state);
            }
          },
        ),
      ),
    );
  }

  Widget _buildReportForm(ReportState state) {
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Help us keep our community safe by reporting inappropriate behavior.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Report Reason Selection
            Text(
              'Reason for Report *',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              _buildReasonSelection(reasons),

            const SizedBox(height: 24),

            // Additional Details
            Text(
              'Additional Details (Optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _detailsController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Please provide any additional details about your experience...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.deepPurple),
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
                onPressed: (isSubmitting || _selectedReason == null) 
                    ? null 
                    : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Report',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Warning text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'False reports may result in your account being suspended.',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
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

  Widget _buildReasonSelection(List<String> reasons) {
    return Column(
      children: reasons.map((reason) {
        return RadioListTile<String>(
          title: Text(reason),
          value: reason,
          groupValue: _selectedReason,
          onChanged: (value) {
            setState(() {
              _selectedReason = value;
            });
          },
          activeColor: Colors.red,
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }
} 