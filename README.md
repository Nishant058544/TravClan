Hotel Bookings – SQL + Power BI

Purpose: Analyze hotel booking data to understand cancellation behavior and key business drivers using SQL Server for data prep/EDA and Power BI for visuals.

What I did

Imported CSV → built typed view and a clean view (valid check-in/out, LOS > 0).

Derived fields: length_of_stay, lead_time, revenue, month keys.

Created summary tables for month, channel, room × star, lead-time bins.

Ran a chi-square test for cancellation vs channel.

Built a compact Power BI dashboard (4 charts + KPI).

Results (clean stays)

Overall cancel rate: 4.18% (24,532 bookings; 1,025 cancels).

Channels: Web/Android/iOS show similar cancel rates (χ² → not significant).

Room & star: Standard (3★–4★) drives most volume and absolute cancels; premium rooms cancel less.

Lead time: Cancellation rate flat (~4–5%) across 0–60+ days; “Z:Unknown” is data-quality (missing dates).
