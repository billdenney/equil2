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
#' @examples
#' add_units()
#' @import units
add_units <- function() {
  if (requireNamespace("units")) {
    # Units requiring mEq/L
    units::install_unit("g_ammonia")
    units::install_unit("g_chloride")
    units::install_unit("g_potassium")
    units::install_unit("g_sodium")
    
    # weight from https://pubchem.ncbi.nlm.nih.gov/compound/Ammonia
    units::install_unit("mol_ammonia", def="17.031 g_ammonia")
    # weight from https://pubchem.ncbi.nlm.nih.gov/element/Chlorine#section=Atomic-Weight
    units::install_unit("mol_chloride", def="35.4527 g_chloride")
    # weight from https://pubchem.ncbi.nlm.nih.gov/element/Potassium#section=Atomic-Weight
    units::install_unit("mol_potassium", def="39.09831 g_potassium")
    # weight from https://pubchem.ncbi.nlm.nih.gov/element/Sodium#section=Atomic-Weight
    units::install_unit("mol_sodium", def="22.989769282 g_sodium")

    units::install_unit("Eq_ammonia", def="1 mol_ammonia")
    units::install_unit("Eq_chloride", def="1 mol_chloride")
    units::install_unit("Eq_potassium", def="1 mol_potassium")
    units::install_unit("Eq_sodium", def="1 mol_sodium")
    
    # Units requiring mg/dL
    units::install_unit("g_calcium")
    units::install_unit("g_citrate")
    units::install_unit("g_magnesium")
    units::install_unit("g_oxalate")
    units::install_unit("g_phosphate")
    units::install_unit("g_sulfate")
    units::install_unit("g_urate")
    
    # weight from https://pubchem.ncbi.nlm.nih.gov/element/Calcium#section=Atomic-Weight
    units::install_unit("mol_calcium", def="40.0784 g_calcium")
    # weight from https://pubchem.ncbi.nlm.nih.gov/compound/Citrate
    units::install_unit("mol_citrate", def="189.10 g_citrate")
    # weight from https://pubchem.ncbi.nlm.nih.gov/element/Magnesium#section=Atomic-Weight
    units::install_unit("mol_magnesium", def="24.305 g_magnesium")
    # weight from https://pubchem.ncbi.nlm.nih.gov/compound/Oxalate
    units::install_unit("mol_oxalate", def="88.02 g_oxalate")
    # weight from https://pubchem.ncbi.nlm.nih.gov/compound/Phosphate
    units::install_unit("mol_phosphate", def="94.971 g_phosphate")
    # weight from https://pubchem.ncbi.nlm.nih.gov/compound/Sulfate
    units::install_unit("mol_sulfate", def="96.07 g_sulfate")
    # weight from https://pubchem.ncbi.nlm.nih.gov/compound/Urate
    units::install_unit("mol_urate", def="168.11 g_urate")
    
    units::install_unit("Eq_sulfate", def="0.5 mol_sulfate")
    
    packageStartupMessage("units added to enable unit conversion")
  } else {
    packageStartupMessage("units package is not installed, no units added.")
  }
}
