DELIMITER $$

CREATE PROCEDURE kill_stale_procs (IN timeout INT)
BEGIN
  DECLARE finished INTEGER DEFAULT 0;
  DECLARE pid INTEGER;
  DECLARE cur CURSOR FOR SELECT id FROM information_schema.processlist WHERE state='Sleep' AND time > timeout;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;

  OPEN cur;

  REPEAT
    FETCH cur INTO pid;
    IF NOT finished THEN
      KILL pid;
    END IF;
  UNTIL finished END REPEAT;
END$$
