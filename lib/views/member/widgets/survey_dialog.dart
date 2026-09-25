import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/survey_view_model.dart';

class SurveyDialog extends StatelessWidget {
  final String trainerName;
  final TextEditingController _commentController = TextEditingController();

  SurveyDialog({super.key, required this.trainerName});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SurveyViewModel>();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text("$trainerName ile dersin nasıldı?", textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Puanın eğitmene gizli tutulacaktır.", 
            style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 20),
          
          // 5 Yıldız Seçimi
          FittedBox(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    index < viewModel.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 36,
                  ),
                  onPressed: () => viewModel.setRating(index + 1.0),
                );
              }),
            ),
          ),
          
          const SizedBox(height: 20),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              hintText: "Görüşlerini yazabilirsin (isteğe bağlı)",
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Kapat"),
        ),
        ElevatedButton(
          onPressed: viewModel.isSubmitting || viewModel.rating == 0
              ? null
              : () async {
                  bool success = await viewModel.submitSurvey(_commentController.text);
                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Geri bildirimin için teşekkürler!")),
                    );
                  }
                },
          child: viewModel.isSubmitting 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("Gönder"),
        ),
      ],
    );
  }
}
