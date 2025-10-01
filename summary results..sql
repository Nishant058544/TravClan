USE HotelBookings_v2;

SELECT
  booking_year,
  booking_month,
  month_label = CONCAT(LEFT(booking_month_name,3), '-', booking_year),
  month_key   = booking_year*100 + booking_month,
  bookings,
  cancels
FROM dbo.summary_monthly
ORDER BY month_key;
