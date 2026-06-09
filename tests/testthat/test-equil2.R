test_that("equil2 works correctly with units", {
  # Example values from https://files.labcorp.com/testmenu-d8/sample_reports/306266.pdf
  # Phosphate (LabCorp reports 100 mg P/dL) and sulfate (LabCorp reports
  # 20 mEq SO4/L = 10 mmol/L) are given here in mmol/L so the meaning is
  # unambiguous after the issue #2 fix. See vignette("original-source").
  value <-
    equil2(
      sodium_mEq_L=set_units(45, "mmol_sodium/L"),
      potassium_mEq_L=set_units(55, "mmol_potassium/L"),
      calcium_mg_dL=set_units(15, "mg_calcium/dL"),
      magnesium_mg_dL=set_units(15, "mg_magnesium/dL"),
      ammonia_mEq_L=set_units(10, "ug_ammonia/dL"),
      chloride_mEq_L=set_units(75, "mmol_chloride/L"),
      phosphate_mg_dL=set_units(32.285, "mmol_phosphate/L"),
      sulfate_mg_dL=set_units(10, "mmol_sulfate/L"),
      oxalate_mg_dL=set_units(10, "mg_oxalate/L"),
      citrate_mg_dL=set_units(400, "mg_citrate/L"),
      pH=5.5,
      urate_mg_dL=set_units(50, "mg_urate/dL")
    )
  value_round <- value
  value_round$super_saturation <- round(value_round$super_saturation, 2)
  value_round$neg_delta_Gibbs <- round(value_round$neg_delta_Gibbs, 2)
  # TODO: Verify these against ss.exe by entering phosphate=100, sulfate=32.06
  # (mg/dL) in the V5 GUI. The numbers below were snapshotted from the R port
  # after the issue #2 fix and should match ss.exe with the equivalent
  # mg P/dL and mg S/dL inputs (the molar amounts are identical).
  expect_equal(
    value_round,
    data.frame(
      species = c("Calcium Oxalate", "Brushite", "Hydroxyapatite",
                  "Uric Acid", "Sodium Urate", "Ammonium Urate"),
      super_saturation = c(3.10, 1.26, 39041.89, 4.56, 1.63, 0),
      neg_delta_Gibbs = c(1.46, 0.30, 3.04, 3.93, 0.63, -11.29)
    ),
    tolerance=0.0001
  )
})

test_that("phosphate input is interpreted as PO4 mass, not P mass (issue #2)", {
  # The same molar amount of phosphate should give identical results
  # regardless of whether it's supplied as mmol/L or mg/dL of PO4.
  common_args <-
    list(
      sodium_mEq_L=set_units(45, "mmol_sodium/L"),
      potassium_mEq_L=set_units(55, "mmol_potassium/L"),
      calcium_mg_dL=set_units(15, "mg_calcium/dL"),
      magnesium_mg_dL=set_units(15, "mg_magnesium/dL"),
      ammonia_mEq_L=set_units(10, "ug_ammonia/dL"),
      chloride_mEq_L=set_units(75, "mmol_chloride/L"),
      sulfate_mg_dL=set_units(10, "mmol_sulfate/L"),
      oxalate_mg_dL=set_units(10, "mg_oxalate/L"),
      citrate_mg_dL=set_units(400, "mg_citrate/L"),
      pH=5.5,
      urate_mg_dL=set_units(50, "mg_urate/dL")
    )
  v_mmol <-
    do.call(
      equil2,
      c(common_args, list(phosphate_mg_dL=set_units(32, "mmol_phosphate/L")))
    )
  # 32 mmol/L of PO4 = 32 * 94.971 mg/L = 3039.07 mg/L = 303.91 mg/dL
  v_mg <-
    do.call(
      equil2,
      c(common_args, list(phosphate_mg_dL=set_units(32 * 94.971 / 10, "mg_phosphate/dL")))
    )
  expect_equal(v_mmol, v_mg, tolerance = 1e-6)
})

test_that("sulfate input is interpreted as SO4 mass, not S mass (issue #2)", {
  # The same molar amount of sulfate should give identical results
  # regardless of whether it's supplied as mmol/L, mEq/L, or mg/dL of SO4.
  common_args <-
    list(
      sodium_mEq_L=set_units(45, "mmol_sodium/L"),
      potassium_mEq_L=set_units(55, "mmol_potassium/L"),
      calcium_mg_dL=set_units(15, "mg_calcium/dL"),
      magnesium_mg_dL=set_units(15, "mg_magnesium/dL"),
      ammonia_mEq_L=set_units(10, "ug_ammonia/dL"),
      chloride_mEq_L=set_units(75, "mmol_chloride/L"),
      phosphate_mg_dL=set_units(32.285, "mmol_phosphate/L"),
      oxalate_mg_dL=set_units(10, "mg_oxalate/L"),
      citrate_mg_dL=set_units(400, "mg_citrate/L"),
      pH=5.5,
      urate_mg_dL=set_units(50, "mg_urate/dL")
    )
  v_mmol <-
    do.call(
      equil2,
      c(common_args, list(sulfate_mg_dL=set_units(10, "mmol_sulfate/L")))
    )
  v_mEq <-
    do.call(
      equil2,
      c(common_args, list(sulfate_mg_dL=set_units(20, "mEq_sulfate/L")))
    )
  v_mg <-
    do.call(
      equil2,
      c(common_args, list(sulfate_mg_dL=set_units(10 * 96.07 / 10, "mg_sulfate/dL")))
    )
  expect_equal(v_mmol, v_mEq, tolerance = 1e-6)
  expect_equal(v_mmol, v_mg, tolerance = 1e-6)
})
