/* 1. Obtener la lista de usuarios (name, handle, email) que están activas (enabled) 
y no tienen imagen de perfil, ordenados alfabéticamente por nombre. */

SELECT name, handle, email
FROM users
WHERE enabled
AND image IS NULL
ORDER BY name;

/* 2. Obtener la lista de usuarios (name, handle) que están activos, 
saben elixir al menos en un nivel competent y además saben aws en cualquier nivel. 
(Los niveles de competencia son, en orden: novice, advanced_beginner, competent, proficient, expert) */

SELECT name, handle
FROM users
INNER JOIN (
    SELECT user_id FROM user_skills
    WHERE skill_id = (SELECT id FROM skills WHERE name = 'Elixir')
    AND level IN ('competent', 'proficient', 'expert')
) AS elixir_skills
ON users.id = elixir_skills.user_id
INNER JOIN (
    SELECT user_id FROM user_skills
    WHERE skill_id = (SELECT id FROM skills WHERE name = 'AWS')
) AS aws_skills
ON users.id = aws_skills.user_id
WHERE enabled;

/* 3. Obtener la lista de los 10 usuarios activos (name, handle) que son los que tienen menos skills registrados, 
ordenados de menor a mayor. Ejemplo:
name, handle, email, count_skills
Agustín Ramos, @MachinesAreUs, agustin@bunsan.io, 1
Amir Orbe, @AmirOrbe, amir.orbe@bunsan.io, 2
Juan Galicia, @ga_c, juan.galicia@bunsan.io, 4
... */

SELECT users.name, handle, COUNT(*) AS num_skils
FROM users 
INNER JOIN user_skills
ON users.id = user_skills.user_id
WHERE enabled
GROUP BY users.name, handle
ORDER BY num_skils
LIMIT 10;

/* 4. En base a las asignaciones vigentes, 
calcular la fecha en la que al menos la mitad de los usuarios activos ya no tienen trabajo asignado. */

SELECT MIN(end_date) AS end_date FROM(
    SELECT end_date, COUNT(*) total_users
    FROM assignments
    WHERE end_date > current_date
    GROUP BY end_date
) AS t
WHERE total_users >= (SELECT COUNT(users.id)/2 FROM "users" WHERE enabled) ;

/* 5. En base a las asignaciones vigentes en marzo y considerando que cada día laborable (lun-vie) es de 8 hrs, 
calcular el total de horas trabajadas durante marzo por todos los usuarios. */

SELECT SUM(work_days) AS total_work_days, SUM(work_days)*8 AS total_work_hours
    FROM (
        SELECT count(*) AS work_days
        FROM(
            SELECT id,
                CASE
                    WHEN start_date < '2022-03-01' THEN '2022-03-01'
                    ELSE start_date
                END AS start_,
                CASE
                    WHEN end_date > '2022-03-31' THEN '2022-03-31'
                    ELSE end_date
                END AS end_
            FROM assignments
            WHERE EXTRACT(YEAR FROM start_date) = EXTRACT(YEAR FROM CURRENT_DATE)
            AND EXTRACT(MONTH FROM start_date) <= 3
            AND EXTRACT(MONTH FROM end_date) >= 3
        ) AS vigent_march
        CROSS JOIN GENERATE_SERIES(start_, end_ ,interval '1 day') gs(dt)
        WHERE EXTRACT (isodow FROM dt) < 6
        GROUP BY id, start_, end_
        ORDER BY work_days
    ) AS table_work_days;

