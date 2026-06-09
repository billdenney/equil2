# equil2 1.0.0.9000

* Bug fix (#2): corrected the phosphate and sulfate mass-mole conversion
  factors in `equil2()` so that the `mg_phosphate/dL` and `mg_sulfate/dL`
  units now consume actual phosphate (PO4(3-), 94.97 g/mol) and sulfate
  (SO4(2-), 96.07 g/mol) masses, matching the unit definitions in
  `add_units()`. The original V5 BASIC source uses atomic-weight factors
  for inorganic P (30.97) and S (32.06), so calling code that supplied
  unit-aware inputs such as `set_units(32, "mmol_phosphate/L")` saw
  approximately 3x over-estimates. Thanks Lea Lerose for the report and
  diagnosis. See `vignette("original-source")` for further discussion and
  a brief V1-vs-V5 comparison.

# equil2 1.0.0

* Initial version implementing the equil2 function for urine supersaturation
  calculations
