/// Shared types for receipt printer services.
///
/// This file contains common types used by both the main
/// `ReceiptPrinterService` and the black-and-white variant `ReceiptPrinterServiceBW`.
class ReceiptPrinterException implements Exception {
  const ReceiptPrinterException(this.message, {this.canOpenSettings = false});

  final String message;
  final bool canOpenSettings;

  @override
  String toString() => message;
}

class ReceiptPrinterDevice {
  const ReceiptPrinterDevice({
    required this.name,
    required this.macAddress,
  });

  final String name;
  final String macAddress;

  factory ReceiptPrinterDevice.fromBluetoothInfo(dynamic info) {
    // Support both Map (legacy) and BluetoothInfo object (new API)
    if (info is Map) {
      return ReceiptPrinterDevice(
        name: ((info['name'] as String?) ?? 'Printer').trim(),
        macAddress: ((info['macAdress'] as String?) ?? '').trim(),
      );
    }
    // Assume BluetoothInfo-like object with name and macAdress properties
    return ReceiptPrinterDevice(
      name: (info.name as String? ?? 'Printer').trim(),
      macAddress: (info.macAdress as String? ?? '').trim(),
    );
  }

  bool hasSameAddress(ReceiptPrinterDevice other) =>
      macAddress == other.macAddress;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptPrinterDevice &&
          runtimeType == other.runtimeType &&
          macAddress == other.macAddress;

  @override
  int get hashCode => macAddress.hashCode;

  @override
  String toString() => 'ReceiptPrinterDevice(name: $name, macAddress: $macAddress)';
}