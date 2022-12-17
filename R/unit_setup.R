#' Add units to support unit conversion for calculations
#'
#' Units are added to support molecular weight and mEq/L conversions.  Units are
#' named with the unit, an underscore, and the chemical species in lower case.
#' Examples are \code{"g_ammonia"}, \code{"mol_ammonia"}, and
#' \code{"Eq_ammonia"}.  Species with units are all species inputs for the
#' \code{equil2()} function.
#'
#' @return NULL, the function is used for its side-effects
#' @keywords Internal
#' @import units
add_units <- function() {
  if (requireNamespace("units")) {
    # Ensure units are present as suggested in https://github.com/r-quantities/units/issues/299
    unit_definitions <-
      data.frame(
        species=c("ammonia", "chloride", "potassium", "sodium",
                  "calcium", "citrate", "magnesium", "oxalate", "phosphate", "sulfate", "urate"
        ),
        mass_mole_conversion=
          c(
            17.031, # weight from https://pubchem.ncbi.nlm.nih.gov/compound/Ammonia
            35.4527, # weight from https://pubchem.ncbi.nlm.nih.gov/element/Chlorine#section=Atomic-Weight
            39.09831, # weight from https://pubchem.ncbi.nlm.nih.gov/element/Potassium#section=Atomic-Weight
            22.989769282, # weight from https://pubchem.ncbi.nlm.nih.gov/element/Sodium#section=Atomic-Weight

            40.0784, # weight from https://pubchem.ncbi.nlm.nih.gov/element/Calcium#section=Atomic-Weight
            189.10, # weight from https://pubchem.ncbi.nlm.nih.gov/compound/Citrate
            24.305, # weight from https://pubchem.ncbi.nlm.nih.gov/element/Magnesium#section=Atomic-Weight
            88.02, # weight from https://pubchem.ncbi.nlm.nih.gov/compound/Oxalate
            94.971, # weight from https://pubchem.ncbi.nlm.nih.gov/compound/Phosphate
            96.07, # weight from https://pubchem.ncbi.nlm.nih.gov/compound/Sulfate
            168.11 # weight from https://pubchem.ncbi.nlm.nih.gov/compound/Urate
          ),
        mole_eq_conversion=c(1, 1, 1, 1, NA, NA, NA, NA, NA, 0.5, NA)
      )
    units::remove_unit(c(
      paste0("g_", unit_definitions$species),
      paste0("mol_", unit_definitions$species),
      paste0("Eq_", unit_definitions$species[!is.na(unit_definitions$mole_eq_conversion)])
    ))
    units::install_unit(paste0("g_", unit_definitions$species))
    for (current_row in seq_len(nrow(unit_definitions))) {
      current_species <- unit_definitions$species[current_row]
      current_mol <- unit_definitions$mass_mole_conversion[current_row]
      current_eq <- unit_definitions$mole_eq_conversion[current_row]
      if (!is.na(current_mol)) {
        # See https://github.com/r-quantities/units/issues/334 for the reason
        # we're adding two units at once.
        new_units <- paste0("mol_", current_species)
        if (identical(current_eq, 1)) {
          new_units <- c(new_units, paste0("Eq_", current_species))
        }
        units::install_unit(new_units, def = sprintf("%g g_%s", current_mol, current_species))
      }
      if (!(current_eq %in% c(NA, 1))) {
        units::install_unit(paste0("Eq_", current_species), def = sprintf("%s mol_%s", current_eq, current_species))
      }
    }
    packageStartupMessage("units added to enable unit conversion")
  } else {
    packageStartupMessage("units package is not installed, no units added")
  }
}
