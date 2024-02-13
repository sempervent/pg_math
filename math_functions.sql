--- Function to calculate a moving average
--- @param window_size integer
--- @param values integer[]
--- @return integer[]
CREATE OR REPLACE FUNCTION moving_average(window_size integer, values integer[])
RETURNS float[] AS $$
DECLARE
  result integer[];
  i integer;
  j integer;
  sum integer;
BEGIN
    FOR i IN 1..array_length(values, 1) - window_size + 1 LOOP
        sum := 0;
        FOR j IN 0..window_size - 1 LOOP
        sum := sum + values[i + j];
        END LOOP;
        result[i] := sum / window_size;
    END LOOP;
    RETURN result;
    END;
$$ LANGUAGE plpgsql;

-- Function to calculate the standard deviation
-- @param values integer[]
-- @return float
CREATE OR REPLACE FUNCTION standard_deviation(values integer[])
RETURNS float AS $$
DECLARE
  sum integer;
  mean float;
  variance float;
  i integer;
BEGIN
    sum := 0;
    FOR i IN 1..array_length(values, 1) LOOP
        sum := sum + values[i];
    END LOOP;
    mean := sum / array_length(values, 1);
    sum := 0;
    FOR i IN 1..array_length(values, 1) LOOP
        sum := sum + (values[i] - mean) * (values[i] - mean);
    END LOOP;
    variance := sum / array_length(values, 1);
    RETURN sqrt(variance);
END;
$$ LANGUAGE plpgsql;


