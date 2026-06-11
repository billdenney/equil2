# equil2 1.1.0

* The `CITATION` file now uses `bibentry()`

* New function `equil2_v1()` ports the original Mayo Clinic class-based
  VBA module (`clsEquil2`, attached to issue 2). V1 takes mmol/L inputs,
  models CO2 / bicarbonate / carbonate chemistry, TRIS buffer, struvite
  in the Mg / NH4 mass balance, and (when chloride is omitted) auto-fills
  chloride from electroneutrality. V1 outputs activity products and
  relative saturation ratios for Calcium Oxalate, Brushite, Struvite,
  and Uric Acid. For Hydroxyapatite, Sodium Urate, and Ammonium Urate
  supersaturations (which V1 does not compute) keep using `equil2()`.
  Pyrophosphate input is accepted but disabled inside the algorithm,
  matching the V1 source. The V1 source code is shipped in the new
  vignette `vignette("original-source-v1")`. The R port has been
  verified against the original VBA module by running `clsEquil2.bas`
  in LibreOffice Basic with `Option VBASupport 1`; on the LabCorp
  inputs the two agree to better than 10 ppm.
* New units in `add_units()`: `g_carbondioxide`, `g_pyrophosphate`,
  `g_tris` (and corresponding mol / mmol variants) for use with
  `equil2_v1()` inputs.

* Bug fix (#2): corrected the phosphate and sulfate mass-mole conversion
  factors in `equil2()` so that the `mg_phosphate/dL` and `mg_sulfate/dL`
  units now consume actual phosphate (PO4(3-), 94.97 g/mol) and sulfate
  (SO4(2-), 96.07 g/mol) masses, matching the unit definitions in
  `add_units()`. The original V5 BASIC source uses atomic-weight factors
  for inorganic P (30.97) and S (32.06), so calling code that supplied
  unit-aware inputs such as `set_units(32, "mmol_phosphate/L")` saw
  approximately 3x over-estimates. The R port has been cross-validated
  against the V5 BASIC source itself (with the same fix applied) run in
  LibreOffice Basic; the two agree on ionic strength to ~2 ppb and on
  the six supersaturation / Gibbs-energy outputs to better than 1 ppm on
  the LabCorp inputs. Thanks Lea Lerose for the report and diagnosis.
  See `vignette("original-source")` for further discussion and a brief
  V1-vs-V5 comparison.

# equil2 1.0.0

* Initial version implementing the equil2 function for urine supersaturation
  calculations
