import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Process payment for a completed walk
  Future<void> processPayment({
    required String walkId,
    required String wandererId,
    required String walkerId,
    required double totalCost,
    required String paymentMethod,
  }) async {
    try {
      // Calculate commission (25%)
      final commission = totalCost * 0.25;
      final walkerEarnings = totalCost - commission;

      // Update walk with payment status
      await _firestore.collection('walks').doc(walkId).update({
        'paymentStatus': 'paid',
        'paidAt': DateTime.now(),
        'paymentMethod': paymentMethod,
      });

      // Create payment record
      await _firestore.collection('payments').doc().set({
        'walkId': walkId,
        'wandererId': wandererId,
        'walkerId': walkerId,
        'totalCost': totalCost,
        'commission': commission,
        'walkerEarnings': walkerEarnings,
        'paymentStatus': 'paid',
        'paymentMethod': paymentMethod,
        'createdAt': DateTime.now(),
      });

      // Update user's wallet/earnings
      await _updateUserEarnings(walkerId, walkerEarnings);

      // TODO: Integrate actual payment gateway (Razorpay) here
      // For now, we'll simulate payment
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }

  // Update Walker's earnings
  Future<void> _updateUserEarnings(String userId, double earnings) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final currentEarnings = userDoc.data()?['totalEarnings'] ?? 0.0;
        await _firestore.collection('users').doc(userId).update({
          'totalEarnings': currentEarnings + earnings,
          'lastUpdated': DateTime.now(),
        });
      }
    } catch (e) {
      // Ignore errors in earning updates
      print('Error updating earnings: $e');
    }
  }

  // Get payment history for a user
  Stream<List<Map<String, dynamic>>> getPaymentHistory(String userId, {required bool isWalker}) {
    try {
      return _firestore
          .collection('payments')
          .where(isWalker ? 'walkerId' : 'wandererId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList());
    } catch (e) {
      throw Exception('Failed to get payment history: $e');
    }
  }

  // Show payment confirmation dialog
  Future<bool> showPaymentConfirmation({
    required BuildContext context,
    required String wandererName,
    required double totalCost,
    required double commission,
    required double walkerEarnings,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Walking with: $wandererName'),
            const SizedBox(height: 16),
            _buildPaymentRow('Total Cost', '\$${totalCost.toStringAsFixed(2)}', Colors.blue),
            _buildPaymentRow('Commission (25%)', '\$${commission.toStringAsFixed(2)}', Colors.grey),
            const Divider(),
            _buildPaymentRow('Your Earnings', '\$${walkerEarnings.toStringAsFixed(2)}', Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Payment will be processed automatically.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Widget _buildPaymentRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}






