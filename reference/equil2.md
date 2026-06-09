# Calculate urine saturation with the EQUIL-2 algorithm

Calculate urine saturation with the EQUIL-2 algorithm

## Usage

``` r
equil2(
  sodium_mEq_L,
  potassium_mEq_L,
  calcium_mg_dL,
  magnesium_mg_dL,
  ammonia_mEq_L,
  chloride_mEq_L,
  phosphate_mg_dL,
  sulfate_mg_dL,
  oxalate_mg_dL,
  citrate_mg_dL,
  pH,
  urate_mg_dL
)
```

## Arguments

- sodium_mEq_L, potassium_mEq_L, ammonia_mEq_L, chloride_mEq_L:

  Concentration of the given species in mEq/L (or a unit value that can
  be converted to mEq/L)

- calcium_mg_dL, magnesium_mg_dL, phosphate_mg_dL, sulfate_mg_dL,
  oxalate_mg_dL, citrate_mg_dL, urate_mg_dL:

  Concentration of the given species in mg/dL (or a unit value that can
  be converted to mg/dL)

- pH:

  The urine pH

## Value

A data.frame with three columns:

- "species" indicating the chemical species

- "super_saturation" is the supersaturation ratio. This is SS as defined
  in Werness 1985.

- "neg_delta_Gibbs" which is the negative of the change in Gibbs free
  energy of transfer from a supersaturated to a saturated solution (the
  value is negative for under-saturated solutions, zero for solutions at
  the solubility product, and positive for supersaturated solutions).
  This is DG as defined in Werness 1985.

## Details

This program is intended for research use, only. The code within is
translated from Visual Basic code based on Werness, et al 1985 to R. The
Visual Basic code was kindly provided by Dr. John Lieske of the Mayo
Clinic.

`phosphate_mg_dL` is the mass of phosphate (PO4, 94.97 g/mol) per dL,
and `sulfate_mg_dL` is the mass of sulfate (SO4, 96.07 g/mol) per dL.
U.S. clinical labs typically report "phosphate" and "sulfate" as the
mass of the inorganic element (P or S), so a value of 100 mg/dL on a
clinical report corresponds to ~32.3 mmol/L of phosphate (P MW 30.97) or
~31.2 mmol/L of sulfate (S MW 32.06). Supplying inputs in mmol/L (or any
molar unit) avoids ambiguity.

## References

Werness PG, Brown CM, Smith LH, Finlayson B. Equil2: A Basic Computer
Program for the Calculation of Urinary Saturation. Journal of Urology.
1985;134(6):1242-1244. doi:10.1016/S0022-5347(17)47703-2

## Examples

``` r
# Example values from https://files.labcorp.com/testmenu-d8/sample_reports/306266.pdf
# Phosphate and sulfate inputs are given in mmol/L so the meaning is
# unambiguous: clinical labs often report "phosphate (mg/dL)" as mass of
# inorganic phosphorus (P), but the `mg_phosphate/dL` unit in this package
# is mass of the PO4 ion. See vignette("original-source") for details.
equil2(
  sodium_mEq_L=units::set_units(45, "mmol_sodium/L"),
  potassium_mEq_L=units::set_units(55, "mmol_potassium/L"),
  calcium_mg_dL=units::set_units(15, "mg_calcium/dL"),
  magnesium_mg_dL=units::set_units(15, "mg_magnesium/dL"),
  ammonia_mEq_L=units::set_units(10, "ug_ammonia/dL"),
  chloride_mEq_L=units::set_units(75, "mmol_chloride/L"),
  phosphate_mg_dL=units::set_units(32.285, "mmol_phosphate/L"),
  sulfate_mg_dL=units::set_units(10, "mmol_sulfate/L"),
  oxalate_mg_dL=units::set_units(10, "mg_oxalate/L"),
  citrate_mg_dL=units::set_units(400, "mg_citrate/L"),
  pH=5.5,
  urate_mg_dL=units::set_units(50, "mg_urate/dL")
)
#>           species super_saturation neg_delta_Gibbs
#> 1 Calcium Oxalate     3.096613e+00       1.4620547
#> 2        Brushite     1.259350e+00       0.2982760
#> 3  Hydroxyapatite     3.904189e+04       3.0389279
#> 4       Uric Acid     4.563641e+00       3.9273785
#> 5    Sodium Urate     1.626900e+00       0.6295155
#> 6  Ammonium Urate     1.618179e-04     -11.2910116
```
