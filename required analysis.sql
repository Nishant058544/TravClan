--- (A) Overall KPIs on the clean data

SELECT 
  COUNT(*) AS total_bookings,
  SUM(CASE WHEN is_canceled=1 THEN 1 ELSE 0 END) AS cancellations,
  CAST(1.0*SUM(CASE WHEN is_canceled=1 THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0) AS DECIMAL(6,4)) AS cancellation_rate,
  CAST(AVG(lead_time*1.0) AS DECIMAL(10,2)) AS avg_lead_time_days,
  CAST(AVG(length_of_stay*1.0) AS DECIMAL(10,2)) AS avg_length_of_stay_nights,
  CAST(AVG(price_per_night) AS DECIMAL(10,2)) AS avg_price_per_night,
  CAST(AVG(revenue) AS DECIMAL(12,2)) AS avg_revenue_per_booking
FROM dbo.vw_bookings_clean;

---(B) By channel (clean data)

SELECT 
  channel,
  COUNT(*) AS bookings,
  SUM(CASE WHEN is_canceled=1 THEN 1 ELSE 0 END) AS cancels,
  CAST(1.0*SUM(CASE WHEN is_canceled=1 THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0) AS DECIMAL(6,4)) AS cancel_rate
FROM dbo.vw_bookings_clean
GROUP BY channel
ORDER BY bookings DESC;

--Step 1 — Monthly trend (bookings, cancels, LOS, revenue)

USE HotelBookings_v2;

SELECT 
  booking_year, booking_month, booking_month_name,
  COUNT(*) AS bookings,
  SUM(CASE WHEN is_canceled=1 THEN 1 ELSE 0 END) AS cancels,
  SUM(revenue) AS revenue,
  CAST(AVG(length_of_stay*1.0) AS DECIMAL(10,2)) AS avg_los
FROM dbo.vw_bookings_clean
GROUP BY booking_year, booking_month, booking_month_name
ORDER BY booking_year, booking_month;

---Step 2 — Lead-time bins vs cancellation (behavioral pattern)

WITH b AS (
  SELECT *,
         CASE 
           WHEN lead_time IS NULL THEN 'Z:Unknown'
           WHEN lead_time < 7 THEN 'A:0-6d'
           WHEN lead_time BETWEEN 7 AND 14 THEN 'B:7-14d'
           WHEN lead_time BETWEEN 15 AND 30 THEN 'C:15-30d'
           WHEN lead_time BETWEEN 31 AND 60 THEN 'D:31-60d'
           WHEN lead_time BETWEEN 61 AND 120 THEN 'E:61-120d'
           ELSE 'F:>120d'
         END AS lead_bin
  FROM dbo.vw_bookings  -- note: uses raw view to show Unknown too
)
SELECT lead_bin,
       COUNT(*) AS bookings,
       CAST(1.0*SUM(CASE WHEN is_canceled=1 THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0) AS DECIMAL(6,4)) AS cancel_rate
FROM b
GROUP BY lead_bin
ORDER BY lead_bin;

---Step 3 — Room type × star rating

USE HotelBookings_v2;

SELECT 
  room_type_reserved,
  star_rating,
  COUNT(*) AS bookings,
  SUM(CASE WHEN is_canceled=1 THEN 1 ELSE 0 END) AS cancels,
  CAST(1.0*SUM(CASE WHEN is_canceled=1 THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0) AS DECIMAL(6,4)) AS cancel_rate,
  CAST(AVG(revenue) AS DECIMAL(12,2)) AS avg_revenue,
  CAST(AVG(length_of_stay*1.0) AS DECIMAL(10,2)) AS avg_los
FROM dbo.vw_bookings_clean
GROUP BY room_type_reserved, star_rating
ORDER BY bookings DESC;

