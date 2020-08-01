-- Convert schema '/usr/home/tom/checkouts/admonitor/share/migrations/_source/deploy/8/001-auto.yml' to '/usr/home/tom/checkouts/admonitor/share/migrations/_source/deploy/9/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `host_alarm` (
  `id` integer NOT NULL auto_increment,
  `stattype` varchar(50) NOT NULL,
  `host` integer NOT NULL DEFAULT 0,
  `plugin` varchar(50) NOT NULL,
  `decimal` decimal(10, 3) NOT NULL,
  INDEX `host_alarm_idx_host` (`host`),
  PRIMARY KEY (`id`),
  CONSTRAINT `host_alarm_fk_host` FOREIGN KEY (`host`) REFERENCES `host` (`id`)
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

