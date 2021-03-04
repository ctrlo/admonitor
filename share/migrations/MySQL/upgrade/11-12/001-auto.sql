-- Convert schema '/srv/admonitor/share/migrations/_source/deploy/11/001-auto.yml' to '/srv/admonitor/share/migrations/_source/deploy/12/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE fingerprint DROP FOREIGN KEY fingerprint_fk_user_id;

;
ALTER TABLE fingerprint ADD CONSTRAINT fingerprint_fk_user_id FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE host_alarm ADD COLUMN stattype varchar(50) NOT NULL;

;
ALTER TABLE user_group DROP FOREIGN KEY user_group_fk_user_id;

;
ALTER TABLE user_group ADD CONSTRAINT user_group_fk_user_id FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE ON UPDATE CASCADE;

;

COMMIT;

