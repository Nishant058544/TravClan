---Step 4 — Create 4 summary tables for easy export

USE HotelBookings_v2;

-- monthly
IF OBJECT_ID('dbo.summary_monthly','U') IS NOT NULL DROP TABLE dbo.summary_monthly;
SELECT booking_year, booking_month, booking_month_name,
       COUNT(*) bookings,
       SUM(CASE WHEN is_canceled=1 THEN 1 ELSE 0 END) cancels
INTO dbo.summary_monthly
FROM dbo.vw_bookings_clean
GROUP BY booking_year, booking_month, booking_month_name;

-- channel
IF OBJECT_ID('dbo.summary_channel','U') IS NOT NULL DROP TABLE dbo.summary_channel;
SELECT channel,
       COUNT(*) bookings,
       SUM(CASE WHEN is_canceled=1 THEN 1 ELSE 0 END) cancels,
       CAST(1.0*SUM(CASE WHEN is_canceled=1 THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0) AS DECIMAL(6,4)) cancel_rate
INTO dbo.summary_channel
FROM dbo.vw_bookings_clean
GROUP BY channel;

-- room × star
IF OBJECT_ID('dbo.summary_room_star','U') IS NOT NULL DROP TABLE dbo.summary_room_star;
SELECT room_type_reserved, star_rating,
       COUNT(*) bookings,
       CAST(1.0*SUM(CASE WHEN is_canceled=1 THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0) AS DECIMAL(6,4)) cancel_rate
INTO dbo.summary_room_star
FROM dbo.vw_bookings_clean
GROUP BY room_type_reserved, star_rating;

-- lead-time bins (include Unknown for QA)
IF OBJECT_ID('dbo.summary_lead_bins','U') IS NOT NULL DROP TABLE dbo.summary_lead_bins;
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
  FROM dbo.vw_bookings
)
SELECT lead_bin,
       COUNT(*) bookings,
       CAST(1.0*SUM(CASE WHEN is_canceled=1 THEN 1 ELSE 0 END)/NULLIF(COUNT(*),0) AS DECIMAL(6,4)) cancel_rate
INTO dbo.summary_lead_bins
FROM b
GROUP BY lead_bin;
