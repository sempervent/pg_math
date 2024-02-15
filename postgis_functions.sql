--- Postgis functions

-- zonal statistics
--- example usage: SELECT * FROM public.get_zonal_statistics();
CREATE OR REPLACE FUNCTION public.get_zonal_statistics(raster_table text, raster_col text, geom_table text, geom_col text, raster_band integer)
RETURNS TABLE (
  id integer,
  count bigint,
  sum double precision,
  mean double precision,
  stddev double precision,
  min double precision,
  max double precision
) AS $$
BEGIN
  RETURN QUERY EXECUTE format(
    'SELECT
      g.id,
      (stats).count,
      (stats).sum,
      (stats).mean,
      (stats).stddev,
      (stats).min,
      (stats).max
    FROM
      (
        SELECT
          g.id,
          ST_SummaryStatsAgg(r.%I, %L, true) as stats
        FROM
          %I g
          INNER JOIN %I r ON ST_Intersects(g.%I, r.rast)
        GROUP BY
          g.id
      ) as g',
    raster_col, raster_band, geom_table, raster_table, geom_col
  );
END;
$$ LANGUAGE plpgsql;

