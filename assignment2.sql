-- 1b)
SELECT Company.cname, W.pid, W.salary
FROM Company, worksFor W, Knows, (SELECT pid FROM personSkill WHERE skill = 'Operating Systems') OS
WHERE Company.cname = W.cname
  AND W.pid = Knows.pid1
  AND Knows.pid2 = OS.pid
  AND W.salary = (SELECT MIN(W2.salary) FROM worksFor W2 WHERE W2.cname = Company.cname)
ORDER BY Company.cname, W.pid;

-- 2b)
SELECT P.pname, W.salary, P.city
FROM Person P
JOIN worksFor W ON P.pid = W.pid
LEFT JOIN (
    SELECT DISTINCT P2.pid, P2.city
    FROM Person P2
    JOIN personSkill PS ON P2.pid = PS.pid
    WHERE PS.skill = 'Networks'
) NetworkCities ON P.city = NetworkCities.city AND P.pid = NetworkCities.pid
WHERE NetworkCities.pid IS NULL
AND W.salary = (
    SELECT MAX(W2.salary)
    FROM worksFor W2
    WHERE W2.cname = W.cname
)
ORDER BY P.pname;


-- 3b)
SELECT DISTINCT W1.cname AS c1, W2.cname AS c2
FROM worksFor W1
JOIN worksFor W2 ON W1.cname < W2.cname
LEFT JOIN Person P1 ON P1.pid = W1.pid AND P1.city = 'Chicago'
LEFT JOIN Person P2 ON P2.pid = W2.pid AND P2.city = 'Chicago'
WHERE P1.pid IS NULL AND P2.pid IS NULL
ORDER BY c1, c2;

-- 12)
CREATE VIEW CompanyKnownPerson AS
SELECT DISTINCT W1.pid AS known_person
FROM worksFor W1
JOIN Knows K1 ON W1.pid = K1.pid1
LEFT JOIN Knows K2 ON K1.pid2 = K2.pid2 AND K1.pid1 <> K2.pid1
LEFT JOIN worksFor W2 ON K1.pid2 = W2.pid AND W1.cname = W2.cname AND W1.salary > W2.salary
WHERE K2.pid2 IS NULL AND W2.pid IS NULL;
-- Test your view
SELECT * FROM CompanyKnownPerson;

-- 13)
DELIMITER //
CREATE PROCEDURE SkillOnlyOnePerson(IN skill1 TEXT)
BEGIN
    -- Create a temporary table to store the result
    CREATE TEMPORARY TABLE TempSkillOnlyOnePerson AS
    SELECT PS1.pid AS pid1, PS2.pid AS pid2
    FROM personSkill PS1
    JOIN personSkill PS2 ON PS1.pid <> PS2.pid
    LEFT JOIN personSkill PS3 ON PS3.pid = PS2.pid AND PS3.skill = skill1
    WHERE PS1.skill = skill1 AND PS3.pid IS NULL;

    -- Query the temporary table
    SELECT * FROM TempSkillOnlyOnePerson;
    -- Drop the temporary table
    DROP TEMPORARY TABLE TempSkillOnlyOnePerson;
END //
DELIMITER ;
-- Call the stored procedure to get the result for 'WebDevelopment'
CALL SkillOnlyOnePerson('WebDevelopment');

-- 14)
-- Drop the existing stored procedure if it exists
DROP PROCEDURE RecursiveSameGeneration;
-- Create a temporary table to store the intermediate results
CREATE TEMPORARY TABLE TempSameGeneration AS
SELECT parent, child
FROM PC;
-- Create a stored procedure for recursive processing
DELIMITER //
CREATE PROCEDURE RecursiveSameGeneration()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    REPEAT
        -- Insert the next generation into the temporary table
        INSERT IGNORE INTO TempSameGeneration
        SELECT PC.parent, PC.child
        FROM PC
        JOIN TempSameGeneration SG ON PC.child = SG.parent;
        -- Check if no new rows were inserted
        SET done = ROW_COUNT() = 0;
    UNTIL done END REPEAT;
END //
DELIMITER ;
CALL RecursiveSameGeneration ();
-- Query the temporary table
SELECT * FROM TempSameGeneration;
-- Drop the temporary table
DROP TEMPORARY TABLE TempSameGeneration;

-- 15)
DROP PROCEDURE RecursiveInheritance;
-- Create a temporary table to store the intermediate results
CREATE TEMPORARY TABLE TempInheritance AS
SELECT child_id AS m, gold_accumulated AS p
FROM Hierarchy
WHERE parent_id IS NULL;
-- Create a stored procedure for recursive processing
DELIMITER //
CREATE PROCEDURE RecursiveInheritance()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    REPEAT
        -- Insert the next generation into the temporary table
        INSERT IGNORE INTO TempInheritance
        SELECT H2.child_id AS m, H1.p + H2.gold_accumulated AS p
        FROM TempInheritance H1
        JOIN Hierarchy H2 ON H1.m = H2.parent_id;
        -- Check if no new rows were inserted
        SET done = ROW_COUNT() = 0;
    UNTIL done END REPEAT;
END //
DELIMITER ; 
CALL RecursiveInheritance();
-- Query the temporary table
SELECT * FROM TempInheritance;
-- Drop the temporary table
DROP TEMPORARY TABLE TempInheritance;