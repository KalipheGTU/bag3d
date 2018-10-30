CREATE OR REPLACE VIEW bagactueel.missing_height AS
SELECT *
FROM bagactueel.bag3d
WHERE
(
"ground-0.00" IS NULL OR 
"ground-0.10" IS NULL OR 
"ground-0.20" IS NULL OR 
"ground-0.30" IS NULL OR 
"ground-0.40" IS NULL OR 
"ground-0.50" IS NULL
) AND ( 
"roof-0.00" IS NULL OR
"roof-0.10" IS NULL OR
"roof-0.25" IS NULL OR
"roof-0.50" IS NULL OR
"roof-0.75" IS NULL OR
"roof-0.90" IS NULL OR
"roof-0.95" IS NULL OR
"roof-0.99" IS NULL
);
COMMENT ON VIEW bagactueel.missing_height IS 'Buildings where any of the ground or roof heights is missing';

CREATE OR REPLACE VIEW bagactueel.bag3d_invalid_height AS
SELECT *
FROM bagactueel.bag3d
WHERE bouwjaar > date_part('YEAR', ahn_file_date);
COMMENT ON VIEW bagactueel.bag3d_invalid_height IS 'The BAG footprints where the building was built after the AHN3 was created';


CREATE OR REPLACE VIEW bagactueel.missing_ground AS
SELECT *
FROM bagactueel.bag3d
WHERE
"ground-0.00" IS NULL OR 
"ground-0.10" IS NULL OR 
"ground-0.20" IS NULL OR 
"ground-0.30" IS NULL OR 
"ground-0.40" IS NULL OR 
"ground-0.50" IS NULL;
COMMENT ON VIEW bagactueel.missing_ground IS 'Buildings where any of the ground heights is missing';


CREATE OR REPLACE VIEW bagactueel.missing_roof AS
SELECT *
FROM bagactueel.bag3d
WHERE
"roof-0.00" IS NULL OR
"roof-0.10" IS NULL OR
"roof-0.25" IS NULL OR
"roof-0.50" IS NULL OR
"roof-0.75" IS NULL OR
"roof-0.90" IS NULL OR
"roof-0.95" IS NULL OR
"roof-0.99" IS NULL;
COMMENT ON VIEW bagactueel.missing_roof IS 'Buildings where any of the roof heights is missing';


CREATE OR REPLACE VIEW bagactueel.bag3d_sample AS
WITH sample AS (
    SELECT *
    FROM bagactueel.bag3d
    TABLESAMPLE BERNOULLI (1)
)
SELECT
FROM sample s,
;

COMMENT ON VIEW bagactueel.bag3d_sample IS 'Random sample (1%) of the 3D BAG, using Bernoulli sampling method';


/* Evaluation */

WITH total AS (
    SELECT
        COUNT(gid) total_cnt
    FROM
        bagactueel.pand3d
),
ground AS (
    SELECT
        COUNT(gid) ground_missing_cnt
    FROM
        bagactueel.pand3d
    WHERE nr_ground_pts = 0
),
roof AS (
    SELECT
        COUNT(gid) roof_missing_cnt
    FROM
        bagactueel.pand3d
    WHERE nr_roof_pts = 0
),
invalid AS (
    SELECT
        COUNT (gid) invalid_height_cnt
    FROM
        bagactueel.pand3d
    WHERE bouwjaar > ahn_file_date
)
INSERT INTO public.bag3d_quality
SELECT
    current_date AS date,
    t.total_cnt,
    (t.total_cnt::float4 - i.invalid_height_cnt::float4) / t.total_cnt::float4 * 100 AS valid_height_pct,
    i.invalid_height_cnt::float4 / t.total_cnt::float4 * 100 AS invalid_height_pct,
    (
        g.ground_missing_cnt::FLOAT4 / t.total_cnt::FLOAT4
    )* 100 AS ground_missing_pct,
    (
        r.roof_missing_cnt::FLOAT4 / t.total_cnt::FLOAT4
    )* 100 AS roof_missing_pct
FROM
    total t,
    ground g,
    roof r,
    invalid i;

   
CREATE TABLE public.bag3d_quality (
date date PRIMARY KEY, 
total_cnt int,
valid_height_pct float4,
invalid_height_pct float4,
ground_missing_pct float4,
roof_missing_pct float4
);

