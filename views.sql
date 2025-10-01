
USE HotelBookings_v2;
GO

IF OBJECT_ID('dbo.vw_bookings','V') IS NOT NULL DROP VIEW dbo.vw_bookings;
GO
CREATE VIEW dbo.vw_bookings AS
SELECT
    /* IDs & location */
    TRY_CONVERT(BIGINT,        COALESCE(booking_id, customer_id))                 AS booking_id,
    TRY_CONVERT(INT,           property_id)                                       AS property_id,
    NULLIF(LTRIM(RTRIM(COALESCE(property_name,''))), '')                           AS property_name,
    NULLIF(LTRIM(RTRIM(city)), '')                                                AS city,
    NULLIF(LTRIM(RTRIM(country)), '')                                             AS country,
    TRY_CONVERT(TINYINT,       star_rating)                                       AS star_rating,

    /* dates (we accept yyyy-mm-dd or dd/mm/yyyy) */
    COALESCE(TRY_CONVERT(date, booking_date, 23),  TRY_CONVERT(date, booking_date, 103))   AS booking_date,
    COALESCE(TRY_CONVERT(date, COALESCE(checkin_date,  check_in_date),  23),
             TRY_CONVERT(date, COALESCE(checkin_date,  check_in_date), 103))               AS checkin_date,
    COALESCE(TRY_CONVERT(date, COALESCE(checkout_date, check_out_date), 23),
             TRY_CONVERT(date, COALESCE(checkout_date, check_out_date), 103))              AS checkout_date,

    /* party size */
    TRY_CONVERT(INT, adults)    AS adults,
    TRY_CONVERT(INT, children)  AS children,
    TRY_CONVERT(INT, babies)    AS babies,

    /* rooms & channel */
    NULLIF(LTRIM(RTRIM(COALESCE(room_type_reserved, room_type))), '')            AS room_type_reserved,
    NULLIF(LTRIM(RTRIM(assigned_room_type)), '')                                 AS assigned_room_type,
    NULLIF(LTRIM(RTRIM(
        COALESCE(channel, booking_channel, channel_of_booking, distribution_channel)
    )), '')                                                                       AS channel,

    /* lengths */
    TRY_CONVERT(INT, stays_in_week_nights)    AS stays_in_week_nights,
    TRY_CONVERT(INT, stays_in_weekend_nights) AS stays_in_weekend_nights,
    TRY_CONVERT(INT, nights)                  AS nights_raw,

    /* length_of_stay fallback logic */
    COALESCE(
        TRY_CONVERT(INT, nights),
        TRY_CONVERT(INT, stays_in_week_nights) + TRY_CONVERT(INT, stays_in_weekend_nights),
        CASE WHEN COALESCE(
                    COALESCE(TRY_CONVERT(date, checkin_date, 23),  TRY_CONVERT(date, checkin_date, 103)),
                    COALESCE(TRY_CONVERT(date, check_in_date, 23), TRY_CONVERT(date, check_in_date, 103))
                 ) IS NOT NULL
              AND COALESCE(
                    COALESCE(TRY_CONVERT(date, checkout_date, 23),  TRY_CONVERT(date, checkout_date, 103)),
                    COALESCE(TRY_CONVERT(date, check_out_date, 23), TRY_CONVERT(date, check_out_date, 103))
                 ) IS NOT NULL
             THEN DATEDIFF(DAY,
                COALESCE(TRY_CONVERT(date, COALESCE(checkin_date,  check_in_date),  23),
                         TRY_CONVERT(date, COALESCE(checkin_date,  check_in_date), 103)),
                COALESCE(TRY_CONVERT(date, COALESCE(checkout_date, check_out_date), 23),
                         TRY_CONVERT(date, COALESCE(checkout_date, check_out_date), 103))
             )
        END
    ) AS length_of_stay,

    /* lead time = checkin - booking */
    CASE WHEN COALESCE(
            COALESCE(TRY_CONVERT(date, booking_date, 23),  TRY_CONVERT(date, booking_date, 103)), NULL
         ) IS NOT NULL
       AND COALESCE(
            COALESCE(TRY_CONVERT(date, COALESCE(checkin_date, check_in_date), 23),
                     TRY_CONVERT(date, COALESCE(checkin_date, check_in_date), 103)), NULL
         ) IS NOT NULL
         THEN DATEDIFF(DAY,
            COALESCE(TRY_CONVERT(date, booking_date, 23),  TRY_CONVERT(date, booking_date, 103)),
            COALESCE(TRY_CONVERT(date, COALESCE(checkin_date, check_in_date), 23),
                     TRY_CONVERT(date, COALESCE(checkin_date, check_in_date), 103))
         )
    END AS lead_time,

    /* prices & revenue */
    TRY_CONVERT(DECIMAL(18,2), price_per_night) AS price_per_night_explicit,
    TRY_CONVERT(DECIMAL(18,2), adr)             AS adr,
    TRY_CONVERT(DECIMAL(18,2), total_amount)    AS total_amount,
    TRY_CONVERT(DECIMAL(18,2), selling_price)   AS selling_price,
    TRY_CONVERT(DECIMAL(18,2), booking_value)   AS booking_value,
    TRY_CONVERT(DECIMAL(18,2), costprice)       AS costprice,
    TRY_CONVERT(DECIMAL(18,2), markup)          AS markup,

    /* price_per_night derived */
    COALESCE(
        TRY_CONVERT(DECIMAL(18,2), price_per_night),
        TRY_CONVERT(DECIMAL(18,2), adr),
        CASE WHEN TRY_CONVERT(DECIMAL(18,2), selling_price) IS NOT NULL
               AND NULLIF(
                    COALESCE(
                      TRY_CONVERT(INT, nights),
                      TRY_CONVERT(INT, stays_in_week_nights) + TRY_CONVERT(INT, stays_in_weekend_nights),
                      NULL
                    ), 0) IS NOT NULL
             THEN TRY_CONVERT(DECIMAL(18,2), selling_price) /
                  NULLIF(
                    COALESCE(
                      TRY_CONVERT(INT, nights),
                      TRY_CONVERT(INT, stays_in_week_nights) + TRY_CONVERT(INT, stays_in_weekend_nights)
                    ), 0)
        END
    ) AS price_per_night,

    /* revenue prefer selling_price / total_amount / else ppn * LOS */
    COALESCE(
        TRY_CONVERT(DECIMAL(18,2), selling_price),
        TRY_CONVERT(DECIMAL(18,2), total_amount),
        COALESCE(
            TRY_CONVERT(DECIMAL(18,2), price_per_night),
            TRY_CONVERT(DECIMAL(18,2), adr)
        ) * NULLIF(
              COALESCE(
                TRY_CONVERT(INT, nights),
                TRY_CONVERT(INT, stays_in_week_nights) + TRY_CONVERT(INT, stays_in_weekend_nights),
                length_of_stay
              ), 0)
    ) AS revenue,

    /* cancellation */
    CASE
        WHEN TRY_CONVERT(INT, is_canceled) IN (0,1) THEN TRY_CONVERT(INT, is_canceled)
        WHEN UPPER(LTRIM(RTRIM(COALESCE(booking_status,'')))) IN ('CANCELED','CANCELLED') THEN 1
        WHEN UPPER(LTRIM(RTRIM(COALESCE(booking_status,'')))) IN ('CONFIRMED','CHECKED-IN','CHECKED OUT','NOT CANCELED') THEN 0
    END AS is_canceled,

    /* time dimensions */
    YEAR(COALESCE(TRY_CONVERT(date, booking_date, 23), TRY_CONVERT(date, booking_date, 103)))  AS booking_year,
    MONTH(COALESCE(TRY_CONVERT(date, booking_date, 23), TRY_CONVERT(date, booking_date, 103))) AS booking_month,
    DATENAME(MONTH, COALESCE(TRY_CONVERT(date, booking_date, 23), TRY_CONVERT(date, booking_date, 103))) AS booking_month_name,
    CASE MONTH(COALESCE(TRY_CONVERT(date, booking_date, 23), TRY_CONVERT(date, booking_date, 103)))
        WHEN 12 THEN 'Winter' WHEN 1 THEN 'Winter' WHEN 2 THEN 'Winter'
        WHEN 3 THEN 'Spring' WHEN 4 THEN 'Spring' WHEN 5 THEN 'Spring'
        WHEN 6 THEN 'Summer' WHEN 7 THEN 'Summer' WHEN 8 THEN 'Summer'
        WHEN 9 THEN 'Autumn' WHEN 10 THEN 'Autumn' WHEN 11 THEN 'Autumn'
    END AS season
FROM dbo.Hotel_bookings;
GO

/* Keep only valid stays (non-null dates & LOS>0) for analysis */
IF OBJECT_ID('dbo.vw_bookings_clean','V') IS NOT NULL DROP VIEW dbo.vw_bookings_clean;
GO
CREATE VIEW dbo.vw_bookings_clean AS
SELECT *
FROM dbo.vw_bookings
WHERE checkin_date  IS NOT NULL
  AND checkout_date IS NOT NULL
  AND length_of_stay IS NOT NULL
  AND length_of_stay > 0;
GO
