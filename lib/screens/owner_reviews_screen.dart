import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OwnerReviewsScreen extends StatefulWidget {
  const OwnerReviewsScreen({super.key});

  @override
  State<OwnerReviewsScreen> createState() => _OwnerReviewsScreenState();
}

class _OwnerReviewsScreenState extends State<OwnerReviewsScreen> {
  List<QueryDocumentSnapshot> reviews = [];
  bool isLoading = true;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    try {
      final ownerId = FirebaseAuth.instance.currentUser!.uid;

      // STEP 2: Fetch owner properties
      final propertiesSnapshot = await FirebaseFirestore.instance
          .collection("properties")
          .where("ownerId", isEqualTo: ownerId)
          .get();

      // STEP 3: Collect property IDs
      List<String> propertyIds =
          propertiesSnapshot.docs.map((doc) => doc.id).toList();

      List<QueryDocumentSnapshot> allReviews = [];

      // STEP 4: Fetch reviews for each property
      for (String propertyId in propertyIds) {
        final reviewSnapshot = await FirebaseFirestore.instance
            .collection("properties")
            .doc(propertyId)
            .collection("reviews")
            .orderBy("createdAt", descending: true)
            .get();

        allReviews.addAll(reviewSnapshot.docs);
      }

      // STEP 5: Update state
      setState(() {
        reviews = allReviews;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching reviews: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ===== REVIEW STATS CALCULATION =====
    double avgRating = 0;
    int totalReviews = reviews.length;
    int pendingReviews = 0;
    int respondedReviews = 0;

    int star5 = 0;
    int star4 = 0;
    int star3 = 0;
    int star2 = 0;
    int star1 = 0;

    for (var doc in reviews) {
      final data = doc.data() as Map<String, dynamic>;
      final rawRating = data['rating'];

    final rating = rawRating is num
        ? rawRating.toDouble()
        : double.tryParse(rawRating?.toString() ?? '0') ?? 0;
          final hasReply = data['ownerReply'] != null && data['ownerReply'] != '';

      avgRating += rating;

      if (!hasReply) {
        pendingReviews++;
      } else {
        respondedReviews++;
      }

      if (rating >= 5) {
        star5++;
      } else if (rating >= 4) star4++;
      else if (rating >= 3) star3++;
      else if (rating >= 2) star2++;
      else if (rating >= 1) star1++;
    }

    if (totalReviews > 0) {
      avgRating = avgRating / totalReviews;
    }
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 41, 70, 92),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Reviews',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '"Manage guest feedback smartly."',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF6FAF8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage and respond to guest feedback',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),

                // ===== TOP METRICS =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Average Rating',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF64748B))),
                            const SizedBox(height: 6),
                            Text(avgRating.toStringAsFixed(1),
                                style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800)),
                          ]),
                      const Icon(Icons.star, color: Colors.amber, size: 32),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Row(children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FFF6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Reviews',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B))),
                            const SizedBox(height: 6),
                            Text('$totalReviews',
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700)),
                          ]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F8FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pending Response',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B))),
                            const SizedBox(height: 6),
                            Text('$pendingReviews',
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700)),
                          ]),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3FB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Response Rate',
                            style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B))),
                        const SizedBox(height: 6),
                        Text(totalReviews == 0
                            ? '0%'
                            : '${((respondedReviews / totalReviews) * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700)),
                      ]),
                ),

                const SizedBox(height: 16),

                // ===== TABS =====
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = 0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _tabIndex == 0
                                ? const Color(0xFF1E5FA8)
                                : Colors.transparent,
                            borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(20)),
                          ),
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                            child: Text('All Reviews',
                                style: TextStyle(
                                    color: _tabIndex == 0
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = 1),
                        child: Container(
                          color: _tabIndex == 1
                              ? const Color(0xFFE3F2FD)
                              : Colors.transparent,
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          child: const Center(
                              child: Text('Pending',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600))),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = 2),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _tabIndex == 2
                                ? const Color(0xFFE3F2FD)
                                : Colors.transparent,
                            borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(20)),
                          ),
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          child: const Center(
                              child: Text('Responded',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600))),
                        ),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 16),

                // ===== REVIEWS LIST =====
                isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : reviews.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text("No reviews yet"),
                            ),
                          )
                        : (() {
                            final filteredReviews = _tabIndex == 0
                                ? reviews
                                : _tabIndex == 1
                                    ? reviews.where((doc) {
                                        final data = doc.data() as Map<String, dynamic>;
                                        return data['ownerReply'] == null || data['ownerReply'] == '';
                                      }).toList()
                                    : reviews.where((doc) {
                                        final data = doc.data() as Map<String, dynamic>;
                                        return data['ownerReply'] != null && data['ownerReply'] != '';
                                      }).toList();
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredReviews.length,
                              itemBuilder: (context, index) {
                                final reviewDoc = filteredReviews[index];
                                final data = reviewDoc.data() as Map<String, dynamic>;

                                final userName =
                                    data['userName'] ?? 'Guest';
                                final comment = data['comment'] ?? '';
                                final rating = data['rating'] ?? 0;

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.star, color: Colors.amber),
                                            const SizedBox(width: 8),
                                            Text(userName,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold)),
                                            const Spacer(),
                                            Text("$rating ⭐"),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(comment),
                                        const SizedBox(height: 8),
                                        if (data['ownerReply'] != null &&
                                            data['ownerReply'] != '')
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE8F2FF),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              "Owner Reply: ${data['ownerReply']}",
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                          )
                                        else
                                          TextButton.icon(
                                            onPressed: () {
                                              final controller = TextEditingController();

                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: const Text("Reply to Review"),
                                                    content: TextField(
                                                      controller: controller,
                                                      maxLines: 3,
                                                      decoration: const InputDecoration(
                                                        hintText: "Write your reply...",
                                                        border: OutlineInputBorder(),
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(context);
                                                        },
                                                        child: const Text("Cancel"),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () async {
                                                          final reply = controller.text.trim();
                                                          if (reply.isEmpty) return;

                                                          try {
                                                            await reviewDoc.reference.update({
                                                              "ownerReply": reply,
                                                              "repliedAt": FieldValue.serverTimestamp(),
                                                            });

                                                            Navigator.pop(context);

                                                            setState(() {});
                                                          } catch (e) {
                                                            debugPrint("Reply error: $e");
                                                          }
                                                        },
                                                        child: const Text("Send"),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                            icon: const Icon(Icons.reply),
                                            label: const Text("Reply"),
                                          )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          })(),
              ]),
        ),
      ),
    );
  }
}