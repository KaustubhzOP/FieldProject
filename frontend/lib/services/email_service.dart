import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

/// Cross-platform email service.
/// Uses Gmail SMTP on Native Devices and FormSubmit (Optimized) on Web.
class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  static const String _senderEmail = '2024.kaustubh.patil@ves.ac.in';
  static const String _appPassword  = 'amgm ibwh fixb xrqc';

  Future<void> sendComplaintRegistered({
    required String toEmail,
    required String toName,
    required String complaintId,
    required String type,
    required String description,
  }) =>
      _dispatch(
        to: toEmail,
        subject: 'Complaint Registered — #${_short(complaintId)}',
        html: _template(
          heading: '✅ Complaint Successfully Registered',
          recipientName: toName,
          message: 'Your complaint has been successfully registered. Our team will review it shortly.',
          status: 'PENDING',
          statusColor: '#f59e0b',
          complaintId: complaintId,
          type: type,
          description: description,
        ),
        webData: {
          'Status': '✅ REGISTERED',
          'Name': toName,
          'ID': '#${_short(complaintId)}',
          'Complaint Type': type,
          'Description': description,
          'Message': 'Your complaint is being processed. Thank you.',
        },
      );

  Future<void> sendComplaintInProgress({
    required String toEmail,
    required String toName,
    required String complaintId,
    required String type,
    required String description,
    String? remarks,
  }) =>
      _dispatch(
        to: toEmail,
        subject: 'Complaint In Progress — #${_short(complaintId)}',
        html: _template(
          heading: '🔧 Your Complaint Is Being Addressed',
          recipientName: toName,
          message: 'A garbage collection team has been assigned and work is now underway.',
          status: 'IN PROGRESS',
          statusColor: '#0ea5e9',
          complaintId: complaintId,
          type: type,
          description: description,
          remarks: remarks,
        ),
        webData: {
          'Status': '🔧 IN PROGRESS',
          'ID': '#${_short(complaintId)}',
          'Details': '$type: $description',
          'Admin Remarks': remarks ?? 'None',
        },
      );

  Future<void> sendComplaintResolved({
    required String toEmail,
    required String toName,
    required String complaintId,
    required String type,
    required String description,
    String? remarks,
  }) =>
      _dispatch(
        to: toEmail,
        subject: 'Complaint Resolved — #${_short(complaintId)}',
        html: _template(
          heading: '🎉 Your Complaint Has Been Resolved',
          recipientName: toName,
          message: 'Great news! Your waste collection complaint has been successfully resolved.',
          status: 'RESOLVED',
          statusColor: '#22c55e',
          complaintId: complaintId,
          type: type,
          description: description,
          remarks: remarks,
        ),
        webData: {
          'Status': '🎉 RESOLVED',
          'ID': '#${_short(complaintId)}',
          'Resolution Notes': remarks ?? 'Problem resolved by field team.',
          'Message': 'Thank you for your cooperation!',
        },
      );

  Future<void> sendNewComplaintAlertToAdmin({
    required String adminEmail,
    required String residentName,
    required String residentEmail,
    required String complaintId,
    required String type,
    required String description,
    required String ward,
  }) async {
    final html = _template(
      heading: '🚨 New Complaint Alert',
      recipientName: 'Admin',
      message: 'Resident $residentName has filed a new complaint in your area.',
      status: 'PENDING',
      statusColor: '#dc2626',
      complaintId: complaintId,
      type: type,
      description: 'Filed by $residentName\nContact: $residentEmail\n\n$description',
    );
    final webData = {
      'ALERT': '🚨 NEW COMPLAINT FILED',
      'Area/Ward': ward,
      'Resident': residentName,
      'Resident Email': residentEmail,
      'Complaint ID': '#${_short(complaintId)}',
      'Category': type,
      'Detailed Note': description,
    };

    await _dispatch(
      to: adminEmail,
      subject: '🚨 New Alert: $type — #${_short(complaintId)}',
      html: html,
      webData: webData,
      replyTo: residentEmail,
    );
  }

  // ── Dispatch logic ─────────────────────────────────────────────────────────

  Future<void> _dispatch({
    required String to,
    required String subject,
    required String html,
    required Map<String, String> webData,
    String? replyTo,
  }) async {
    print('[Email] Dispatching to: $to | Subject: $subject | Platform: ${kIsWeb ? "Web" : "Native"}');
    if (to.isEmpty || !to.contains('@')) {
      print('[Email] ✗ Aborted: Invalid recipient address.');
      return;
    }

    if (kIsWeb) {
      await _sendViaFormSubmit(to: to, subject: subject, data: webData, replyTo: replyTo);
    } else {
      await _sendViaSmtp(to: to, subject: subject, html: html, replyTo: replyTo);
    }
  }

  Future<void> _sendViaFormSubmit({required String to, required String subject, required Map<String, String> data, String? replyTo}) async {
    try {
      print('[Email] Building FormSubmit payload for $to...');
      final payload = Map<String, String>.from(data);
      payload['_subject'] = subject;
      payload['email'] = replyTo ?? _senderEmail;
      payload['_template'] = 'table';
      payload['_captcha'] = 'false';

      final response = await http.post(
        Uri.parse('https://formsubmit.co/ajax/$to'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(payload),
      );
      
      print('[Email] FormSubmit Response: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('[Email] ✓ Web Alert Sent Successfully to $to');
      } else {
        print('[Email] ✗ Web Alert Failed: ${response.body}');
      }
    } catch (e) {
      print('[Email] ✗ Web Error: $e');
    }
  }

  Future<void> _sendViaSmtp({required String to, required String subject, required String html, String? replyTo}) async {
    final smtpServer = gmail(_senderEmail, _appPassword);
    final message = Message()
      ..from = Address(_senderEmail, 'Smart Waste BMC')
      ..recipients.add(to)
      ..subject = subject
      ..html = html;
    if (replyTo != null && replyTo.isNotEmpty) message.headers['Reply-To'] = Address(replyTo);

    try {
      await send(message, smtpServer);
      print('[Email] Native Alert Sent Successfully');
    } catch (e) {
      print('[Email] Native Error: $e');
    }
  }

  String _short(String id) => id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();

  String _template({
    required String heading,
    required String recipientName,
    required String message,
    required String status,
    required String statusColor,
    required String complaintId,
    required String type,
    required String description,
    String? remarks,
  }) {
    final remarksBlock = (remarks != null && remarks.isNotEmpty)
        ? '<div style="background:#fefce8;border-left:4px solid #f59e0b;padding:12px;margin:12px 0;"><strong>Admin Remarks:</strong> $remarks</div>'
        : '';
    return '''
<!DOCTYPE html><html><body style="font-family:Sans-Serif;background:#f1f5f9;padding:20px;">
<div style="background:#fff;max-width:600px;margin:auto;border-radius:12px;overflow:hidden;border:1px solid #e2e8f0;">
  <div style="background:linear-gradient(135deg,#1e40af,#0ea5e9);padding:24px;color:#fff;">
    <h2 style="margin:0;">♻️ Smart Waste BMC</h2>
  </div>
  <div style="padding:32px;">
    <h3 style="margin-top:0;">$heading</h3>
    <p>Hi <strong>$recipientName</strong>,</p>
    <p>$message</p>
    <div style="background:#f8fafc;padding:16px;border-radius:8px;">
      <p><strong>ID:</strong> #${_short(complaintId)}</p>
      <p><strong>Type:</strong> $type</p>
      <p><strong>Status:</strong> <span style="color:$statusColor;font-weight:bold;">$status</span></p>
      <p><strong>Details:</strong> $description</p>
    </div>
    $remarksBlock
    <p style="color:#94a3b8;font-size:12px;margin-top:20px;">Automated alert from BMC Smart Waste. Do not reply.</p>
  </div>
</div>
</body></html>''';
  }
}
