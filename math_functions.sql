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


-- Function to calculate the z-score
-- @param value integer
-- @param values integer[]
-- @return float
CREATE OR REPLACE FUNCTION z_score(value integer, values integer[])
RETURNS float AS $$
DECLARE
  mean float;
  std_dev float;
BEGIN
    mean := (SELECT avg(value) FROM unnest(values) value);
    std_dev := (SELECT standard_deviation(values));
    RETURN (value - mean) / std_dev;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate the exponential moving average
-- @param alpha float
-- @param values integer[]
-- @return float[]
CREATE OR REPLACE FUNCTION exponential_moving_average(alpha float, values integer[])
RETURNS float[] AS $$
DECLARE
  result float[];
  i integer;
BEGIN
    result[1] := values[1];
    FOR i IN 2..array_length(values, 1) LOOP
        result[i] := alpha * values[i] + (1 - alpha) * result[i - 1];
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate the relative strength index
-- @param window_size integer
-- @param values integer[]
-- @return float[]
CREATE OR REPLACE FUNCTION relative_strength_index(window_size integer, values integer[])
RETURNS float[] AS $$
DECLARE
  result float[];
  i integer;
  gain float;
  loss float;
  avg_gain float;
  avg_loss float;
  rs float;
BEGIN
    result[1] := 0;
    gain := 0;
    loss := 0;
    FOR i IN 2..window_size LOOP
        IF values[i] > values[i - 1] THEN
            gain := gain + (values[i] - values[i - 1]);
        ELSE
            loss := loss + (values[i - 1] - values[i]);
        END IF;
    END LOOP;
    avg_gain := gain / window_size;
    avg_loss := loss / window_size;
    result[window_size] := 100 - (100 / (1 + avg_gain / avg_loss));
    FOR i IN window_size + 1..array_length(values, 1) LOOP
        IF values[i] > values[i - 1] THEN
            gain := (values[i] - values[i - 1]);
            loss := 0;
        ELSE
            gain := 0;
            loss := (values[i - 1] - values[i]);
        END IF;
        avg_gain := (avg_gain * (window_size - 1) + gain) / window_size;
        avg_loss := (avg_loss * (window_size - 1) + loss) / window_size;
        rs := avg_gain / avg_loss;
        result[i] := 100 - (100 / (1 + rs));
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate the median
CREATE OR REPLACE FUNCTION median(values float[])
RETURNS float AS $$
DECLARE
  sorted_values float[];
  n integer;
BEGIN
  sorted_values := array_sort(values);
  n := array_length(sorted_values, 1);
  IF n % 2 = 0 THEN
    RETURN (sorted_values[n / 2] + sorted_values[n / 2 + 1]) / 2;
  ELSE
    RETURN sorted_values[(n + 1) / 2];
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate the mode
CREATE OR REPLACE FUNCTION mode(values integer[])
RETURNS integer AS $$
DECLARE
  mode_value integer;
  max_count integer = 0;
  i integer;
  count integer;
BEGIN
  FOR i IN 1..array_length(values, 1) LOOP
    SELECT count(*) INTO count FROM unnest(values) WHERE value = values[i];
    IF count > max_count THEN
      max_count := count;
      mode_value := values[i];
    END IF;
  END LOOP;
  RETURN mode_value;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate the range
CREATE OR REPLACE FUNCTION range(values integer[])
RETURNS integer AS $$
BEGIN
  RETURN max(values) - min(values);
END;
$$ LANGUAGE plpgsql;

-- Function to calculate the nth percentile
CREATE OR REPLACE FUNCTION percentile(n integer, values float[])
RETURNS float AS $$
DECLARE
  sorted_values float[];
  index float;
BEGIN
  sorted_values := array_sort(values);
  index := n * array_length(sorted_values, 1) / 100.0;
  IF index = floor(index) THEN
    RETURN sorted_values[index];
  ELSE
    RETURN (sorted_values[floor(index)] + sorted_values[ceil(index)]) / 2;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate n number of quantiles
CREATE OR REPLACE FUNCTION quantiles(n integer, values float[])
RETURNS float[] AS $$
DECLARE
  sorted_values float[];
  quantiles float[];
  i integer;
  index float;
BEGIN
    sorted_values := array_sort(values);
    quantiles[1] := sorted_values[1];
    FOR i IN 2..n - 1 LOOP
        index := i * array_length(sorted_values, 1) / n;
        IF index = floor(index) THEN
        quantiles[i] := sorted_values[index + 1];
        ELSE
        quantiles[i] := (sorted_values[floor(index) + 1] + sorted_values[ceil(index)] + 1) / 2;
        END IF;
    END LOOP;
    quantiles[n] := sorted_values[array_length(sorted_values, 1)];
    RETURN quantiles;
    END;
$$ LANGUAGE plpgsql;


-- Function to calculate the covariance
CREATE OR REPLACE FUNCTION covariance(values1 float[], values2 float[])
RETURNS float AS $$
DECLARE
  mean1 float;
  mean2 float;
  sum float;
  i integer;
BEGIN
    mean1 := (SELECT avg(value) FROM unnest(values1) value);
    mean2 := (SELECT avg(value) FROM unnest(values2) value);
    sum := 0;
    FOR i IN 1..array_length(values1, 1) LOOP
        sum := sum + (values1[i] - mean1) * (values2[i] - mean2);
    END LOOP;
    RETURN sum / array_length(values1, 1);
    END;
$$ LANGUAGE plpgsql;


-- Function to calculate the correlation
CREATE OR REPLACE FUNCTION correlation(values1 float[], values2 float[])
RETURNS float AS $$
DECLARE
  std_dev1 float;
  std_dev2 float;
  cov float;
BEGIN
    std_dev1 := (SELECT standard_deviation(values1));
    std_dev2 := (SELECT standard_deviation(values2));
    cov := (SELECT covariance(values1, values2));
    RETURN cov / (std_dev1 * std_dev2);
END;
$$ LANGUAGE plpgsql;