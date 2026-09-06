USE musix_analytics;

-- Каждый запрос ниже независим и может быть выполнен после файлов
-- 01_create_tables.sql и 02_insert_data.sql.
-- Активный пользователь - пользователь хотя бы с одним прослушиванием.

-- ЗАПРОС 1: Топ-10 треков по количеству прослушиваний.
SELECT
    tr.track_id,
    CONCAT(ar.artist_name, ' - ', tr.track_name) AS track_artist_name,
    COUNT(*) AS listen_count
FROM listens AS l
JOIN tracks AS tr ON tr.track_id = l.track_id
JOIN artists AS ar ON ar.artist_id = tr.artist_id
GROUP BY tr.track_id, ar.artist_name, tr.track_name
ORDER BY listen_count DESC, tr.track_id
LIMIT 10;

-- ЗАПРОС 2: Топ-5 исполнителей по количеству уникальных слушателей.
SELECT
    ar.artist_id,
    ar.artist_name,
    COUNT(DISTINCT l.user_id) AS unique_listeners
FROM listens AS l
JOIN tracks AS tr ON tr.track_id = l.track_id
JOIN artists AS ar ON ar.artist_id = tr.artist_id
GROUP BY ar.artist_id, ar.artist_name
ORDER BY unique_listeners DESC, ar.artist_id
LIMIT 5;

-- ЗАПРОС 3: Среднее число прослушиваний самого популярного исполнителя
-- для каждого пользователя.
WITH listens_by_user_artist AS (
    SELECT
        l.user_id,
        tr.artist_id,
        COUNT(*) AS listen_count
    FROM listens AS l
    JOIN tracks AS tr ON tr.track_id = l.track_id
    GROUP BY l.user_id, tr.artist_id
),
top_artist_listens AS (
    SELECT
        user_id,
        MAX(listen_count) AS top_artist_listen_count
    FROM listens_by_user_artist
    GROUP BY user_id
)
SELECT ROUND(AVG(top_artist_listen_count), 2) AS avg_top_artist_listens
FROM top_artist_listens;

-- ЗАПРОС 4: MAU по календарным месяцам.
SELECT
    DATE_FORMAT(listen_date, '%Y-%m') AS activity_month,
    COUNT(DISTINCT user_id) AS mau
FROM listens
GROUP BY DATE_FORMAT(listen_date, '%Y-%m')
ORDER BY activity_month;

-- ЗАПРОС 5: DAU за январь 2024 года.
SELECT
    DATE(listen_date) AS activity_date,
    COUNT(DISTINCT user_id) AS dau
FROM listens
WHERE listen_date >= '2024-01-01'
  AND listen_date < '2024-02-01'
GROUP BY DATE(listen_date)
ORDER BY activity_date;

-- ЗАПРОС 6: Липкость за январь 2024 года = средний календарный DAU / MAU.
-- Дни без прослушиваний учитываются в знаменателе среднего DAU.
WITH params AS (
    SELECT
        DATE('2024-01-01') AS period_start,
        DATE('2024-02-01') AS period_end
),
monthly_activity AS (
    SELECT
        COUNT(DISTINCT l.user_id) AS mau,
        COUNT(DISTINCT DATE(l.listen_date), l.user_id) AS active_user_days,
        DATEDIFF(p.period_end, p.period_start) AS calendar_days
    FROM listens AS l
    CROSS JOIN params AS p
    WHERE l.listen_date >= p.period_start
      AND l.listen_date < p.period_end
    GROUP BY p.period_start, p.period_end
)
SELECT
    mau,
    ROUND(active_user_days / calendar_days, 2) AS avg_dau,
    ROUND(100.0 * active_user_days / calendar_days / NULLIF(mau, 0), 2)
        AS stickiness_pct
FROM monthly_activity;

-- ЗАПРОС 7: Retention первой недели для зарегистрированных в январе 2024 года.
-- Вернувшимся считается пользователь хотя бы с одним прослушиванием
-- на 7-13-й день после регистрации.
SELECT
    COUNT(DISTINCT u.user_id) AS cohort_size,
    COUNT(DISTINCT CASE
        WHEN l.listen_date >= u.registration_date + INTERVAL 7 DAY
         AND l.listen_date < u.registration_date + INTERVAL 14 DAY
        THEN u.user_id
    END) AS retained_users_week_1,
    ROUND(
        100.0 * COUNT(DISTINCT CASE
            WHEN l.listen_date >= u.registration_date + INTERVAL 7 DAY
             AND l.listen_date < u.registration_date + INTERVAL 14 DAY
            THEN u.user_id
        END) / NULLIF(COUNT(DISTINCT u.user_id), 0),
        2
    ) AS retention_week_1_pct
FROM users AS u
LEFT JOIN listens AS l ON l.user_id = u.user_id
WHERE u.registration_date >= '2024-01-01'
  AND u.registration_date < '2024-02-01';

-- ЗАПРОС 8: Недельный когортный retention по относительным периодам в 7 дней.
-- Период 0 отражает активацию на 0-6-й день и рассчитывается по данным,
-- а не задается равным 100%.
WITH RECURSIVE periods AS (
    SELECT 0 AS period_number
    UNION ALL
    SELECT period_number + 1
    FROM periods
    WHERE period_number < 3
),
user_cohorts AS (
    SELECT
        user_id,
        registration_date,
        DATE_SUB(registration_date, INTERVAL WEEKDAY(registration_date) DAY)
            AS cohort_start
    FROM users
),
cohort_sizes AS (
    SELECT
        cohort_start,
        COUNT(*) AS cohort_size
    FROM user_cohorts
    GROUP BY cohort_start
),
user_activity AS (
    SELECT DISTINCT
        uc.user_id,
        uc.cohort_start,
        FLOOR(DATEDIFF(DATE(l.listen_date), uc.registration_date) / 7)
            AS period_number
    FROM user_cohorts AS uc
    JOIN listens AS l ON l.user_id = uc.user_id
    WHERE l.listen_date >= uc.registration_date
      AND l.listen_date < uc.registration_date + INTERVAL 28 DAY
),
active_users AS (
    SELECT
        cohort_start,
        period_number,
        COUNT(*) AS active_users
    FROM user_activity
    GROUP BY cohort_start, period_number
)
SELECT
    cs.cohort_start,
    p.period_number,
    cs.cohort_size,
    COALESCE(au.active_users, 0) AS active_users,
    ROUND(
        100.0 * COALESCE(au.active_users, 0) / NULLIF(cs.cohort_size, 0),
        2
    ) AS retention_pct
FROM cohort_sizes AS cs
CROSS JOIN periods AS p
LEFT JOIN active_users AS au
    ON au.cohort_start = cs.cohort_start
   AND au.period_number = p.period_number
ORDER BY cs.cohort_start, p.period_number;

-- ЗАПРОС 9: Общее количество прослушиваний.
SELECT COUNT(*) AS total_listens
FROM listens;

-- ЗАПРОС 10: Количество пользователей хотя бы с одним прослушиванием.
SELECT COUNT(DISTINCT user_id) AS active_listeners
FROM listens;

-- ЗАПРОС 11: Зарегистрированные пользователи по типу подписки.
SELECT
    subscription_type,
    COUNT(*) AS registered_users
FROM users
GROUP BY subscription_type
ORDER BY registered_users DESC, subscription_type;
