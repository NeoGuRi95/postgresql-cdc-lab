-- 3편: Commit시 WAL에서 일어나는 일
-- 글에서 사용한 실습용 PostgreSQL 컨테이너(pg-cdc-lab)의 postgres DB에서 실행합니다.
-- 최초 실행용입니다. 이미 orders 테이블이 있으면 CREATE TABLE에서 오류가 납니다.
-- 프로젝트 폴더에서 실행: docker exec -i pg-cdc-lab psql -X -v ON_ERROR_STOP=1 -U postgres -d postgres < 03-commit-wal-lab.sql
-- WAL 덤프는 SQL이 아닌 pg_waldump 명령이므로 글의 별도 명령을 사용합니다.

-- 1. 커밋 전에 WAL 플러시를 기다리는 설정인지 확인합니다.
SHOW synchronous_commit;
SHOW fsync;

-- 2. 실습 데이터를 만들고 시작 WAL 위치를 기록합니다.
CREATE TABLE orders (id integer PRIMARY KEY, status text);
INSERT INTO orders VALUES (1, 'pending');
CHECKPOINT;
SELECT pg_current_wal_insert_lsn() AS before_lsn;

-- 3. UPDATE 후, COMMIT 전의 트랜잭션 ID와 WAL 위치를 기록합니다.
BEGIN;
UPDATE orders SET status = 'paid' WHERE id = 1;
SELECT pg_current_xact_id() AS xid,
       pg_current_wal_insert_lsn() AS insert_lsn,
       pg_current_wal_flush_lsn() AS flush_lsn;
COMMIT;

-- 4. COMMIT 후 WAL 플러시 위치와 변경 결과를 확인합니다.
SELECT pg_current_wal_flush_lsn() AS after_flush_lsn;
SELECT * FROM orders;

-- 5. 체크포인트 전후의 서버 전체 누적 통계를 비교합니다.
SELECT num_done, buffers_written FROM pg_stat_checkpointer;
CHECKPOINT;
SELECT pg_stat_clear_snapshot();
SELECT num_done, buffers_written FROM pg_stat_checkpointer;
