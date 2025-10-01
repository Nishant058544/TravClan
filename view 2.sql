USE HotelBookings_v2;
GO
IF OBJECT_ID('dbo.vw_bookings_clean','V') IS NOT NULL DROP VIEW dbo.vw_bookings_clean;
GO
CREATE VIEW dbo.vw_bookings_clean AS
SELECT *
FROM dbo.vw_bookings
WHERE checkin_date  IS NOT NULL
  AND checkout_date IS NOT NULL
  AND length_of_stay > 0;
GO
