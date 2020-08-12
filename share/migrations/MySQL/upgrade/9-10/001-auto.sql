-- Convert schema '/usr/home/tom/checkouts/admonitor/share/migrations/_source/deploy/9/001-auto.yml' to '/usr/home/tom/checkouts/admonitor/share/migrations/_source/deploy/10/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `alarm_message` (
  `id` integer NOT NULL auto_increment,
  `group_id` integer NOT NULL,
  `message_suffix` text NOT NULL,
  INDEX `alarm_message_idx_group_id` (`group_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `alarm_message_fk_group_id` FOREIGN KEY (`group_id`) REFERENCES `group` (`id`)
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;
ALTER TABLE `user` ADD COLUMN `web_enabled` enum('0','1') NOT NULL DEFAULT '0';

;

COMMIT;

