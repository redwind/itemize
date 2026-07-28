// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Itemize';

  @override
  String get dashboardTitle => 'Tổng quan';

  @override
  String get totalValue => 'Tổng giá trị';

  @override
  String get assetsTab => 'Tài sản';

  @override
  String get settingsTab => 'Cài đặt';

  @override
  String get searchPlaceholder => 'Tìm kiếm tài sản...';

  @override
  String get noAssetsFound => 'Không tìm thấy tài sản';

  @override
  String get addItemTitle => 'Thêm tài sản mới';

  @override
  String get smartScan => 'Quét thông minh (AI)';

  @override
  String get scanBarcode => 'Quét mã vạch';

  @override
  String get scanReceipt => 'Quét hóa đơn (OCR)';

  @override
  String get exportPdf => 'Xuất báo cáo PDF';

  @override
  String get biometricLock => 'Khóa sinh trắc học';

  @override
  String get biometricLockSubtitle =>
      'Yêu cầu FaceID/TouchID cho các tác vụ nhạy cảm';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get currency => 'Tiền tệ';

  @override
  String get dataManagement => 'Quản lý dữ liệu';

  @override
  String get exportPdfSubtitle => 'Tạo báo cáo bảo hiểm';

  @override
  String get backupData => 'Sao lưu dữ liệu';

  @override
  String get backupDataSubtitle => 'Sao lưu cục bộ (Sắp ra mắt)';

  @override
  String get preferences => 'Tùy chọn';

  @override
  String get about => 'Giới thiệu';

  @override
  String get version => 'Phiên bản';
}
