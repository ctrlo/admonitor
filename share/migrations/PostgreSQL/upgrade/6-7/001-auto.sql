-- Convert schema '/srv/admonitor/share/migrations/_source/deploy/6/001-auto.yml' to '/srv/admonitor/share/migrations/_source/deploy/7/001-auto.yml':;

;
BEGIN;

;
CREATE INDEX statval_idx_datetime on statval (datetime);

;
CREATE INDEX statval_idx_host_datetime on statval (host, datetime);

;

COMMIT;

