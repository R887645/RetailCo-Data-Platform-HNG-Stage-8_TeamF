-- dim_date.sql
-- Business justification: date dimension required by all four fact
-- tables for time-based analysis. Covers 3 years 
-- Includes Nigerian public holidays.
-- date_key format is YYYYMMDD as integer for fast joins.

with date_spine as (
    select
        generate_series(
            '2023-01-01'::date,
            '2025-12-31'::date,
            '1 day'::interval
        )::date as full_date
),

nigerian_holidays as (
    select unnest(array[
        '2023-01-01'::date, '2023-04-07', '2023-04-10',
        '2023-05-01', '2023-06-12', '2023-06-28', '2023-06-29',
        '2023-09-27', '2023-10-01', '2023-12-25', '2023-12-26',
        '2024-01-01', '2024-03-29', '2024-04-01',
        '2024-05-01', '2024-06-12', '2024-06-16', '2024-06-17',
        '2024-09-15', '2024-09-16', '2024-10-01',
        '2024-12-25', '2024-12-26',
        '2025-01-01', '2025-03-31', '2025-04-18', '2025-04-21',
        '2025-05-01', '2025-06-06', '2025-06-12',
        '2025-09-05', '2025-10-01', '2025-12-25', '2025-12-26'
    ]) as holiday_date
),

final as (
    select
        to_char(d.full_date, 'YYYYMMDD')::int      as date_key,
        d.full_date                                 as full_date,
        extract(year from d.full_date)::int         as year,
        extract(quarter from d.full_date)::int      as quarter,
        extract(month from d.full_date)::int        as month,
        to_char(d.full_date, 'Month')               as month_name,
        extract(week from d.full_date)::int         as week,
        extract(day from d.full_date)::int          as day,
        extract(dow from d.full_date)::int          as day_of_week,
        to_char(d.full_date, 'Day')                 as day_name,
        case
            when extract(dow from d.full_date) in (0, 6)
            then true else false
        end                                         as is_weekend,
        case
            when h.holiday_date is not null
            then true else false
        end                                         as is_public_holiday
    from date_spine d
    left join nigerian_holidays h
        on d.full_date = h.holiday_date
)

select * from final