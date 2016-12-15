-- Convert schema '/home/abeverley/git/admonitor/share/migrations/_source/deploy/2/001-auto.yml' to '/home/abeverley/git/admonitor/share/migrations/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `host_checker` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(50) NOT NULL,
  `host` integer NOT NULL,
  INDEX `host_checker_idx_host` (`host`),
  PRIMARY KEY (`id`),
  CONSTRAINT `host_checker_fk_host` FOREIGN KEY (`host`) REFERENCES `host` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;
ALTER TABLE statval ADD COLUMN failcount integer NULL,
                    CHANGE COLUMN `decimal` `decimal` decimal(10, 3) NULL;

;

COMMIT;

