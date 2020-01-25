-- Convert schema '/srv/admonitor/share/migrations/_source/deploy/7/001-auto.yml' to '/srv/admonitor/share/migrations/_source/deploy/8/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `fingerprint` (
  `id` integer NOT NULL auto_increment,
  `user_id` integer NOT NULL,
  `fingerprint` varchar(64) NOT NULL,
  INDEX `fingerprint_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `fingerprint_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`)
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;
ALTER TABLE sshlogin ADD COLUMN user_id integer NULL,
                     ADD COLUMN fingerprint varchar(64) NOT NULL,
                     ADD INDEX sshlogin_idx_user_id (user_id),
                     ADD CONSTRAINT sshlogin_fk_user_id FOREIGN KEY (user_id) REFERENCES `user` (id);

;
ALTER TABLE user ADD COLUMN notify_all_ssh smallint NOT NULL DEFAULT 0;

;

COMMIT;

