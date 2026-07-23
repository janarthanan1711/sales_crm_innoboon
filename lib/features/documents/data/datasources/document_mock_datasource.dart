import '../../domain/entities/account_document.dart';
import '../../domain/repositories/document_repository.dart';

/// Local mock — there's no documents API contract wired yet. Returns the same
/// demo set for any account so the Documents tab can be built/reviewed; swap
/// for a real `DocumentRemoteDataSourceImpl` once the endpoint exists.
class DocumentMockDataSource implements DocumentDataSource {
  @override
  Future<List<AccountDocument>> getAccountDocuments(String accountId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return [
      AccountDocument(
        id: 'doc_1',
        name: 'MSA_Nexbridge_Final_2023.pdf',
        sizeBytes: 2411724, // 2.4 MB
        version: 'v1.0',
        uploadedByName: 'Sarah Jenkins',
        uploadedAt: DateTime(2023, 10, 12),
      ),
      AccountDocument(
        id: 'doc_2',
        name: 'SOW_Q4_Implementation.docx',
        sizeBytes: 1153433, // 1.1 MB
        version: 'v2.1',
        uploadedByName: 'Mike Ross',
        uploadedAt: DateTime(2023, 11, 5),
        versions: [
          DocumentVersion(
            version: 'v2.0',
            modifiedByName: 'Mike Ross',
            date: DateTime(2023, 11, 3),
            notes: 'Added security compliance clauses',
          ),
          DocumentVersion(
            version: 'v1.0',
            modifiedByName: 'Sarah Jenkins',
            date: DateTime(2023, 10, 28),
            notes: 'Initial draft from template',
          ),
        ],
      ),
      AccountDocument(
        id: 'doc_3',
        name: 'Pricing_Tiers_Calculator.xlsx',
        sizeBytes: 865280, // 845 KB
        version: 'v3.2',
        uploadedByName: 'Amanda Lee',
        uploadedAt: DateTime(2023, 11, 10),
      ),
      AccountDocument(
        id: 'doc_4',
        name: 'Technical_Architecture_Diagram.pdf',
        sizeBytes: 3355443,
        version: 'v1.0',
        uploadedByName: 'David Chen',
        uploadedAt: DateTime(2023, 11, 12),
      ),
      AccountDocument(
        id: 'doc_5',
        name: 'Security_Assessment_Report.pdf',
        sizeBytes: 1887436,
        version: 'v1.1',
        uploadedByName: 'Elena Rodriguez',
        uploadedAt: DateTime(2023, 11, 15),
      ),
      AccountDocument(
        id: 'doc_6',
        name: 'Implementation_Timeline.xlsx',
        sizeBytes: 524288,
        version: 'v2.0',
        uploadedByName: 'Mike Ross',
        uploadedAt: DateTime(2023, 11, 18),
      ),
      AccountDocument(
        id: 'doc_7',
        name: 'Stakeholder_Contact_List.xlsx',
        sizeBytes: 327680,
        version: 'v1.3',
        uploadedByName: 'Sarah Jenkins',
        uploadedAt: DateTime(2023, 11, 20),
      ),
      AccountDocument(
        id: 'doc_8',
        name: 'Kickoff_Meeting_Notes.docx',
        sizeBytes: 245760,
        version: 'v1.0',
        uploadedByName: 'Amanda Lee',
        uploadedAt: DateTime(2023, 11, 22),
      ),
      AccountDocument(
        id: 'doc_9',
        name: 'Budget_Approval_2024.pdf',
        sizeBytes: 1048576,
        version: 'v1.0',
        uploadedByName: 'David Chen',
        uploadedAt: DateTime(2023, 11, 25),
      ),
      AccountDocument(
        id: 'doc_10',
        name: 'Data_Migration_Plan.docx',
        sizeBytes: 1363148,
        version: 'v2.2',
        uploadedByName: 'Elena Rodriguez',
        uploadedAt: DateTime(2023, 11, 28),
      ),
      AccountDocument(
        id: 'doc_11',
        name: 'Support_SLA_Agreement.pdf',
        sizeBytes: 943718,
        version: 'v1.0',
        uploadedByName: 'Sarah Jenkins',
        uploadedAt: DateTime(2023, 12, 1),
      ),
      AccountDocument(
        id: 'doc_12',
        name: 'Onboarding_Checklist.xlsx',
        sizeBytes: 184320,
        version: 'v1.1',
        uploadedByName: 'Mike Ross',
        uploadedAt: DateTime(2023, 12, 3),
      ),
    ];
  }
}
