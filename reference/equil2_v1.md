# Calculate urine saturation with the EQUIL-2 V1 algorithm

This is a port of the original Mayo Clinic class-based VBA module
`clsEquil2` ("V1") that predates the form-based BASIC source ported in
[`equil2()`](https://billdenney.github.io/equil2/reference/equil2.md).
V1 accepts mmol/L (or any molar-convertible unit) inputs, models
CO2/bicarbonate chemistry, TRIS buffer, and several ion-pair complexes
that V5 omits, and (when chloride is omitted) auto-fills chloride from
electroneutrality.

## Usage

``` r
equil2_v1(
  pH,
  calcium_mmol_L = 0,
  phosphate_mmol_L = 0,
  oxalate_mmol_L = 0,
  sodium_mmol_L = 0,
  potassium_mmol_L = 0,
  magnesium_mmol_L = 0,
  ammonia_mmol_L = 0,
  citrate_mmol_L = 0,
  sulfate_mmol_L = 0,
  urate_mmol_L = 0,
  chloride_mmol_L = NA,
  CO2_mmol_L = 0,
  pyrophosphate_mmol_L = 0,
  TRIS_mmol_L = 0,
  tolerance = 1e-04,
  max_iterations = 500
)
```

## Arguments

- pH:

  The urine pH (unitless).

- calcium_mmol_L, phosphate_mmol_L, oxalate_mmol_L, sodium_mmol_L,
  potassium_mmol_L, magnesium_mmol_L, ammonia_mmol_L, citrate_mmol_L,
  sulfate_mmol_L, urate_mmol_L:

  Concentration of each species in mmol/L (or any unit value the `units`
  package can convert to mmol/L, e.g.
  `set_units(100, "mg_phosphate/dL")`). Defaults to zero.

- chloride_mmol_L:

  Chloride concentration in mmol/L. If `NA` (the default) chloride is
  auto-computed via electroneutrality, matching V1's
  `If TCl = 0 Then ...` block.

- CO2_mmol_L:

  Total CO2 (CO2 + H2CO3 + HCO3- + CO3^2- + carbonate complexes) in
  mmol/L.

- pyrophosphate_mmol_L, TRIS_mmol_L:

  Total pyrophosphate and TRIS buffer in mmol/L. **Note:** the V1 source
  unconditionally sets `TPP = 0` after reading the input, so the
  pyrophosphate chemistry is effectively disabled in V1 (this port
  preserves that behavior). TRIS is fully supported.

- tolerance, max_iterations:

  Convergence tolerance and iteration cap. Defaults match V1 (`1e-4` on
  the relative change in Ca/Mg/PO4/Ox/Cit/CO2, `500` max iterations).

## Value

A list with elements:

- `supersaturation`: a data.frame with columns `species`,
  `activity_product` (mol^2/L^2 or mol^3/L^3 depending on
  stoichiometry), and `RSR` (relative saturation ratio; \>1 means
  supersaturated).

- `ionic_strength`: scalar.

- `activity_factors`: named numeric `c(F1, F2, F3, F4)` for ions of
  charge 1/2/3/4 respectively.

- `iterations`: number of convergence iterations.

- `chloride_mmol_L`: chloride used (input or electroneutrality-derived).

## Details

The V1 algorithm computes mass balance over a wider set of species than
V5 (carbonate chemistry, TRIS buffer, struvite in the Mg/NH4 balance,
urate-cation complexes in the Na/K/NH4 balance). The output reports
activity products and relative saturation ratios (RSRs) for the four
crystalline phases V1 itself reports — Calcium Oxalate, Brushite
(CaHPO4·2H2O), Struvite (MgNH4PO4), and Uric Acid. For Hydroxyapatite,
Sodium Urate, and Ammonium Urate supersaturations (which V1 does not
output but V5 does), call
[`equil2()`](https://billdenney.github.io/equil2/reference/equil2.md)
instead.

Inputs are accepted in mmol/L. Supplying mass-based unit values via
[`units::set_units()`](https://r-quantities.github.io/units/reference/units.html)
works (and is more chemically explicit than V5's mg/dL mode), but for
`phosphate_mmol_L` and `sulfate_mmol_L`, note the same caveat as
[`equil2()`](https://billdenney.github.io/equil2/reference/equil2.md):
the `mg_phosphate/dL` unit is the mass of PO4 (94.97 g/mol), not the
mass of inorganic phosphorus that U.S. clinical labs typically report.

## References

Werness PG, Brown CM, Smith LH, Finlayson B. Equil2: A Basic Computer
Program for the Calculation of Urinary Saturation. Journal of Urology.
1985;134(6):1242-1244. doi:10.1016/S0022-5347(17)47703-2

## See also

[`equil2()`](https://billdenney.github.io/equil2/reference/equil2.md)
for the V5-based port (with Hydroxyapatite, Sodium Urate, and Ammonium
Urate outputs) and
[`vignette("original-source-v1")`](https://billdenney.github.io/equil2/articles/original-source-v1.md)
for the V1 VBA source.

## Examples

``` r
# Same LabCorp inputs used by equil2()'s example, expressed in mmol/L
equil2_v1(
  pH = 5.5,
  sodium_mmol_L = 45,
  potassium_mmol_L = 55,
  calcium_mmol_L = units::set_units(15, "mg_calcium/dL"),
  magnesium_mmol_L = units::set_units(15, "mg_magnesium/dL"),
  ammonia_mmol_L = units::set_units(10, "ug_ammonia/dL"),
  chloride_mmol_L = 75,
  phosphate_mmol_L = 32.285,
  sulfate_mmol_L = 10,
  oxalate_mmol_L = units::set_units(10, "mg_oxalate/L"),
  citrate_mmol_L = units::set_units(400, "mg_citrate/L"),
  urate_mmol_L = units::set_units(50, "mg_urate/dL")
)
#> $supersaturation
#>           species activity_product          RSR
#> 1 Calcium Oxalate     1.907592e-05 3.096740e+00
#> 2        Brushite     2.981115e-07 7.488357e-01
#> 3        Struvite     3.736751e-19 5.263029e-06
#> 4       Uric Acid     1.230873e-03 4.715988e+00
#> 
#> $ionic_strength
#> [1] 0.1320986
#> 
#> $activity_factors
#>         F1         F2         F3         F4 
#> 0.75941759 0.33260029 0.08400902 0.01223744 
#> 
#> $iterations
#> [1] 14
#> 
#> $chloride_mmol_L
#> [1] 75
#> 
```
