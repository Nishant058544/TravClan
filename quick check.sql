---quick peek (to build intuition)

SELECT TOP (5) *
FROM dbo.vw_bookings;

---sanity check A (dates & length of stay)

SELECT 
  COUNT(*) AS rows_total,
  SUM(CASE WHEN booking_date IS NULL  THEN 1 ELSE 0 END) AS bad_booking_date,
  SUM(CASE WHEN checkin_date IS NULL  THEN 1 ELSE 0 END) AS bad_checkin_date,
  SUM(CASE WHEN checkout_date IS NULL THEN 1 ELSE 0 END) AS bad_checkout_date,
  SUM(CASE WHEN length_of_stay IS NULL OR length_of_stay <= 0 THEN 1 ELSE 0 END) AS nonpositive_los
FROM dbo.vw_bookings;


---sanity check B (overall cancellation rate)

SELECT 
  SUM(CASE WHEN is_canceled=1 THEN 1 ELSE 0 END) AS cancels,
  COUNT(*) AS bookings,
  1.0*SUM(CASE WHEN is_canceled=1 THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0) AS cancel_rate
FROM dbo.vw_bookings;



