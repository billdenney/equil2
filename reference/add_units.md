# Add units to support unit conversion for calculations

Units are added to support molecular weight and mEq/L conversions. Units
are named with the unit, an underscore, and the chemical species in
lower case. Examples are `"g_ammonia"`, `"mol_ammonia"`, and
`"Eq_ammonia"`. Species with units are all species inputs for the
[`equil2()`](https://billdenney.github.io/equil2/reference/equil2.md)
function.

## Usage

``` r
add_units()
```

## Value

NULL, the function is used for its side-effects
