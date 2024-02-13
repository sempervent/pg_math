--- Function to calculate a moving average
--- @param window_size integer
--- @param values integer[]
--- @return integer[]
CREATE OR REPLACE FUNCTION public.moving_average(window_size integer, values integer[])
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
CREATE OR REPLACE FUNCTION public.standard_deviation(values integer[])
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
CREATE OR REPLACE FUNCTION public.z_score(value integer, values integer[])
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
CREATE OR REPLACE FUNCTION public.exponential_moving_average(alpha float, values integer[])
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
CREATE OR REPLACE FUNCTION public.relative_strength_index(window_size integer, values integer[])
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
CREATE OR REPLACE FUNCTION public.median(values float[])
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
CREATE OR REPLACE FUNCTION public.mode(values integer[])
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
CREATE OR REPLACE FUNCTION public.range(values integer[])
RETURNS integer AS $$
BEGIN
  RETURN max(values) - min(values);
END;
$$ LANGUAGE plpgsql;

-- Function to calculate the nth percentile
CREATE OR REPLACE FUNCTION public.percentile(n integer, values float[])
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
CREATE OR REPLACE FUNCTION public.quantiles(n integer, values float[])
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
CREATE OR REPLACE FUNCTION public.covariance(values1 float[], values2 float[])
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
CREATE OR REPLACE FUNCTION public.correlation(values1 float[], values2 float[])
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

--- Function to calculate the simple linear regression
--- @param x float[]
--- @param y float[]
--- @return float[]
CREATE OR REPLACE FUNCTION public.simple_linear_regression(x float[], y float[])
RETURNS float[] AS $$
DECLARE
  mean_x float;
  mean_y float;
  std_dev_x float;
  std_dev_y float;
  cov float;
  slope float;
  intercept float;
BEGIN
    mean_x := (SELECT avg(value) FROM unnest(x) value);
    mean_y := (SELECT avg(value) FROM unnest(y) value);
    std_dev_x := (SELECT standard_deviation(x));
    std_dev_y := (SELECT standard_deviation(y));
    cov := (SELECT covariance(x, y));
    slope := cov / (std_dev_x * std_dev_x);
    intercept := mean_y - slope * mean_x;
    RETURN ARRAY[slope, intercept];
END;
$$ LANGUAGE plpgsql;

-- Function to calculate the variance
CREATE OR REPLACE FUNCTION public.variance(values float[])
RETURNS float AS $$
DECLARE
  mean float;
  sum float;
  i integer;
BEGIN
    mean := (SELECT avg(value) FROM unnest(values) value);
    sum := 0;
    FOR i IN 1..array_length(values, 1) LOOP
        sum := sum + (values[i] - mean) * (values[i] - mean);
    END LOOP;
    RETURN sum / array_length(values, 1);
END;
$$ LANGUAGE plpgsql;

-- Function to calculate the skewness
CREATE OR REPLACE FUNCTION public.skewness(values float[])
RETURNS float AS $$
DECLARE
  mean float;
  std_dev float;
  sum float;
  i integer;
BEGIN
    mean := (SELECT avg(value) FROM unnest(values) value);
    std_dev := (SELECT standard_deviation(values));
    sum := 0;
    FOR i IN 1..array_length(values, 1) LOOP
        sum := sum + ((values[i] - mean) / std_dev) ^ 3;
    END LOOP;
    RETURN sum / array_length(values, 1);
END;
$$ LANGUAGE plpgsql;

-- Function to calculate the kurtosis
CREATE OR REPLACE FUNCTION public.kurtosis(values float[])
RETURNS float AS $$
DECLARE
  mean float;
  std_dev float;
  sum float;
  i integer;
BEGIN
    mean := (SELECT avg(value) FROM unnest(values) value);
    std_dev := (SELECT standard_deviation(values));
    sum := 0;
    FOR i IN 1..array_length(values, 1) LOOP
        sum := sum + ((values[i] - mean) / std_dev) ^ 4;
    END LOOP;
    RETURN sum / array_length(values, 1) - 3;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate the root mean square
CREATE OR REPLACE FUNCTION public.root_mean_square(values float[])
RETURNS float AS $$
DECLARE
  sum float;
  i integer;
BEGIN
    sum := 0;
    FOR i IN 1..array_length(values, 1) LOOP
        sum := sum + values[i] * values[i];
    END LOOP;
    RETURN sqrt(sum / array_length(values, 1));
END;
$$ LANGUAGE plpgsql;

-- Function to calculate the geometric mean
CREATE OR REPLACE FUNCTION public.geometric_mean(values float[])
RETURNS float AS $$
DECLARE
  product float = 1;
  i integer;
BEGIN
    FOR i IN 1..array_length(values, 1) LOOP
        product := product * values[i];
    END LOOP;
    RETURN exp(ln(product) / array_length(values, 1));
END;
$$ LANGUAGE plpgsql;

-- Function to calculate the harmonic mean
CREATE OR REPLACE FUNCTION public.harmonic_mean(values float[])
RETURNS float AS $$
DECLARE
  sum float = 0;
  i integer;
BEGIN
    FOR i IN 1..array_length(values, 1) LOOP
        sum := sum + (1 / values[i]);
    END LOOP;
    RETURN array_length(values, 1) / sum;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate the weighted mean
CREATE OR REPLACE FUNCTION public.weighted_mean(values float[], weights float[])
RETURNS float AS $$
DECLARE
  sum float = 0;
  sum_weights float = 0;
  i integer;
BEGIN
    FOR i IN 1..array_length(values, 1) LOOP
        sum := sum + values[i] * weights[i];
        sum_weights := sum_weights + weights[i];
    END LOOP;
    RETURN sum / sum_weights;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate the interquartile range
CREATE OR REPLACE FUNCTION public.interquartile_range(values float[])
RETURNS float AS $$
DECLARE
  q1 float;
  q3 float;
BEGIN
    q1 := percentile(25, values);
    q3 := percentile(75, values);
    RETURN q3 - q1;
END;
$$ LANGUAGE plpgsql;


-- Function to calculate the factorial
CREATE OR REPLACE FUNCTION public.factorial(n integer)
RETURNS integer AS $$
BEGIN
  IF n = 0 THEN
    RETURN 1;
  ELSE
    RETURN n * public.factorial(n - 1);
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate the combination
CREATE OR REPLACE FUNCTION public.combination(n integer, k integer)
RETURNS integer AS $$
BEGIN
  RETURN public.factorial(n) / (public.factorial(k) * public.factorial(n - k));
END;
$$ LANGUAGE plpgsql;

-- Function to calculate the permutation
CREATE OR REPLACE FUNCTION public.permutation(n integer, k integer)
RETURNS integer AS $$
BEGIN
  RETURN public.factorial(n) / public.factorial(n - k);
END;
$$ LANGUAGE plpgsql;

--- function to calculate the mean absolute deviation
--- @param values float[]
--- @return float
CREATE OR REPLACE FUNCTION public.mean_absolute_deviation(values float[])
RETURNS float AS $$
DECLARE
  mean float;
  sum float;
  i integer;
BEGIN
    mean := (SELECT avg(value) FROM unnest(values) value);
    sum := 0;
    FOR i IN 1..array_length(values, 1) LOOP
        sum := sum + abs(values[i] - mean);
    END LOOP;
    RETURN sum / array_length(values, 1);
END;
$$ LANGUAGE plpgsql;
