#' Calculate urine saturation with the EQUIL-2 V1 algorithm
#'
#' @description This is a port of the original Mayo Clinic class-based VBA
#'   module `clsEquil2` ("V1") that predates the form-based BASIC source
#'   ported in [equil2()]. V1 accepts mmol/L (or any molar-convertible unit)
#'   inputs, models CO2/bicarbonate chemistry, TRIS buffer, and several
#'   ion-pair complexes that V5 omits, and (when chloride is omitted)
#'   auto-fills chloride from electroneutrality.
#'
#' @param pH The urine pH (unitless).
#' @param calcium_mmol_L,phosphate_mmol_L,oxalate_mmol_L,sodium_mmol_L,potassium_mmol_L,magnesium_mmol_L,ammonia_mmol_L,citrate_mmol_L,sulfate_mmol_L,urate_mmol_L
#'   Concentration of each species in mmol/L (or any unit value the `units`
#'   package can convert to mmol/L, e.g. `set_units(100, "mg_phosphate/dL")`).
#'   Defaults to zero.
#' @param chloride_mmol_L Chloride concentration in mmol/L. If `NA` (the
#'   default) chloride is auto-computed via electroneutrality, matching V1's
#'   `If TCl = 0 Then ...` block.
#' @param CO2_mmol_L Total CO2 (CO2 + H2CO3 + HCO3- + CO3^2- + carbonate
#'   complexes) in mmol/L.
#' @param pyrophosphate_mmol_L,TRIS_mmol_L Total pyrophosphate and TRIS buffer
#'   in mmol/L. **Note:** the V1 source unconditionally sets `TPP = 0` after
#'   reading the input, so the pyrophosphate chemistry is effectively disabled
#'   in V1 (this port preserves that behavior). TRIS is fully supported.
#' @param tolerance,max_iterations Convergence tolerance and iteration cap.
#'   Defaults match V1 (`1e-4` on the relative change in Ca/Mg/PO4/Ox/Cit/CO2,
#'   `500` max iterations).
#'
#' @details The V1 algorithm computes mass balance over a wider set of
#'   species than V5 (carbonate chemistry, TRIS buffer, struvite in the
#'   Mg/NH4 balance, urate-cation complexes in the Na/K/NH4 balance). The
#'   output reports activity products and relative saturation ratios (RSRs)
#'   for the four crystalline phases V1 itself reports — Calcium Oxalate,
#'   Brushite (CaHPO4·2H2O), Struvite (MgNH4PO4), and Uric Acid. For
#'   Hydroxyapatite, Sodium Urate, and Ammonium Urate supersaturations
#'   (which V1 does not output but V5 does), call [equil2()] instead.
#'
#'   Inputs are accepted in mmol/L. Supplying mass-based unit values via
#'   `units::set_units()` works (and is more chemically explicit than V5's
#'   mg/dL mode), but for `phosphate_mmol_L` and `sulfate_mmol_L`, note the
#'   same caveat as [equil2()]: the `mg_phosphate/dL` unit is the mass of
#'   PO4 (94.97 g/mol), not the mass of inorganic phosphorus that U.S.
#'   clinical labs typically report.
#'
#' @return A list with elements:
#' \itemize{
#'   \item{`supersaturation`: a data.frame with columns `species`,
#'     `activity_product` (mol^2/L^2 or mol^3/L^3 depending on stoichiometry),
#'     and `RSR` (relative saturation ratio; >1 means supersaturated).}
#'   \item{`ionic_strength`: scalar.}
#'   \item{`activity_factors`: named numeric `c(F1, F2, F3, F4)` for ions of
#'     charge 1/2/3/4 respectively.}
#'   \item{`iterations`: number of convergence iterations.}
#'   \item{`chloride_mmol_L`: chloride used (input or electroneutrality-derived).}
#' }
#'
#' @references
#' Werness PG, Brown CM, Smith LH, Finlayson B. Equil2: A Basic Computer Program
#' for the Calculation of Urinary Saturation. Journal of Urology.
#' 1985;134(6):1242-1244. doi:10.1016/S0022-5347(17)47703-2
#'
#' @seealso [equil2()] for the V5-based port (with Hydroxyapatite, Sodium
#'   Urate, and Ammonium Urate outputs) and `vignette("original-source-v1")`
#'   for the V1 VBA source.
#'
#' @examples
#' # Same LabCorp inputs used by equil2()'s example, expressed in mmol/L
#' equil2_v1(
#'   pH = 5.5,
#'   sodium_mmol_L = 45,
#'   potassium_mmol_L = 55,
#'   calcium_mmol_L = units::set_units(15, "mg_calcium/dL"),
#'   magnesium_mmol_L = units::set_units(15, "mg_magnesium/dL"),
#'   ammonia_mmol_L = units::set_units(10, "ug_ammonia/dL"),
#'   chloride_mmol_L = 75,
#'   phosphate_mmol_L = 32.285,
#'   sulfate_mmol_L = 10,
#'   oxalate_mmol_L = units::set_units(10, "mg_oxalate/L"),
#'   citrate_mmol_L = units::set_units(400, "mg_citrate/L"),
#'   urate_mmol_L = units::set_units(50, "mg_urate/dL")
#' )
#' @export
equil2_v1 <- function(pH,
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
                      tolerance = 1e-4,
                      max_iterations = 500
) {
  if (requireNamespace("units", quietly = TRUE)) {
    calcium_mmol_L      <- units::set_units(calcium_mmol_L,      "mmol_calcium/L",      mode = "standard")
    phosphate_mmol_L    <- units::set_units(phosphate_mmol_L,    "mmol_phosphate/L",    mode = "standard")
    oxalate_mmol_L      <- units::set_units(oxalate_mmol_L,      "mmol_oxalate/L",      mode = "standard")
    sodium_mmol_L       <- units::set_units(sodium_mmol_L,       "mmol_sodium/L",       mode = "standard")
    potassium_mmol_L    <- units::set_units(potassium_mmol_L,    "mmol_potassium/L",    mode = "standard")
    magnesium_mmol_L    <- units::set_units(magnesium_mmol_L,    "mmol_magnesium/L",    mode = "standard")
    ammonia_mmol_L      <- units::set_units(ammonia_mmol_L,      "mmol_ammonia/L",      mode = "standard")
    citrate_mmol_L      <- units::set_units(citrate_mmol_L,      "mmol_citrate/L",      mode = "standard")
    sulfate_mmol_L      <- units::set_units(sulfate_mmol_L,      "mmol_sulfate/L",      mode = "standard")
    urate_mmol_L        <- units::set_units(urate_mmol_L,        "mmol_urate/L",        mode = "standard")
    if (!is.na(chloride_mmol_L)) {
      chloride_mmol_L   <- units::set_units(chloride_mmol_L,     "mmol_chloride/L",     mode = "standard")
    }
    CO2_mmol_L          <- units::set_units(CO2_mmol_L,          "mmol_carbondioxide/L",          mode = "standard")
    pyrophosphate_mmol_L <- units::set_units(pyrophosphate_mmol_L,"mmol_pyrophosphate/L",mode = "standard")
    TRIS_mmol_L         <- units::set_units(TRIS_mmol_L,         "mmol_tris/L",         mode = "standard")
  }
  equil2_v1_helper(
    pH = as.numeric(pH),
    calcium_mmol_L = as.numeric(calcium_mmol_L),
    phosphate_mmol_L = as.numeric(phosphate_mmol_L),
    oxalate_mmol_L = as.numeric(oxalate_mmol_L),
    sodium_mmol_L = as.numeric(sodium_mmol_L),
    potassium_mmol_L = as.numeric(potassium_mmol_L),
    magnesium_mmol_L = as.numeric(magnesium_mmol_L),
    ammonia_mmol_L = as.numeric(ammonia_mmol_L),
    citrate_mmol_L = as.numeric(citrate_mmol_L),
    sulfate_mmol_L = as.numeric(sulfate_mmol_L),
    urate_mmol_L = as.numeric(urate_mmol_L),
    chloride_mmol_L = if (is.na(chloride_mmol_L)) NA_real_ else as.numeric(chloride_mmol_L),
    CO2_mmol_L = as.numeric(CO2_mmol_L),
    pyrophosphate_mmol_L = as.numeric(pyrophosphate_mmol_L),
    TRIS_mmol_L = as.numeric(TRIS_mmol_L),
    tolerance = tolerance,
    max_iterations = max_iterations
  )
}

# Core V1 algorithm, working in mmol/L numeric inputs (no units)
equil2_v1_helper <- function(pH,
                             calcium_mmol_L,
                             phosphate_mmol_L,
                             oxalate_mmol_L,
                             sodium_mmol_L,
                             potassium_mmol_L,
                             magnesium_mmol_L,
                             ammonia_mmol_L,
                             citrate_mmol_L,
                             sulfate_mmol_L,
                             urate_mmol_L,
                             chloride_mmol_L,
                             CO2_mmol_L,
                             pyrophosphate_mmol_L,
                             TRIS_mmol_L,
                             tolerance,
                             max_iterations
) {
  # Convert mmol/L to mol/L. V1 originally took mmol per collection volume
  # and divided by Vol*1000; we collapse that to mmol/L * 1e-3.
  TCa   <- calcium_mmol_L   / 1000
  TPO4  <- phosphate_mmol_L / 1000
  TOx   <- oxalate_mmol_L   / 1000
  TNa   <- sodium_mmol_L    / 1000
  TK    <- potassium_mmol_L / 1000
  TMg   <- magnesium_mmol_L / 1000
  TNH4  <- ammonia_mmol_L   / 1000
  TCit  <- citrate_mmol_L   / 1000
  TSO4  <- sulfate_mmol_L   / 1000
  TU    <- urate_mmol_L     / 1000
  TCO2  <- CO2_mmol_L       / 1000
  TPP   <- pyrophosphate_mmol_L / 1000
  TTRIS <- TRIS_mmol_L      / 1000
  TCl   <- if (is.na(chloride_mmol_L)) 0 else chloride_mmol_L / 1000

  F1 <- 0.7
  F2 <- 0.3
  F3 <- 0.1
  F4 <- 0.02
  H <- 10 ^ (-pH)

  # NOTE: V1 source unconditionally zeroes TPP and PP here, effectively
  # disabling the pyrophosphate pathway. This port preserves that behavior;
  # remove these two lines to enable the PP chemistry.
  TPP <- 0
  PP_var <- 0

  # Initial guesses (10% of total). H2O ~ pure water density.
  Cl  <- TCl
  Na  <- 0.1 * TNa
  K   <- 0.1 * TK
  Ca  <- 0.1 * TCa
  Mg  <- 0.1 * TMg
  NH4 <- 0.1 * TNH4
  PO4 <- 0.1 * TPO4
  SO4 <- 0.1 * TSO4
  Ox  <- 0.1 * TOx
  Cit <- 0.1 * TCit
  U   <- 0.1 * TU
  PP  <- 0.1 * TPP
  HPP <- 0.01 * PP
  CO2 <- 0.1 * TCO2
  H2O <- 55.6

  # Stability constants (V1 active values; commented-out V1 alternatives kept
  # in source comments for traceability).
  P1X1   <- 1.73e12   # HPO4 from PO4 + H
  P11X1  <- 1.49e7    # H2PO4
  P111X1 <- 162       # H3PO4
  P1X2   <- 145.5     # HSO4
  P1X3   <- 20750     # HOx
  P1X4   <- 2.64e6    # HCit
  P11X4  <- 55210     # H2Cit
  P111X4 <- 1247      # H3Cit
  P11X5  <- 294000    # H2U
  P21X1  <- 12.9      # NaHPO4
  P2X2   <- 5.433     # NaSO4
  P2X3   <- 13.4      # NaOx
  P2X4   <- 8.5       # NaCit
  P2X6   <- 216       # NaPP
  P21X6  <- 33.1      # NaHPP
  P22X6  <- 251.2     # Na2PP
  P31X1  <- 10        # KHPO4
  P3X2   <- 8.831001  # KSO4
  P3X3   <- 13.4      # KOx
  P3X4   <- 12.6      # KCit
  P3X6   <- 143       # KPP
  P4X1   <- 3.597e6   # CaPO4
  P41X1  <- 685       # CaHPO4
  P411X1 <- 31.3      # CaH2PO4
  P4X2   <- 229.6     # CaSO4
  P4X3   <- 2746      # CaOx
  P4X33  <- 17.3      # CaOx2 (chain via CaOx*Ox)
  P44X3  <- 71.4      # Ca2Ox (chain via Ca*CaOx)
  P4X4   <- 60000     # CaCit
  P41X4  <- 505.2     # CaHCit
  P411X4 <- 12.5      # CaH2Cit
  P5X1   <- 3.46e6    # MgPO4
  P51X1  <- 1014      # MgHPO4
  P511X1 <- 31.9      # MgH2PO4
  P5X2   <- 188.4     # MgSO4
  P5X3   <- 4020      # MgOx
  P55X3  <- 4.75      # Mg2Ox
  P5X33  <- 5.93      # MgOx2
  P5X4   <- 69900     # MgCit
  P51X4  <- 316.7     # MgHCit
  P511X4 <- 5         # MgH2Cit
  P61X1  <- 10        # NH4HPO4
  P6X2   <- 12.9      # NH4SO4
  P6X3   <- 13        # NH4Ox
  P6X4   <- 8.5       # NH4Cit
  P1X8   <- 5.88e7    # HTRIS
  P1X6   <- 2.44e9    # HPP
  P11X6  <- 4.97e6    # H2PP
  P111X6 <- 171       # H3PP
  PH4X6  <- 7.05      # H4PP
  P4X6   <- 562000    # CaPP
  P41X6  <- 5500      # CaHPP
  P4X1A6 <- 7.94e8    # CaOHPP
  P4X1A  <- 23.1      # CaOH
  P5X1A  <- 380.19    # MgOH
  P5X6   <- 1.977e7   # MgPP
  P5X1A6 <- 1.995e9   # MgOHPP
  P17X1  <- 4900      # HCO3 ratio (V1 = 4900; V5 used 1940000)
  P7X1   <- 1.58e10   # CO3 from HCO3
  P7     <- 0.00229   # CO2 dissociation
  P7X2   <- 18.6      # NaCO3
  P7X22  <- 1.03      # Na2CO3
  P7X4   <- 1585      # CaCO3
  P7X5   <- 2512      # MgCO3

  OH <- 10 ^ (-13.593 + pH)

  # Pre-iteration "old" values for convergence
  OldCa <- 0
  OldMg <- 0
  OldPO4 <- 0
  OldOx <- 0
  OldCit <- 0
  OldCO2 <- 0

  NH4PO4 <- 0   # V1: declared but never assigned -> 0 throughout

  # State carried out of loop for output
  HPO4 <- H2PO4 <- H3PO4 <- 0
  H2CO3 <- HCO3 <- CO3 <- 0
  NaCO3 <- Na2CO3 <- CaCO3 <- MgCO3 <- 0
  HSO4 <- HOx <- HCit <- H2Cit <- H3Cit <- 0
  NaHPO4 <- NaSO4 <- NaOx <- NaCit <- 0
  KHPO4 <- KSO4 <- KOx <- KCit <- 0
  CaPO4 <- CaHPO4 <- CaH2PO <- CaSO4 <- CaOx <- Ca2Ox <- CaOx2 <- 0
  CaCit <- CaHCit <- CaH2CT <- 0
  MgPO4 <- MgHPO4 <- MgH2PO <- MgSO4 <- MgOx <- Mg2Ox <- MgOx2 <- 0
  MgCit <- MgHCit <- MgH2CT <- 0
  NH4HPO <- NH4SO4 <- NH4Ox <- NH4Cit <- 0
  HU <- H2U <- NaU <- NH4U <- KU <- 0
  CaOH <- MgOH <- 0
  NaPP <- Na2PP <- NaHPP <- KPP <- CaPP <- CaHPP <- CaOHPP <- 0
  MgPP <- MgOHPP <- H2PP <- H3PP <- H4PP <- 0
  Struv <- 0
  TRIS_free <- HTRIS <- 0
  s <- 1e-6
  iter <- 0

  repeat {
    iter <- iter + 1

    # Ionic species (lines 426-494 of V1)
    HPO4   <- P1X1 * (F3 / F2) * H * PO4
    H2PO4  <- P11X1 * (F2 / F1) * H * HPO4
    H3PO4  <- P111X1 * F1 * H * H2PO4
    H2CO3  <- P7 * CO2 * H2O
    HCO3   <- H2CO3 / (H * P17X1 * F1)
    CO3    <- HCO3 / (H * P7X1 * F2)
    NaCO3  <- P7X2 * Na * CO3 * F2
    Na2CO3 <- P7X22 * Na * NaCO3 * F1 * F1
    CaCO3  <- P7X4 * Ca * CO3 * F2 * F2
    MgCO3  <- P7X5 * Mg * CO3 * F2 * F2
    HSO4   <- P1X2 * (F2 / F1) * H * SO4
    HOx    <- P1X3 * (F2 / F1) * H * Ox
    HCit   <- P1X4 * (F3 / F2) * H * Cit
    H2Cit  <- P11X4 * (F2 / F1) * H * HCit
    H3Cit  <- P111X4 * F1 * H * H2Cit
    NaHPO4 <- P21X1 * F2 * Na * HPO4
    NaSO4  <- P2X2 * F2 * Na * SO4
    NaOx   <- P2X3 * F2 * Na * Ox
    NaCit  <- P2X4 * (F3 * F1 / F2) * Na * Cit
    NaPP   <- P2X6 * Na * PP_var * F1 * F4 / F3
    Na2PP  <- P22X6 * Na * NaPP * F1 * F3 / F2
    NaHPP  <- P21X6 * Na * HPP * F1 * F3 / F2
    KHPO4  <- P31X1 * F2 * K * HPO4
    KSO4   <- P3X2 * F2 * K * SO4
    KOx    <- P3X3 * F2 * K * Ox
    KCit   <- P3X4 * (F3 * F1 / F2) * K * Cit
    KPP    <- P3X6 * K * PP_var * F1 * F4 / F3
    CaPO4  <- P4X1 * (F3 * F2 / F1) * Ca * PO4
    CaHPO4 <- P41X1 * (F2 * F2) * Ca * HPO4
    CaH2PO <- P411X1 * F2 * Ca * H2PO4
    CaSO4  <- P4X2 * (F2 * F2) * Ca * SO4
    CaOx   <- P4X3 * (F2 * F2) * Ca * Ox
    Ca2Ox  <- P44X3 * Ca * CaOx
    CaOx2  <- P4X33 * CaOx * Ox
    CaCit  <- P4X4 * (F3 * F2 / F1) * Ca * Cit
    CaHCit <- P41X4 * (F2 * F2) * Ca * HCit
    CaH2CT <- P411X4 * F2 * Ca * H2Cit
    MgPO4  <- P5X1 * (F3 * F2 / F1) * Mg * PO4
    MgHPO4 <- P51X1 * (F2 * F2) * Mg * HPO4
    MgH2PO <- P511X1 * F2 * Mg * H2PO4
    MgSO4  <- P5X2 * (F2 * F2) * Mg * SO4
    MgOx   <- P5X3 * (F2 * F2) * Mg * Ox
    Mg2Ox  <- P55X3 * Mg * MgOx
    MgOx2  <- P5X33 * MgOx * Ox
    MgCit  <- P5X4 * (F3 * F2 / F1) * Mg * Cit
    MgHCit <- P51X4 * (F2 * F2) * Mg * HCit
    MgH2CT <- P511X4 * F2 * Mg * H2Cit
    NH4HPO <- P61X1 * F2 * NH4 * HPO4
    NH4SO4 <- P6X2 * F2 * NH4 * SO4
    NH4Ox  <- P6X3 * F2 * NH4 * Ox
    NH4Cit <- P6X4 * (F3 * F1 / F2) * NH4 * Cit
    HU     <- 7.943e10 * F2 * H * U
    H2U    <- P11X5 * F1 * H * HU
    NaU    <- 358000 * F2 * Na * U
    NH4U   <- 27800  * F2 * NH4 * U
    KU     <- 10400  * F2 * K * U
    HPP    <- P1X6 * (F4 / F3) * H * PP_var
    H2PP   <- P11X6 * (F3 / F2) * H * HPP
    H3PP   <- P111X6 * (F2 / F1) * H * H2PP
    H4PP   <- PH4X6 * F1 * H * H3PP
    CaPP   <- P4X6 * F4 * Ca * PP_var
    CaHPP  <- P41X6 * (F2 * F3 / F1) * Ca * HPP
    CaOHPP <- P4X1A6 * (F4 * F2 / F3) * Ca * OH * PP_var
    CaOH   <- P4X1A * (F2 / F1) * Ca * OH
    MgOH   <- P5X1A * (F2 / F1) * Mg * OH
    MgPP   <- P5X6 * F4 * Mg * PP_var
    MgOHPP <- P5X1A6 * (F2 * F4 / F3) * Mg * OH * PP_var
    Struv  <- F1 * F2 * F3 * Mg * PO4 * NH4

    # Total concentrations (V1 lines 496-513). Note: V1 does NOT include
    # NaU / KU / NH4U in STNa / STK / STNH4 even though it computes those
    # complexes; they affect ionic strength and chloride auto-fill only.
    STNa  <- Na + NaHPO4 + NaSO4 + NaOx + NaCit + NaPP + NaHPP + 2 * Na2PP +
             NaCO3 + Na2CO3
    STK   <- K + KHPO4 + KSO4 + KOx + KCit + KPP
    STNH4 <- NH4 + NH4HPO + NH4SO4 + NH4Ox + NH4Cit + Struv
    STCa  <- Ca + CaPO4 + CaHPO4 + CaH2PO + CaSO4 + CaOx + 2 * Ca2Ox + CaCit +
             CaHCit + CaOx2 + CaH2CT + CaCO3 + CaPP + CaHPP + CaOHPP + CaOH
    STMg  <- Mg + MgPO4 + MgHPO4 + MgH2PO + MgSO4 + MgOx + 2 * Mg2Ox + MgCit +
             MgHCit + MgH2CT + MgOx2 + MgCO3 + Struv + MgOH + MgPP + MgOHPP
    STPO4 <- PO4 + HPO4 + H2PO4 + H3PO4 + NaHPO4 + KHPO4 + CaPO4 + CaHPO4 +
             CaH2PO + MgPO4 + MgHPO4 + MgH2PO + NH4HPO + Struv
    STSO4 <- SO4 + HSO4 + NaSO4 + KSO4 + CaSO4 + MgSO4 + NH4SO4
    STOx  <- Ox + HOx + CaOx + Ca2Ox + MgOx + Mg2Ox + NaOx + KOx + NH4Ox +
             2 * CaOx2 + 2 * MgOx2
    STCit <- Cit + HCit + H2Cit + H3Cit + NaCit + KCit + NH4Cit + CaCit +
             CaHCit + CaH2CT + MgCit + MgHCit + MgH2CT
    STPP  <- PP_var + HPP + H2PP + H3PP + CaPP + CaHPP + CaOHPP + MgPP +
             MgOHPP + NaPP + NaHPP + Na2PP + KPP + H4PP
    STU   <- HU + H2U + U
    STCO3 <- CO2 + CO3 + HCO3 + H2CO3 + NaCO3 + Na2CO3 + CaCO3 + MgCO3

    # Tiny-total clamps (V1 lines 515-521)
    if (TCa  < 1e-15) TCa  <- 0
    if (TMg  < 1e-15) TMg  <- 0
    if (TNH4 < 1e-15) TNH4 <- 0
    if (TPO4 < 1e-15) TPO4 <- 0
    if (TOx  < 1e-15) TOx  <- 0
    if (TU   < 1e-15) TU   <- 0
    if (TCit < 1e-15) TCit <- 0

    # Update free ion concentrations (V1 lines 529-602)
    Na  <- if (TNa  != 0) TNa  * Na  / STNa  else 0
    K   <- if (TK   != 0) TK   * K   / STK   else 0
    Ca  <- if (TCa  != 0) TCa  * Ca  / STCa  else 0
    Mg  <- if (TMg  != 0) TMg  * Mg  / STMg  else 0
    NH4 <- if (TNH4 != 0) TNH4 * NH4 / STNH4 else 0
    PO4 <- if (TPO4 != 0) TPO4 * PO4 / STPO4 else 0
    SO4 <- if (TSO4 != 0) TSO4 * SO4 / STSO4 else 0
    Ox  <- if (TOx  != 0) TOx  * Ox  / STOx  else 0
    Cit <- if (TCit != 0) TCit * Cit / STCit else 0
    U   <- if (TU   != 0) TU   * U   / STU   else 0

    TRIS_free <- TTRIS / (1 + (P1X8 * H) / F1)
    HTRIS     <- (P1X8 * H * TRIS_free) / F1

    PP_var <- if (TPP  != 0) TPP  * PP_var / STPP  else 0
    CO2    <- if (TCO2 != 0) TCO2 * CO2    / STCO3 else 0

    # Auto-fill chloride from electroneutrality if not supplied (V1 604-613).
    # NH4PO4 is always 0 here (V1 declares but never assigns it).
    if (TCl == 0) {
      Sum1 <- Ca + Mg + Ca2Ox + Mg2Ox -
              (SO4 + CaOx2 + Ox + HCit + HPO4 + NaCit + KCit + NH4Cit)
      Cl <- H + Na + K + NH4 + CaH2PO + CaH2CT + MgH2PO + MgH2CT + 2 * Sum1
      Cl <- Cl - HU - H2PO4 - HSO4 - HOx - H2Cit - NaHPO4 - NaSO4 - NaOx -
            KHPO4 - KSO4 - KOx
      Cl <- Cl - CaPO4 - CaCit - MgPO4 - MgCit - NH4PO4 - NH4Ox - 3 * (Cit + PO4)
      Cl <- Cl + HTRIS - 2 * (CaOx2 + MgOx2) - 3 * (NaPP + KPP + MgOHPP)
      Sum2 <- 4 * PP_var + 3 * CaOHPP + 2 * (H2PP + CaPP) + H3PP + CaHPP
      Cl <- Cl - 2 * (Na2PP + NaHPP + MgPP) - NaU - KU - NH4U - 2 * U - Sum2 -
            HCO3 - CO3 - NaCO3
      TCl <- Cl
    }

    # Ionic strength (lines 615-630)
    S1 <- (H + OH) / F1 + Na + K + NH4 + HU + Cl + NaHPO4 + NaSO4 + NaOx +
          NaCO3 + KHPO4 + KSO4 + KOx + NH4PO4 + NH4SO4 + NH4Ox + CaPO4 +
          CaH2PO + CaCit + CaH2CT + CaHPP + CaOH + H2PO4 + HCO3 + HSO4 +
          HOx + H2Cit + H3PP + HTRIS + NaU + KU + NH4U
    S2 <- 4 * (Ca + Mg + SO4 + Ox + CO3 + NaCit + Na2PP + KCit + NH4Cit +
               CaPP + NaHPP + MgPP + HPO4 + HCit + H2PP + Ca2Ox + Mg2Ox +
               CaOx2 + MgOx2 + U)
    S3 <- 9 * (PO4 + Cit + NaPP + KPP + HPP + CaOHPP + MgOHPP)
    S4 <- 16 * PP_var
    s <- (S1 + S2 + S3 + S4) / 2
    s <- max(min(s, 1), 1e-6)

    sqrt_s <- sqrt(s)
    F1 <- exp(-1.20218 * ((sqrt_s / (1 + sqrt_s)) - 0.285 * s))
    F2 <- F1 ^ 4
    F3 <- F1 ^ 9
    F4 <- F1 ^ 16

    # Convergence: V1 checks Ca, Mg, PO4, Ox, Cit, CO2 relative changes
    M <- 0
    if (Ca  != 0 && abs((Ca  - OldCa ) / Ca ) > tolerance) M <- 1
    if (Mg  != 0 && abs((Mg  - OldMg ) / Mg ) > tolerance) M <- 1
    if (PO4 != 0 && abs((PO4 - OldPO4) / PO4) > tolerance) M <- 1
    if (Ox  != 0 && abs((Ox  - OldOx ) / Ox ) > tolerance) M <- 1
    if (Cit != 0 && abs((Cit - OldCit) / Cit) > tolerance) M <- 1
    if (CO2 != 0 && abs((CO2 - OldCO2) / CO2) > tolerance) M <- 1

    OldCa  <- Ca
    OldMg  <- Mg
    OldPO4 <- PO4
    OldOx  <- Ox
    OldCit <- Cit
    OldCO2 <- CO2

    if (M == 0) break
    if (iter >= max_iterations) {
      warning(max_iterations,
              " iterations without convergence, interpret results with caution")
      break
    }
  }

  # Activity products and RSRs (V1 lines 676-690)
  AP_CaOx <- CaOx
  AP_Br   <- Ca * HPO4 * F2 * F2
  AP_Stru <- Struv
  AP_UA   <- H2U

  RSR_CaOx <- AP_CaOx / 6.16e-6
  RSR_Br   <- AP_Br   / 3.981e-7
  RSR_Stru <- AP_Stru / 7.1e-14
  RSR_UA   <- AP_UA   / 2.61e-4

  list(
    supersaturation = data.frame(
      species = c("Calcium Oxalate", "Brushite", "Struvite", "Uric Acid"),
      activity_product = c(AP_CaOx, AP_Br, AP_Stru, AP_UA),
      RSR = c(RSR_CaOx, RSR_Br, RSR_Stru, RSR_UA)
    ),
    ionic_strength = s,
    activity_factors = c(F1 = F1, F2 = F2, F3 = F3, F4 = F4),
    iterations = iter,
    chloride_mmol_L = TCl * 1000
  )
}
