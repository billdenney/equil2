test_that("equil2 works correctly with units", {
  # Example values from https://files.labcorp.com/testmenu-d8/sample_reports/306266.pdf
  value <-
    equil2(
      sodium_mEq_L=set_units(45, "mmol_sodium/L"),
      potassium_mEq_L=set_units(55, "mmol_potassium/L"),
      calcium_mg_dL=set_units(15, "mg_calcium/dL"),
      magnesium_mg_dL=set_units(15, "mg_magnesium/dL"),
      ammonia_mEq_L=set_units(10, "ug_ammonia/dL"),
      chloride_mEq_L=set_units(75, "mmol_chloride/L"),
      phosphate_mg_dL=set_units(100, "mg_phosphate/dL"),
      sulfate_mg_dL=set_units(20, "mEq_sulfate/L"),
      oxalate_mg_dL=set_units(10, "mg_oxalate/L"),
      citrate_mg_dL=set_units(400, "mg_citrate/L"),
      pH=5.5,
      urate_mg_dL=set_units(50, "mg_urate/dL")
    )
  value_round <- value
  value_round$super_saturation <- round(value_round$super_saturation, 2)
  value_round$neg_delta_Gibbs <- round(value_round$neg_delta_Gibbs, 2)
  expect_equal(
    value_round,
    # Output generated from ss.exe
    data.frame(
      species = c("Calcium Oxalate", "Brushite", "Hydroxyapatite", 
                  "Uric Acid", "Sodium Urate", "Ammonium Urate"),
      super_saturation = c(2.75, 1.01, 12802.58, 4.52, 1.55, 0),
      neg_delta_Gibbs = c(1.31, 0.01, 2.72, 3.91, 0.57, 0)
    ),
    tolerance=0.0001
  )
})