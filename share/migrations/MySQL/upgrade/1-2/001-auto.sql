-- Convert schema '/srv/admonitor/share/migrations/_source/deploy/1/001-auto.yml' to '/srv/admonitor/share/migrations/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `user` (
  `id` integer NOT NULL auto_increment,
  `firstname` text NULL,
  `surname` text NULL,
  `email` varchar(128) NOT NULL,
  `username` varchar(128) NOT NULL,
  `password` varchar(128) NULL,
  `pwchanged` datetime NULL,
  `pw_reset_code` char(32) NULL,
  `lastlogin` datetime NULL,
  INDEX `user_idx_email` (`email`),
  INDEX `user_idx_username` (`username`),
  PRIMARY KEY (`id`)
);

;
SET foreign_key_checks=1;

;

COMMIT;

