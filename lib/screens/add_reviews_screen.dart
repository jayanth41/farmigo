import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/review_service_new.dart';

class AddReviewScreen extends StatefulWidget {
  final String propertyId;

  const AddReviewScreen({super.key, required this.propertyId});

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final TextEditingController _controller = TextEditingController();
  final ReviewService _reviewService = ReviewService();
  double rating = 5;
  bool _isSubmitting = false;

  Future<void> submitReview() async {
    final comment = _controller.text.trim();
    if (comment.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please write a review')),
        );
      }
      return;
    }

    if (mounted) setState(() => _isSubmitting = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';

      await _reviewService.addReview(
        reviewText: comment,
        rating: rating.round(),
        propertyId: widget.propertyId,
        userId: userId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Review submitted successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Review')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Write your review',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              const Text('Rating'),
              Slider(
                value: rating,
                min: 1,
                max: 5,
                divisions: 4,
                label: rating.toString(),
                onChanged: (v) {
                  setState(() => rating = v);
                },
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        if (kDebugMode) debugPrint('SUBMIT CLICKED');
                        await submitReview();
                      },
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Review'),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

// Note: this screen is part of the app; run the app from `lib/main.dart`.
