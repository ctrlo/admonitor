-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Fri Sep 10 07:27:13 2021
-- 
;
SET foreign_key_checks=0;
--
-- Table: `group`
--
CREATE TABLE `group` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;
--
-- Table: `user`
--
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
  `notify_all_ssh` smallint NOT NULL DEFAULT 0,
  `web_enabled` enum('0','1') NOT NULL DEFAULT '0',
  INDEX `user_idx_email` (`email`),
  INDEX `user_idx_username` (`username`),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;
--
-- Table: `alarm_message`
--
CREATE TABLE `alarm_message` (
  `id` integer NOT NULL auto_increment,
  `group_id` integer NOT NULL,
  `message_suffix` text NOT NULL,
  `plugin` varchar(50) NOT NULL,
  INDEX `alarm_message_idx_group_id` (`group_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `alarm_message_fk_group_id` FOREIGN KEY (`group_id`) REFERENCES `group` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB;
--
-- Table: `fingerprint`
--
CREATE TABLE `fingerprint` (
  `id` integer NOT NULL auto_increment,
  `user_id` integer NOT NULL,
  `fingerprint` varchar(64) NOT NULL,
  INDEX `fingerprint_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `fingerprint_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `host`
--
CREATE TABLE `host` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(50) NOT NULL,
  `port` integer NULL,
  `password` varchar(64) NULL,
  `group_id` integer NULL,
  `silenced` smallint NOT NULL DEFAULT 0,
  `collect_agents` smallint NOT NULL DEFAULT 1,
  INDEX `host_idx_group_id` (`group_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `host_fk_group_id` FOREIGN KEY (`group_id`) REFERENCES `group` (`id`)
) ENGINE=InnoDB;
--
-- Table: `host_alarm`
--
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
--
-- Table: `host_checker`
--
CREATE TABLE `host_checker` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(50) NOT NULL,
  `host` integer NOT NULL,
  INDEX `host_checker_idx_host` (`host`),
  PRIMARY KEY (`id`),
  CONSTRAINT `host_checker_fk_host` FOREIGN KEY (`host`) REFERENCES `host` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `statval`
--
CREATE TABLE `statval` (
  `id` integer NOT NULL auto_increment,
  `datetime` datetime NOT NULL,
  `stattype` varchar(50) NOT NULL,
  `host` integer NOT NULL DEFAULT 0,
  `plugin` varchar(50) NOT NULL,
  `decimal` decimal(10, 3) NULL,
  `param` varchar(50) NULL,
  `failcount` integer NULL,
  `string` text NULL,
  INDEX `statval_idx_host` (`host`),
  INDEX `statval_idx_datetime` (`datetime`),
  INDEX `statval_idx_host_datetime` (`host`, `datetime`),
  PRIMARY KEY (`id`),
  CONSTRAINT `statval_fk_host` FOREIGN KEY (`host`) REFERENCES `host` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `user_group`
--
CREATE TABLE `user_group` (
  `id` integer NOT NULL auto_increment,
  `user_id` integer NOT NULL,
  `group_id` integer NOT NULL,
  INDEX `user_group_idx_group_id` (`group_id`),
  INDEX `user_group_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `user_group_fk_group_id` FOREIGN KEY (`group_id`) REFERENCES `group` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `user_group_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `sshlogin`
--
CREATE TABLE `sshlogin` (
  `id` integer NOT NULL auto_increment,
  `host_id` integer NOT NULL,
  `user_id` integer NULL,
  `username` varchar(50) NOT NULL,
  `source_ip` varchar(50) NOT NULL,
  `datetime` datetime NOT NULL,
  `fingerprint` varchar(64) NOT NULL,
  INDEX `sshlogin_idx_host_id` (`host_id`),
  INDEX `sshlogin_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `sshlogin_fk_host_id` FOREIGN KEY (`host_id`) REFERENCES `host` (`id`),
  CONSTRAINT `sshlogin_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`)
) ENGINE=InnoDB;
SET foreign_key_checks=1;
