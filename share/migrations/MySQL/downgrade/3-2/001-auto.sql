-- Convert schema '/home/abeverley/git/admonitor/share/migrations/_source/deploy/3/001-auto.yml' to '/home/abeverley/git/admonitor/share/migrations/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE statval DROP COLUMN failcount,
                    CHANGE COLUMN `decimal` `decimal` decimal(10, 2) NOT NULL;

;
ALTER TABLE host_checker DROP FOREIGN KEY host_checker_fk_host;

;
DROP TABLE host_checker;

;

COMMIT;

