test_that("equil2_v1 works correctly with units", {
  # Same LabCorp inputs used in test-equil2.R, recast as mmol/L for V1.
  # https://files.labcorp.com/testmenu-d8/sample_reports/306266.pdf
  value <-
    equil2_v1(
      pH = 5.5,
      sodium_mmol_L = 45,
      potassium_mmol_L = 55,
      calcium_mmol_L = set_units(15, "mg_calcium/dL"),
      magnesium_mmol_L = set_units(15, "mg_magnesium/dL"),
      ammonia_mmol_L = set_units(10, "ug_ammonia/dL"),
      chloride_mmol_L = 75,
      phosphate_mmol_L = 32.285,
      sulfate_mmol_L = 10,
      oxalate_mmol_L = set_units(10, "mg_oxalate/L"),
      citrate_mmol_L = set_units(400, "mg_citrate/L"),
      urate_mmol_L = set_units(50, "mg_urate/dL")
    )
  ss_round <- value$supersaturation
  ss_round$activity_product <- signif(ss_round$activity_product, 4)
  ss_round$RSR <- round(ss_round$RSR, 2)
  # TODO: Verify these against ss.exe / the original V1 VBA module by
  # entering the equivalent mmol/L inputs (phosphate 32.285, sulfate 10).
  # Snapshotted from the R port; if a V1 reference output becomes available,
  # update these values.
  expect_equal(
    ss_round,
    data.frame(
      species = c("Calcium Oxalate", "Brushite", "Struvite", "Uric Acid"),
      activity_product = c(1.908e-05, 2.981e-07, 3.736e-19, 1.231e-03),
      RSR = c(3.10, 0.75, 0.00, 4.72)
    ),
    tolerance = 1e-3
  )
  expect_equal(value$iterations, 14)
  expect_true(value$ionic_strength > 0 && value$ionic_strength < 1)
})

test_that("equil2_v1 phosphate input is interpreted as PO4 mass (issue 2)", {
  common_args <-
    list(
      pH = 5.5,
      sodium_mmol_L = 45,
      potassium_mmol_L = 55,
      calcium_mmol_L = set_units(15, "mg_calcium/dL"),
      magnesium_mmol_L = set_units(15, "mg_magnesium/dL"),
      ammonia_mmol_L = set_units(10, "ug_ammonia/dL"),
      chloride_mmol_L = 75,
      sulfate_mmol_L = 10,
      oxalate_mmol_L = set_units(10, "mg_oxalate/L"),
      citrate_mmol_L = set_units(400, "mg_citrate/L"),
      urate_mmol_L = set_units(50, "mg_urate/dL")
    )
  v_mmol <-
    do.call(equil2_v1,
            c(common_args,
              list(phosphate_mmol_L = set_units(32, "mmol_phosphate/L"))))
  v_mg <-
    do.call(equil2_v1,
            c(common_args,
              list(phosphate_mmol_L = set_units(32 * 94.971 / 10, "mg_phosphate/dL"))))
  expect_equal(v_mmol$supersaturation, v_mg$supersaturation, tolerance = 1e-6)
})

test_that("equil2_v1 sulfate input is interpreted as SO4 mass (issue 2)", {
  common_args <-
    list(
      pH = 5.5,
      sodium_mmol_L = 45,
      potassium_mmol_L = 55,
      calcium_mmol_L = set_units(15, "mg_calcium/dL"),
      magnesium_mmol_L = set_units(15, "mg_magnesium/dL"),
      ammonia_mmol_L = set_units(10, "ug_ammonia/dL"),
      chloride_mmol_L = 75,
      phosphate_mmol_L = 32.285,
      oxalate_mmol_L = set_units(10, "mg_oxalate/L"),
      citrate_mmol_L = set_units(400, "mg_citrate/L"),
      urate_mmol_L = set_units(50, "mg_urate/dL")
    )
  v_mmol <- do.call(equil2_v1,
                    c(common_args,
                      list(sulfate_mmol_L = set_units(10, "mmol_sulfate/L"))))
  v_mEq <- do.call(equil2_v1,
                   c(common_args,
                     list(sulfate_mmol_L = set_units(20, "mEq_sulfate/L"))))
  v_mg <- do.call(equil2_v1,
                  c(common_args,
                    list(sulfate_mmol_L = set_units(96.07, "mg_sulfate/dL"))))
  expect_equal(v_mmol$supersaturation, v_mEq$supersaturation, tolerance = 1e-6)
  expect_equal(v_mmol$supersaturation, v_mg$supersaturation, tolerance = 1e-6)
})

test_that("equil2_v1 auto-fills chloride from electroneutrality when omitted", {
  v_default <- equil2_v1(
    pH = 5.5,
    sodium_mmol_L = 45,
    potassium_mmol_L = 55,
    calcium_mmol_L = set_units(15, "mg_calcium/dL"),
    magnesium_mmol_L = set_units(15, "mg_magnesium/dL"),
    ammonia_mmol_L = set_units(10, "ug_ammonia/dL"),
    phosphate_mmol_L = 32.285,
    sulfate_mmol_L = 10,
    oxalate_mmol_L = set_units(10, "mg_oxalate/L"),
    citrate_mmol_L = set_units(400, "mg_citrate/L"),
    urate_mmol_L = set_units(50, "mg_urate/dL")
  )
  # When chloride is omitted (NA), V1 derives it via electroneutrality.
  # The derived value should be a real (non-NA, finite) number.
  expect_true(is.finite(v_default$chloride_mmol_L))
  expect_false(identical(v_default$chloride_mmol_L, 0))
})

test_that("equil2_v1 converges on the LabCorp inputs", {
  v <- equil2_v1(
    pH = 5.5,
    sodium_mmol_L = 45,
    potassium_mmol_L = 55,
    calcium_mmol_L = set_units(15, "mg_calcium/dL"),
    magnesium_mmol_L = set_units(15, "mg_magnesium/dL"),
    ammonia_mmol_L = set_units(10, "ug_ammonia/dL"),
    chloride_mmol_L = 75,
    phosphate_mmol_L = 32.285,
    sulfate_mmol_L = 10,
    oxalate_mmol_L = set_units(10, "mg_oxalate/L"),
    citrate_mmol_L = set_units(400, "mg_citrate/L"),
    urate_mmol_L = set_units(50, "mg_urate/dL")
  )
  expect_lt(v$iterations, 500)
  # Activity products should be positive and finite for these inputs.
  expect_true(all(is.finite(v$supersaturation$activity_product)))
  expect_true(all(v$supersaturation$activity_product >= 0))
})

test_that("equil2_v1 warns on non-convergence with low max_iterations", {
  expect_warning(
    equil2_v1(
      pH = 5.5,
      sodium_mmol_L = 45,
      calcium_mmol_L = 4,
      phosphate_mmol_L = 32,
      max_iterations = 2
    ),
    "iterations without convergence"
  )
})
