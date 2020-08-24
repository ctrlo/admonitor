-- Convert schema '/usr/home/tom/checkouts/admonitor/share/migrations/_source/deploy/10/001-auto.yml' to '/usr/home/tom/checkouts/admonitor/share/migrations/_source/deploy/11/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE `alarm_message` DROP FOREIGN KEY `alarm_message_fk_group_id`;

;
ALTER TABLE `alarm_message` ADD COLUMN `plugin` varchar(50) NOT NULL,
                            ADD CONSTRAINT `alarm_message_fk_group_id` FOREIGN KEY (`group_id`) REFERENCES `group` (`id`) ON DELETE CASCADE;

;

COMMIT;

