-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Wed Dec 14 11:02:20 2016
-- 
;
SET foreign_key_checks=0;
--
-- Table: `host`
--
CREATE TABLE `host` (
  `id` integer NOT NULL auto_increment,
  `name` varchar(50) NOT NULL,
  `port` integer NULL,
  `password` varchar(64) NULL,
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
  INDEX `user_idx_email` (`email`),
  INDEX `user_idx_username` (`username`),
  PRIMARY KEY (`id`)
);
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
  INDEX `statval_idx_host` (`host`),
  PRIMARY KEY (`id`),
  CONSTRAINT `statval_fk_host` FOREIGN KEY (`host`) REFERENCES `host` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
SET foreign_key_checks=1;
