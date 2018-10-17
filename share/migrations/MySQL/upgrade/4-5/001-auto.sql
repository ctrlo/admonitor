-- Convert schema '/srv/admonitor/share/migrations/_source/deploy/4/001-auto.yml' to '/srv/admonitor/share/migrations/_source/deploy/5/001-auto.yml':;

;
BEGIN;

;
SET foreign_key_checks=0;

;
CREATE TABLE `sshlogin` (
  `id` integer NOT NULL auto_increment,
  `host_id` integer NOT NULL,
  `username` varchar(50) NOT NULL,
  `source_ip` varchar(50) NOT NULL,
  `datetime` datetime NOT NULL,
  INDEX `sshlogin_idx_host_id` (`host_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `sshlogin_fk_host_id` FOREIGN KEY (`host_id`) REFERENCES `host` (`id`)
) ENGINE=InnoDB;

;
SET foreign_key_checks=1;

;

COMMIT;

