
<!-- README.md is generated from README.Rmd. Please edit that file -->

# equil2

<!-- badges: start -->

[![Codecov test
coverage](https://codecov.io/gh/billdenney/equil2/branch/main/graph/badge.svg)](https://app.codecov.io/gh/billdenney/equil2?branch=main)
[![R-CMD-check](https://github.com/billdenney/equil2/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/billdenney/equil2/actions/workflows/R-CMD-check.yaml)
[![CRAN
status](https://www.r-pkg.org/badges/version/equil2)](https://CRAN.R-project.org/package=equil2)
<!-- badges: end -->

The goal of equil2 is to calculate urinary saturation with the EQUIL2
algorithm.

This program is intended for research use, only. The code within is
translated from EQUIL2 Visual Basic code based on Werness, et al 1985 to
R (see reference below). The Visual Basic code was kindly provided by
Dr. John Lieske of the Mayo Clinic.

Werness PG, Brown CM, Smith LH, Finlayson B. Equil2: A Basic Computer
Program for the Calculation of Urinary Saturation. Journal of Urology.
1985;134(6):1242-1244. <doi:10.1016/S0022-5347(17)47703-2>

## Installation

You can install the development version of equil2 like so:

``` r
remotes::install_github("billdenney/equil2")
```

## Example

This is a basic example which shows you how to calculate
supersaturation:

``` r
library(equil2)
#> units added to enable unit conversion
equil2(
  sodium_mEq_L=units::set_units(45, "mmol_sodium/L"),
  potassium_mEq_L=units::set_units(55, "mmol_potassium/L"),
  calcium_mg_dL=units::set_units(15, "mg_calcium/dL"),
  magnesium_mg_dL=units::set_units(15, "mg_magnesium/dL"),
  ammonia_mEq_L=units::set_units(10, "ug_ammonia/dL"),
  chloride_mEq_L=units::set_units(75, "mmol_chloride/L"),
  phosphate_mg_dL=units::set_units(100, "mg_phosphate/dL"),
  sulfate_mg_dL=units::set_units(20, "mEq_sulfate/L"),
  oxalate_mg_dL=units::set_units(10, "mg_oxalate/L"),
  citrate_mg_dL=units::set_units(400, "mg_citrate/L"),
  pH=5.5,
  urate_mg_dL=units::set_units(50, "mg_urate/dL")
)
#>           species super_saturation neg_delta_Gibbs
#> 1 Calcium Oxalate     2.751276e+00     1.309105783
#> 2        Brushite     1.006634e+00     0.008552342
#> 3  Hydroxyapatite     1.280275e+04     2.718439456
#> 4       Uric Acid     4.524588e+00     3.905145139
#> 5    Sodium Urate     1.550834e+00     0.567578360
#> 6  Ammonium Urate     1.493353e-04   -11.394850707
```
