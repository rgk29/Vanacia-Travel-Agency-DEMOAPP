import 'dart:io';
import 'package:flutter/services.dart';
import 'package:agencedevoyage/currency_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class FlightTicketWidget extends ConsumerWidget {
  final String fullName;
  final String country;
  final String email;
  final String passportNumber;
  final double totalPrice;
  final String selectedBaggage;

  const FlightTicketWidget({
    super.key,
    required this.fullName,
    required this.country,
    required this.email,
    required this.passportNumber,
    required this.totalPrice,
    required this.selectedBaggage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedPrice =
        ref.read(currencyProvider.notifier).formatPrice(totalPrice);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "🛫_Voir_les_détails_du_vol".tr(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          child: TicketWidget(
            fullName: fullName,
            country: country,
            email: email,
            passportNumber: passportNumber,
            price: formattedPrice,
            selectedBaggage: selectedBaggage,
          ),
        ),
      ],
    );
  }
}

String formatPassport(String passport) {
  if (passport.length <= 3) return "**** $passport";
  return "**** ${passport.substring(passport.length - 3)}";
}

class TicketWidget extends StatelessWidget {
  final String fullName;
  final String country;
  final String email;
  final String passportNumber;
  final String price;
  final String selectedBaggage;

  const TicketWidget({
    super.key,
    required this.fullName,
    required this.country,
    required this.email,
    required this.passportNumber,
    required this.price,
    required this.selectedBaggage,
  });

  Future<void> _generateFlightPDF(BuildContext context) async {
    final pdf = pw.Document();
    final ByteData imageData = await rootBundle.load('assets/AirAlgérie.jpg');
    final Uint8List logoBytes = imageData.buffer.asUint8List();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child:
                  pw.Image(pw.MemoryImage(logoBytes), width: 150, height: 50),
            ),
            pw.SizedBox(height: 20),
            pw.Header(
              level: 0,
              child: pw.Text('E-BILLET AIR ALGÉRIE',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Divider(),
            _buildPDFSection('DÉTAILS DU VOL', [
              _buildPDFRow(
                  'Départ:', 'Oran (Ahmed Ben Bella) - 15 Août 2025 08:30'),
              _buildPDFRow(
                  'Arrivée:', 'Barcelone (El Prat) - 15 Août 2025 10:00'),
              _buildPDFRow('Retour:', 'Barcelone - 22 Août 2025 10:30'),
              _buildPDFRow('Destination finale:', 'Oran - 22 Août 2025 11:20'),
            ]),
            pw.SizedBox(height: 15),
            _buildPDFSection('INFORMATIONS PASSAGER', [
              _buildPDFRow('Nom complet:', fullName),
              _buildPDFRow('Nationalité:', country),
              _buildPDFRow('N° passeport:', formatPassport(passportNumber)),
              _buildPDFRow('Bagage:', selectedBaggage),
            ]),
            pw.SizedBox(height: 30),
            pw.Center(
              child: pw.Text(
                'Présentez ce document imprimé au comptoir d\'enregistrement',
                style:
                    pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file =
        File('${output.path}/billet_${fullName.replaceAll(' ', '_')}.pdf');
    await file.writeAsBytes(await pdf.save());

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF généré: ${file.path}'),
          action: SnackBarAction(
            label: 'Ouvrir',
            onPressed: () => OpenFile.open(file.path),
          ),
        ),
      );
    }
  }

  pw.Widget _buildPDFSection(String title, List<pw.Widget> rows) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 8),
        ...rows,
        pw.SizedBox(height: 15),
      ],
    );
  }

  pw.Widget _buildPDFRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4.0),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(label,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrData = "Nom: $fullName\n"
        "Pays: $country\n"
        "Email: $email\n"
        "Bagage : $selectedBaggage\n"
        "Passeport: ${formatPassport(passportNumber)}\n"
        "Prix: $price";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.asset('assets/AirAlgérie.jpg',
                height: 100, fit: BoxFit.cover),
          ),
          // Stack(
          //   children: [
          // ClipRRect(
          //   borderRadius:
          //       const BorderRadius.vertical(top: Radius.circular(20)),
          //   child: Image.asset(
          //     'assets/AirAlgérie.jpg',
          //     height: 100,
          //     width: double.infinity,
          //     fit: BoxFit.cover,
          //   ),
          // ),
          //     Positioned(
          //       top: 8,
          //       right: 8,
          //       child: Container(
          //         decoration: BoxDecoration(
          //           color: Colors.white.withOpacity(0.9),
          //           shape: BoxShape.circle,
          //         ),
          //         child: IconButton(
          //           icon: const Icon(Icons.download, color: Colors.blue),
          //           onPressed: () => _generateFlightPDF(context),
          //           tooltip: 'Télécharger PDF',
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.flight_takeoff, color: Colors.blue),
                Text("Air Algérie",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Icon(Icons.flight_land, color: Colors.redAccent),
              ],
            ),
          ),
          // Align(
          //   alignment: Alignment.topRight,
          //   child: IconButton(
          //     icon: const Icon(Icons.download, color: Colors.blue),
          //     onPressed: () => _generateFlightPDF(context),
          //     tooltip: 'Télécharger le PDF',
          //   ),
          // ),
          const Divider(),
          _ticketRow("📍_Départ".tr(), "Oran_(Ahmed_Ben_Bella)".tr(),
              "🕒_15_Août_2025_08_30".tr()),
          _ticketRow("📍_Arrivée".tr(), "Barcelone_(El_Prat)".tr(),
              "🕓_15_Août_2025_10_00".tr()),
          const Divider(),
          _ticketRow(
              "🔁_Retour".tr(), "Barcelone".tr(), "🕘_22_Août_2025_10_30".tr()),
          _ticketRow(
              "📍_Destination".tr(), "Oran".tr(), "🕤_22_Août_2025_11_20".tr()),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.person),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("${'country'.tr()} : $country"),
                      Text("${'email'.tr()} : $email"),
                      Text(
                          "${'passport'.tr()} : ${formatPassport(passportNumber)}"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enregistrer_votre_vol'.tr(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 150.0,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Colors.blue,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.download, color: Colors.blue),
                        onPressed: () => _generateFlightPDF(context),
                        tooltip: 'Télécharger PDF',
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Télécharger\nle PDF',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.luggage, color: Colors.brown),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${'selected_baggage'.tr()} : $selectedBaggage",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFEDF4FF),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Text(
              "${'💵_Prix_Total'.tr()} : $price",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ticketRow(String label, String place, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(place, style: const TextStyle(fontSize: 14)),
              Text(time,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
