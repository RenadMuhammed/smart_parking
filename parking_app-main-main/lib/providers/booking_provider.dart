import 'package:flutter/material.dart';
import 'package:smart_parking_app/core/models/booking.dart';
import 'package:smart_parking_app/core/services/booking_service.dart';

class BookingProvider with ChangeNotifier {
  List<BookingModel> _activeBookings = [];
  List<BookingModel> _bookingHistory = [];

  List<BookingModel> get activeBookings => _activeBookings;
  List<BookingModel> get bookingHistory => _bookingHistory;

  Future<void> fetchActiveBookings(String userId) async {
    final bookingsData = await BookingService.fetchActiveBookings(userId);
    _activeBookings = bookingsData.map((data) => BookingModel.fromJson(data)).toList();
    notifyListeners();
  }

  Future<void> fetchBookingHistory(String userId) async {
    final bookingsData = await BookingService.fetchBookingHistory(userId);
    _bookingHistory = bookingsData.map((data) => BookingModel.fromJson(data)).toList();
    notifyListeners();
  }

  Future<void> createBooking(BookingModel booking) async {
    await BookingService.createBooking(booking);
    _activeBookings.add(booking);
    notifyListeners();
  }
}
