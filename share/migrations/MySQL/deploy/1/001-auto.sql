-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Mon Aug 24 19:06:53 2015
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
-- Table: `statval`
--
CREATE TABLE `statval` (
  `id` integer NOT NULL auto_increment,
  `datetime` datetime NOT NULL,
  `stattype` varchar(50) NOT NULL,
  `host` integer NOT NULL DEFAULT 0,
  `plugin` varchar(50) NOT NULL,
  `decimal` decimal(10, 2) NOT NULL,
  `param` varchar(50) NULL,
  INDEX `statval_idx_host` (`host`),
  PRIMARY KEY (`id`),
  CONSTRAINT `statval_fk_host` FOREIGN KEY (`host`) REFERENCES `host` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
SET foreign_key_checks=1;
