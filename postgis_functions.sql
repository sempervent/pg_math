--- Postgis functions

-- zonal statistics
--- example usage: SELECT * FROM public.get_zonal_statistics();
CREATE OR REPLACE FUNCTION public.get_zonal_statistics(
    raster_table text,
    raster_col text,
    geom_table text,
    geom_col text,
    raster_band integer := 1
)
RETURNS TABLE (
  id integer,
  count bigint,
  sum double precision,
  mean double precision,
  stddev double precision,
  min double precision,
  max double precision,
  median double precision,
  q1 double precision,
  q3 double precision,
  q90 double precision,
  q95 double precision,
  q99 double precision
) AS $$
DECLARE
  pixel_values float[];
BEGIN
  RETURN QUERY EXECUTE format(
    'WITH stats AS (
        SELECT
          g.id,
          ST_SummaryStatsAgg(r.%I, %L, true) as summary_stats,
          ST_DumpValues(r.%I, %L) as pixel_values
        FROM
          %I g
          INNER JOIN %I r ON ST_Intersects(g.%I, r.rast)
        GROUP BY
          g.id
      )
      SELECT
        id,
        (summary_stats).count,
        (summary_stats).sum,
        (summary_stats).mean,
        (summary_stats).stddev,
        (summary_stats).min,
        (summary_stats).max,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY unnest(pixel_values)) as median,
        percentile_cont(0.25) WITHIN GROUP (ORDER BY unnest(pixel_values)) as q1,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY unnest(pixel_values)) as q3,
        percentile_cont(0.9) WITHIN GROUP (ORDER BY unnest(pixel_values)) as q90,
        percentile_cont(0.95) WITHIN GROUP (ORDER BY unnest(pixel_values)) as q95,
        percentile_cont(0.99) WITHIN GROUP (ORDER BY unnest(pixel_values)) as q99
      FROM stats',
    raster_col, raster_band, raster_col, raster_band, geom_table, raster_table, geom_col
  );
END;
$$ LANGUAGE plpgsql;

