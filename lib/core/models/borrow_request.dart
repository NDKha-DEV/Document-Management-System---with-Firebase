import 'cloud_document.dart';

class BorrowRequest {
  final int id;
  final String documentId;
  final String? documentTitle;
  final String requesterId;
  final String? requesterEmail;
  final String? requesterName;
  final String ownerId;
  final String? ownerEmail;
  final String? ownerName;
  final String status; // 'pending', 'approved', 'rejected', 'returned'
  final String? requestNote;
  final String? responseNote;
  final DateTime? borrowDate;
  final DateTime? returnDueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final CloudDocument? document;

  BorrowRequest({
    required this.id,
    required this.documentId,
    this.documentTitle,
    required this.requesterId,
    this.requesterEmail,
    this.requesterName,
    required this.ownerId,
    this.ownerEmail,
    this.ownerName,
    required this.status,
    this.requestNote,
    this.responseNote,
    this.borrowDate,
    this.returnDueDate,
    this.createdAt,
    this.updatedAt,
    this.document,
  });

  factory BorrowRequest.fromMap(Map<String, dynamic> m) {
    final docMap = m['documents'] is Map ? m['documents'] as Map<String, dynamic> : null;
    final reqMap = m['requester'] is Map ? m['requester'] as Map : null;
    final ownerMap = m['owner'] is Map ? m['owner'] as Map : null;

    return BorrowRequest(
      id: (m['id'] as num).toInt(),
      documentId: m['document_id'] as String,
      documentTitle: docMap?['title'] as String? ?? m['document_title'] as String?,
      requesterId: m['requester_id'] as String,
      requesterEmail: reqMap?['email'] as String? ?? m['requester_email'] as String?,
      requesterName: reqMap?['display_name'] as String? ?? m['requester_name'] as String?,
      ownerId: m['owner_id'] as String,
      ownerEmail: ownerMap?['email'] as String? ?? m['owner_email'] as String?,
      ownerName: ownerMap?['display_name'] as String? ?? m['owner_name'] as String?,
      status: (m['status'] as String?) ?? 'pending',
      requestNote: m['request_note'] as String?,
      responseNote: m['response_note'] as String?,
      borrowDate: _parseDate(m['borrow_date']),
      returnDueDate: _parseDate(m['return_due_date']),
      createdAt: _parseDate(m['created_at']),
      updatedAt: _parseDate(m['updated_at']),
      document: docMap != null ? CloudDocument.fromMap(docMap) : null,
    );
  }

  static DateTime? _parseDate(dynamic v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  String get statusLabel {
    switch (status) {
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Từ chối';
      case 'returned':
        return 'Đã trả';
      case 'pending':
      default:
        return 'Chờ duyệt';
    }
  }
}
