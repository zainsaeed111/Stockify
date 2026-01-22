import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../theme/app_colors.dart';

class ReceiptPreviewScreen extends StatelessWidget {
  final String title;
  final LayoutCallback buildPdf;
  final Uint8List? initialBytes;

  const ReceiptPreviewScreen({
    super.key, 
    required this.title, 
    required this.buildPdf,
    this.initialBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Make background transparent for dialog feel
      body: Stack(
        children: [
          // Dimmed background helper (if not using showDialog's barrier)
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.black54),
          ),
          Center(
            child: Container(
              width: 420,
              height: 650,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 4))],
              ),
              clipBehavior: Clip.hardEdge,
              child: Shortcuts(
                shortcuts: {
                   LogicalKeySet(LogicalKeyboardKey.enter): const _PrintIntent(),
                   LogicalKeySet(LogicalKeyboardKey.keyP): const _PrintIntent(),
                   LogicalKeySet(LogicalKeyboardKey.keyS): const _ShareIntent(),
                   LogicalKeySet(LogicalKeyboardKey.escape): const _CloseIntent(),
                },
                child: Actions(
                  actions: {
                    _PrintIntent: CallbackAction<_PrintIntent>(onInvoke: (_) => Printing.layoutPdf(onLayout: buildPdf)),
                    _ShareIntent: CallbackAction<_ShareIntent>(onInvoke: (_) async {
                      final bytes = await buildPdf(PdfPageFormat.roll80);
                      await Printing.sharePdf(bytes: bytes, filename: 'receipt.pdf');
                      return null;
                    }),
                    _CloseIntent: CallbackAction<_CloseIntent>(onInvoke: (_) => Navigator.pop(context)),
                  },
                  child: Focus(
                    autofocus: true, 
                    child: Column(
                      children: [
                        // Custom Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          color: AppColors.primary,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                onPressed: () => Navigator.pop(context),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                        // PDF Preview
                        Expanded(
                          child: PdfPreview(
                            build: buildPdf,
                            initialPageFormat: PdfPageFormat.roll80,
                            allowPrinting: true,
                            allowSharing: true,
                            canChangeOrientation: false,
                            canChangePageFormat: false,
                            canDebug: false,
                            maxPageWidth: 320, // Tighter width for Roll80
                            pdfFileName: 'receipt.pdf',
                            scrollViewDecoration: BoxDecoration(
                              color: Colors.grey.shade100,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrintIntent extends Intent { const _PrintIntent(); }
class _ShareIntent extends Intent { const _ShareIntent(); }
class _CloseIntent extends Intent { const _CloseIntent(); }
