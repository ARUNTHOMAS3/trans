BEGIN;

ALTER TABLE public.storage_locations
ADD COLUMN IF NOT EXISTS storage_type character varying(255);

UPDATE public.storage_locations
SET storage_type = CASE
  WHEN location_name IN ('Freezer', 'Cold / Fridge', 'Cool', 'Room Temp', 'Normal Temp', 'Dry Place', 'Dark Place')
    THEN location_name
  WHEN display_text = 'Store in a Freezer (-20°C to -10°C)' THEN 'Freezer'
  WHEN display_text = 'Store in a Refrigerator (2°C to 8°C)' THEN 'Cold / Fridge'
  WHEN display_text = 'Store in a Cool Place (8°C to 25°C)' THEN 'Cool'
  WHEN display_text = 'Store below 25°C' THEN 'Room Temp'
  WHEN display_text = 'Store below 30°C' THEN 'Normal Temp'
  WHEN display_text = 'Store in a Dry Place' THEN 'Dry Place'
  WHEN display_text = 'Protect from Light' THEN 'Dark Place'
  WHEN location_name = 'Store below 25°C' THEN 'Room Temp'
  WHEN location_name = 'Store below 30°C' THEN 'Normal Temp'
  ELSE COALESCE(storage_type, location_name)
END
WHERE storage_type IS NULL
   OR storage_type = '';

UPDATE public.storage_locations
SET display_text = CASE
  WHEN storage_type = 'Freezer' THEN 'Store in a Freezer (-20°C to -10°C)'
  WHEN storage_type = 'Cold / Fridge' THEN 'Store in a Refrigerator (2°C to 8°C)'
  WHEN storage_type = 'Cool' THEN 'Store in a Cool Place (8°C to 25°C)'
  WHEN storage_type = 'Room Temp' THEN 'Store below 25°C'
  WHEN storage_type = 'Normal Temp' THEN 'Store below 30°C'
  WHEN storage_type = 'Dry Place' THEN 'Store in a Dry Place'
  WHEN storage_type = 'Dark Place' THEN 'Protect from Light'
  ELSE display_text
END
WHERE storage_type IN (
  'Freezer',
  'Cold / Fridge',
  'Cool',
  'Room Temp',
  'Normal Temp',
  'Dry Place',
  'Dark Place'
);

UPDATE public.storage_locations
SET temperature_range = CASE
  WHEN storage_type = 'Freezer' THEN '-20°C to -10°C'
  WHEN storage_type = 'Cold / Fridge' THEN '2°C to 8°C'
  WHEN storage_type = 'Cool' THEN '8°C to 25°C'
  WHEN storage_type = 'Room Temp' THEN 'Up to 25°C'
  WHEN storage_type = 'Normal Temp' THEN 'Up to 30°C'
  WHEN storage_type = 'Dry Place' THEN 'Low Humidity'
  WHEN storage_type = 'Dark Place' THEN 'Protect from Light'
  ELSE temperature_range
END
WHERE storage_type IN (
  'Freezer',
  'Cold / Fridge',
  'Cool',
  'Room Temp',
  'Normal Temp',
  'Dry Place',
  'Dark Place'
);

COMMIT;
