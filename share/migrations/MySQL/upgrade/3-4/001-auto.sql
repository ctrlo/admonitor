-- Convert schema '/srv/admonitor/share/migrations/_source/deploy/3/001-auto.yml' to '/srv/admonitor/share/migrations/_source/deploy/4/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `group` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

;
CREATE TABLE `user_group` (
  `id` integer NOT NULL auto_increment,
  `user_id` integer NOT NULL,
  `group_id` integer NOT NULL,
  INDEX `user_group_idx_group_id` (`group_id`),
  INDEX `user_group_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `user_group_fk_group_id` FOREIGN KEY (`group_id`) REFERENCES `group` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `user_group_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`)
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;
ALTER TABLE host ADD COLUMN group_id integer NULL,
                 ADD INDEX host_idx_group_id (group_id),
                 ADD CONSTRAINT host_fk_group_id FOREIGN KEY (group_id) REFERENCES `group` (id);

;
ALTER TABLE user ENGINE=InnoDB;

;

COMMIT;

