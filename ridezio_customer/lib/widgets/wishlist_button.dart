import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/providers.dart';
import '../screens/wishlist_screen.dart';

class WishlistButton extends ConsumerStatefulWidget {
  final int vehicleId;
  final bool initialStatus;
  final double size;

  const WishlistButton({
    super.key,
    required this.vehicleId,
    this.initialStatus = false,
    this.size = 18,
  });

  @override
  ConsumerState<WishlistButton> createState() => _WishlistButtonState();
}

class _WishlistButtonState extends ConsumerState<WishlistButton> {
  late bool _isInWishlist;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isInWishlist = widget.initialStatus;
  }

  Future<void> _toggleWishlist() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.post('/user/wishlist/toggle', {'vehicle_id': widget.vehicleId});
      setState(() {
        _isInWishlist = response['status'] == 'added';
      });
      ref.refresh(wishlistProvider);
      ref.refresh(vehiclesProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'])));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update wishlist')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : _toggleWishlist,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: _isLoading
            ? SizedBox(width: widget.size, height: widget.size, child: const CircularProgressIndicator(strokeWidth: 2))
            : Icon(
                _isInWishlist ? Icons.favorite : Icons.favorite_border,
                size: widget.size,
                color: _isInWishlist ? Colors.red : Colors.black54,
              ),
      ),
    );
  }
}
