/* 1. Obtener la lista de usuarios (name, handle, email) que están activas (enabled) 
y no tienen imagen de perfil, ordenados alfabéticamente por nombre. */

SELECT name, handle, email
FROM "users"
WHERE enabled = TRUE
AND image IS NULL
ORDER BY name ASC;

/* 2. Obtener la lista de usuarios (name, handle) que están activos, 
saben elixir al menos en un nivel competent y además saben aws en cualquier nivel. 
(Los niveles de competencia son, en orden: novice, advanced_beginner, competent, proficient, expert) */

SELECT name, handle
FROM "users" 
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
WHERE enabled = TRUE;

/* 3. Obtener la lista de los 10 usuarios activos (name, handle) que son los que tienen menos skills registrados, 
ordenados de menor a mayor. Ejemplo:
name, handle, email, count_skills
Agustín Ramos, @MachinesAreUs, agustin@bunsan.io, 1
Amir Orbe, @AmirOrbe, amir.orbe@bunsan.io, 2
Juan Galicia, @ga_c, juan.galicia@bunsan.io, 4
... */

SELECT users.name, handle, COUNT(*) AS num_skils
FROM "users" 
INNER JOIN user_skills
ON users.id = user_skills.user_id
GROUP BY users.name, handle
ORDER BY num_skils ASC
LIMIT 10;

/* 4. En base a las asignaciones vigentes, 
calcular la fecha en la que al menos la mitad de los usuarios activos ya no tienen trabajo asignado. */

SELECT MIN(end_date) AS end_date FROM(
    SELECT end_date, COUNT(*) total_users
    FROM "assignments"
    WHERE end_date > current_date
    GROUP BY end_date
) AS t
WHERE total_users >= (SELECT COUNT(users.id)/2 FROM "users" WHERE enabled = TRUE) ;

/* 5. En base a las asignaciones vigentes en marzo y considerando que cada día laborable (lun-vie) es de 8 hrs, 
calcular el total de horas trabajadas durante marzo por todos los usuarios. */

SELECT start_date, end_date,((end_date - start_date) - ((end_date - start_date)/7)*2) AS avalible_days, ((end_date - start_date) - ((end_date - start_date)/7)*2)*8 AS work_hours
FROM assignments
WHERE EXTRACT(YEAR FROM start_date) = EXTRACT(YEAR FROM current_date)
AND EXTRACT(MONTH FROM start_date) <= 3
AND EXTRACT(MONTH FROM end_date) >= 3;

