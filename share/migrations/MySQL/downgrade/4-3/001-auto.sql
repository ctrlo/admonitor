-- Convert schema '/srv/admonitor/share/migrations/_source/deploy/4/001-auto.yml' to '/srv/admonitor/share/migrations/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE host DROP FOREIGN KEY host_fk_group_id,
                 DROP INDEX host_idx_group_id,
                 DROP COLUMN group_id;

;
ALTER TABLE user;

;
ALTER TABLE user_group DROP FOREIGN KEY user_group_fk_group_id,
                       DROP FOREIGN KEY user_group_fk_user_id;

;
DROP TABLE `group`;

;
DROP TABLE user_group;

;

COMMIT;

