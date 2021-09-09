-- Deploy penhas:0016-tweet_depth to pg
-- requires: 0015-cliente_eh_admin

BEGIN;

alter table tweets add column tweet_depth smallint;


update tweets me
set tweet_depth = x.depth
from (
    WITH RECURSIVE nodes_cte(id, original_parent_id, depth, path) AS (
     SELECT tn.id, tn.original_parent_id, 1::INT AS depth, tn.id::TEXT AS path
     FROM tweets AS tn
     WHERE tn.original_parent_id IS NULL
    UNION ALL
     SELECT c.id, c.original_parent_id, p.depth + 1 AS depth,
            (p.path || '->' || c.id::TEXT)
     FROM nodes_cte AS p, tweets AS c
     WHERE c.original_parent_id = p.id
    )
    SELECT * FROM nodes_cte AS n ORDER BY n.id ASC
) x
where me.id = x.id;

-- orphan tweets will be left as -1
update tweets set tweet_depth = -1 where tweet_depth is null;
alter table tweets alter column tweet_depth set not null;
alter table tweets alter column tweet_depth set default 1;

COMMIT;
