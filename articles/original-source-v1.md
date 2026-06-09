# Original Source Code (V1)

Below is the original Visual Basic source code for the V1 class-based
EQUIL-2 module (`clsEquil2`), the basis of the
[`equil2_v1()`](https://billdenney.github.io/equil2/reference/equil2_v1.md)
function in this package. It is included to allow users to inspect the
fidelity of the code translation.

This program is intended for research use, only. The code within is
translated from Visual Basic code based on Werness, et al 1985 to R. The
Visual Basic code was kindly provided by Dr. John Lieske of the Mayo
Clinic and shared on the equil2 issue tracker by Lea Lerose ([issue
\#2](https://github.com/billdenney/equil2/issues/2)).

## Reference

Werness PG, Brown CM, Smith LH, Finlayson B. Equil2: A Basic Computer
Program for the Calculation of Urinary Saturation. Journal of Urology.
1985;134(6):1242-1244. <doi:10.1016/S0022-5347(17)47703-2>

## How V1 differs from V5

The V5 form-based BASIC source (in
[`vignette("original-source")`](https://billdenney.github.io/equil2/articles/original-source.md))
is a stripped-down version of V1. V1 adds several pathways that V5
omits:

- **CO2 / bicarbonate / carbonate** chemistry (H2CO3, HCO3, CO3, plus
  the Na2CO3 / CaCO3 / MgCO3 complexes).
- **TRIS buffer** (HTRIS).
- **Pyrophosphate (PP)** speciation — though, see the caveat below.
- **Struvite (MgNH4PO4)** included in the Mg and NH4 mass balances (V5
  computes struvite SS but does not feed it back into the balances).
- **Sodium-urate, ammonium-urate, and potassium-urate** complexes
  included in the Na/NH4/K mass balances (V5 reports their SS but does
  not couple them back into the cation balance).
- **Chloride auto-fill** via electroneutrality when no chloride is
  supplied (V5 requires a chloride input).
- **Inputs in mmol per collection volume** (V1) vs **mg/dL** (V5). V1’s
  approach is unit-unambiguous and does not need per-species
  atomic-weight conversion factors — see issue \#2 for why this matters.

V1 and V5 share the same stability constants for the core CaOx /
Brushite / HAP / Uric Acid / Sodium-urate / Ammonium-urate pathways. The
constants that differ are concentrated in the CO2 / PP / HU pathways
that V5 doesn’t use anyway (e.g. P7 for CO2 dissociation is 0.00229 in
V1 vs 0.00123 in V5; the HU formation constant is `7.943e10` in V1 vs
`2.78e5` in V5).

V1 reports **activity products** (`APCaOx`, `APBr`, `APStru`, `APUA`,
`APNaU`) and **relative saturation ratios** (RSR = AP / Ksp) for
**Calcium Oxalate, Brushite, Struvite, and Uric Acid** only. V5
additionally reports SS values for **Hydroxyapatite, Sodium Urate, and
Ammonium Urate**, plus a negative ΔGibbs energy for each. For those
V5-only outputs use the
[`equil2()`](https://billdenney.github.io/equil2/reference/equil2.md)
function.

V1’s iteration loop is capped at **500** iterations (vs 50 in V5) and
raises a warning on non-convergence.

## Quirks preserved by the R port

Three quirks of the V1 source are preserved verbatim in
[`equil2_v1()`](https://billdenney.github.io/equil2/reference/equil2_v1.md)
for fidelity:

1.  **Pyrophosphate is disabled.** After reading the input, V1
    unconditionally sets `TPP = 0` and `PP = 0`, which short-circuits
    the entire pyrophosphate pathway. The R port keeps this; users who
    want PP chemistry can edit the two `TPP <- 0` / `PP_var <- 0` lines
    in `R/equil2_v1.R`.
2.  **`NH4PO4` is uninitialized.** V1 declares `Dim NH4PO4 As Double`
    but never assigns it, so it is always zero (VBA default). In the R
    port we make this explicit with `NH4PO4 <- 0`.
3.  **Urate-cation complexes (`NaU`, `KU`, `NH4U`) are not in the cation
    mass balance.** V1 computes them and uses them for ionic strength
    and for the chloride electroneutrality auto-fill, but `STNa` / `STK`
    / `STNH4` do *not* include them. Effectively V1 treats them as trace
    species that don’t deplete free Na, K, or NH4. The R port matches
    this.

## Numerical verification against the V1 VBA module

The R port has been cross-validated against the original VBA module by
running `clsEquil2.bas` in LibreOffice 26.2.4 with `Option VBASupport 1`
and `Option ClassModule`, using LibreOffice’s Python UNO bridge to drive
the Calc method. On the LabCorp inputs in the package examples, ionic
strength agrees to \<1 ppm and the four reported activity products /
relative saturation ratios agree to ~10 ppm. The residual differences
are floating-point reordering noise from how mass-balance sums are
grouped in R vs the original BASIC.

## EQUIL-2 V1 source

The code below is the basis of the
[`equil2_v1()`](https://billdenney.github.io/equil2/reference/equil2_v1.md)
function.

``` vb
VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "clsEquil2"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

' input
Private varpH As Variant
Private varVol As Variant
Private varCa As Variant
Private varP As Variant
Private varOx As Variant
Private varNa As Variant
Private varK As Variant
Private varMg As Variant
Private varNH4 As Variant
Private varCit As Variant
Private varSO4 As Variant
Private varUA As Variant
Private varCl As Variant
Private varCO2 As Variant
Private varPP As Variant
Private varTRIS As Variant
' Activity Products
Private varAPCaOx As Variant    ' Moles squared
Private varAPBr As Variant
Private varAPStru As Variant
Private varAPUA As Variant
Private varAPNaU As Variant
' Relative Saturation Ratio's
Private varRSRCaOx As Variant
Private varRSRBr As Variant
Private varRSRStru As Variant
Private varRSRUA As Variant
' Undissociated Uric Acid
Private varH2U As Variant       ' mg/day
' Total concentrations, mol/L
Private varTCa As Variant
Private varTP As Variant
Private varTOx As Variant
Private varTNa As Variant
Private varTK As Variant
Private varTMg As Variant
Private varTNH4 As Variant
Private varTCit As Variant
Private varTSO4 As Variant
Private varTUA As Variant
Private varTCl As Variant
Private varTCO2 As Variant
Private varTPP As Variant
Private varTTRIS As Variant
' Ionic Strength
Private varIonicStrength As Variant
' Ionic Species
Private varISNa As Variant
Private varISK As Variant
Private varISCa As Variant
Private varISMg As Variant
Private varISNH4 As Variant
Private varISPO4 As Variant
Private varISSO4 As Variant
Private varISOx As Variant
Private varISCit As Variant
Private varISHU As Variant
Private varISCl As Variant
Private varISPP As Variant
Private varISCO2 As Variant
Private varISH2O As Variant
Private varISHPO4 As Variant
Private varISH2PO4 As Variant
Private varISH3PO4 As Variant
Private varISH2CO3 As Variant
Private varISHCO3 As Variant
Private varISCO3 As Variant
Private varISNaCO3 As Variant
Private varISNa2CO3 As Variant
Private varISCaCO3 As Variant
Private varISMgCO3 As Variant
Private varISHSO4 As Variant
Private varISHOx As Variant
Private varISHCit As Variant
Private varISH2Cit As Variant
Private varISH3Cit As Variant
Private varISH2U As Variant
Private varISHPP As Variant
Private varISH2PP As Variant
Private varISH3PP As Variant
Private varISH4PP As Variant
Private varISNaHPO4 As Variant
Private varISNaSO4 As Variant
Private varISNaOx As Variant
Private varISNaCit As Variant
Private varISNaPP As Variant
Private varISNa2PP As Variant
Private varISNaHPP As Variant
Private varISKHPO4 As Variant
Private varISKSO4 As Variant
Private varISKOx As Variant
Private varISKCit As Variant
Private varISKPP As Variant
Private varISCaPO4 As Variant
Private varISCaHPO4 As Variant
Private varISCaH2PO4 As Variant
Private varISCaSO4 As Variant
Private varISCaOx As Variant
Private varISCa2Ox As Variant
Private varISCaOx2 As Variant
Private varISCaCit As Variant
Private varISCaHCit As Variant
Private varISCaH2Cit As Variant
Private varISCaPP As Variant
Private varISCaHPP As Variant
Private varISCaOHPP As Variant
Private varISCaOH As Variant
Private varISMgPO4 As Variant
Private varISMgHPO4 As Variant
Private varISMgH2PO4 As Variant
Private varISMgSO4 As Variant
Private varISMgOx As Variant
Private varISMg2Ox As Variant
Private varISMgOx2 As Variant
Private varISMgCit As Variant
Private varISMgHCit As Variant
Private varISMgH2Cit As Variant
Private varISMgPP As Variant
Private varISMgOHPP As Variant
Private varISMgOH As Variant
Private varISNH4HPO4 As Variant
Private varISNH4SO4 As Variant
Private varISNH4Ox As Variant
Private varISNH4Cit As Variant
Private varF1 As Variant
Private varF2 As Variant
Private varF3 As Variant
Private varF4 As Variant
' status
Private intErr As Integer

Sub Calc()
    Call mCalcEquil2
End Sub

Private Sub mCalcEquil2()
    
    Dim done As Integer
    Dim TN As Integer
    Dim NEQUAL As Integer
    Dim NCTC As Integer
    Dim status As Integer
    Dim ch As Integer
    Dim pH As Double, Vol As Double, TCa As Double, TPO4 As Double, TOx As Double, TNa As Double, TK As Double, TMg As Double, TNH4 As Double, TCit As Double, TSO4 As Double, TU As Double, TCO2 As Double
    Dim ZCaOx As Double, ZCaHP As Double, ZNaU As Double, APCaOx As Double, APBr As Double, APNaU As Double, H2U As Double
    Dim RSCaOx As Double, RSBr As Double, RSNaU As Double, RSStruv As Double, RSUA As Double
    Dim RSRCaOx As Double, RSRBr As Double, RSRNaU As Double
    Dim NaHPO4 As Double, NaSO4 As Double, NaOx As Double, NaCit As Double, KHPO4 As Double, KSO4 As Double, KOx As Double, KCit As Double
    Dim MgPO4 As Double, MgHPO4 As Double, MgH2PO As Double, MgSO4 As Double, MgOx As Double, Mg2Ox As Double, MgCit As Double, MgH2CT As Double
    Dim MgHCit As Double, MgOx2 As Double, MgOH As Double, NH4HPO As Double, NH4SO4 As Double, NH4Ox As Double, NH4Cit As Double, K As Double
    Dim MgPP As Double, MgOHPP As Double, NaPP As Double, NaHPP As Double, Na2PP As Double, KPP As Double
    Dim TCl As Double, H2O
    Dim Na As Double, NH4 As Double, Ca As Double, Mg As Double, PO4 As Double, Ox As Double, HU As Double, HPO4 As Double, SO4 As Double, Cit As Double, F1 As Double, F2 As Double, F3 As Double, F4 As Double, Cl As Double
    Dim T As Double, H As Double, HPP As Double, PP As Double, OH As Double, TOH As Double
    Dim OldNa As Double, OldK As Double, OldNH4 As Double, OldCa As Double, OldMg As Double, OldPO4 As Double, OldSO4 As Double, OldOx As Double, OldCit As Double, OldCO2 As Double, OldHU As Double, OldPP As Double
    Dim P1X1 As Double, P11X1 As Double, P111X1 As Double, P1X2 As Double, P1X3 As Double, P1X4 As Double, P11X4 As Double, P111X4 As Double, P11X5 As Double
    Dim P21X1 As Double, P2X2 As Double, P2X3 As Double, P2X4 As Double, P2X6 As Double, P21X6 As Double, P22X6 As Double
    Dim P31X1 As Double, P3X2 As Double, P3X3 As Double, P3X4 As Double, P3X6 As Double
    Dim P4X1 As Double, P41X1 As Double, P411X1 As Double, P4X2 As Double, P4X3 As Double, P4X33 As Double, P44X3 As Double, P4X4 As Double, P41X4 As Double, P411X4 As Double
    Dim P5X1 As Double, P51X1 As Double, P511X1 As Double, P5X2 As Double, P5X3 As Double, P55X3 As Double, P5X33 As Double, P5X4 As Double, P51X4 As Double, P511X4 As Double
    Dim P61X1 As Double, P6X2 As Double, P6X3 As Double, P6X4 As Double
    Dim P1X6 As Double, P11X6 As Double, P111X6 As Double, PH4X6 As Double, P4X6 As Double, P41X6 As Double, P4X1A6 As Double, P4X1A As Double
    Dim P5X1A As Double, P5X6 As Double, P5X1A6 As Double
    Dim P17X1 As Double, P7X1 As Double, P7 As Double, P7X2 As Double, P7X22 As Double, P7X4 As Double, P7X5 As Double
    Dim H2PO4 As Double, H3PO4 As Double, HSO4 As Double, HOx As Double, HCit As Double, H2Cit As Double, H3Cit As Double
    Dim CaPO4 As Double, CaHPO4 As Double, CaH2PO As Double, CaSO4 As Double, CaOx As Double, Ca2Ox As Double, CaOx2 As Double
    Dim CaCit As Double, CaHCit As Double, CaH2CT As Double
    Dim H2PP As Double, H3PP As Double, H4PP As Double, CaPP As Double, CaHPP As Double, CaOHPP As Double, CaOH As Double
    Dim H2CO3 As Double, HCO3 As Double, CO3 As Double, NaCO3 As Double, Na2CO3 As Double, CaCO3 As Double, MgCO3 As Double
    Dim STNa As Double, STK As Double, STNH4 As Double, STCa As Double, STMg As Double, STPO4 As Double, STSO4 As Double, STOx As Double, STCit As Double, STPP As Double, STU As Double, STCO2 As Double
    Dim TPP As Double, SS As Double, AP As Double, Brush As Double, RES1 As Double, RES2 As Double, RES3 As Double, RAP As Double
    Dim RBrush As Double, RSU As Double, RCaOH2 As Double, RMgOH2 As Double, RWhit As Double, RMgPO4 As Double
    Dim ZKU As Double, ZNH4U As Double, ZCaUPK As Double, ZCaUB As Double, ZMgUB As Double, ZZZ As Double
    Dim P1X8 As Double, U As Double, NaU As Double, NH4U As Double, KU As Double
    Dim Struv As Double, STCO3 As Double, TTRIS As Double, TRIS As Double, HTRIS As Double
    Dim Sum1 As Double, Sum2 As Double
    Dim NH4PO4 As Double
    Dim S1 As Double, S2 As Double, S3 As Double, S4 As Double
    Dim M As Integer
    Dim RCaOx As Double, RStruv As Double
    Dim s As Double
    
    ' set all output to empty
    varRSRCaOx = Empty
    varRSRBr = Empty
    varRSRStru = Empty
    varRSRUA = Empty

    If Not IsNull(varpH) And Not IsEmpty(varpH) Then
        pH = varpH
    Else
        intErr = 1
        Exit Sub
    End If
    
    If Not IsNull(varVol) And Not IsEmpty(varVol) Then
        Vol = varVol
    Else
        intErr = 2
        Exit Sub
    End If
    
    If Not IsNull(varCa) And Not IsEmpty(varCa) Then
        TCa = varCa
    Else
        TCa = 0#
    End If
    
    If Not IsNull(varP) And Not IsEmpty(varP) Then
        TPO4 = varP
    Else
        TPO4 = 0#
    End If
    
    If Not IsNull(varOx) And Not IsEmpty(varOx) Then
        TOx = varOx
    Else
        TOx = 0#
    End If
    
    If Not IsNull(varNa) And Not IsEmpty(varNa) Then
        TNa = varNa
    Else
        TNa = 0#
    End If
    
    If Not IsNull(varK) And Not IsEmpty(varK) Then
        TK = varK
    Else
        TK = 0#
    End If
    
    If Not IsNull(varMg) And Not IsEmpty(varMg) Then
        TMg = varMg
    Else
        TMg = 0#
    End If
    
    If Not IsNull(varNH4) And Not IsEmpty(varNH4) Then
        TNH4 = varNH4
    Else
        TNH4 = 0#
    End If
    
    If Not IsNull(varCit) And Not IsEmpty(varCit) Then
        TCit = varCit
    Else
        TCit = 0#
    End If
    
    If Not IsNull(varSO4) And Not IsEmpty(varSO4) Then
        TSO4 = varSO4
    Else
        TSO4 = 0#
    End If
    
    If Not IsNull(varUA) And Not IsEmpty(varUA) Then
        TU = varUA
    Else
        TU = 0#
    End If
    
    If Not IsNull(varCl) And Not IsEmpty(varCl) Then
        TCl = varCl
    Else
        TCl = 0#
    End If
    
    If Not IsNull(varCO2) And Not IsEmpty(varCO2) Then
        TCO2 = varCO2
    Else
        TCO2 = 0#
    End If

    If Not IsNull(varPP) And Not IsEmpty(varPP) Then
        TPP = varPP
    Else
        TPP = 0#
    End If
    
    If Not IsNull(varTRIS) And Not IsEmpty(varTRIS) Then
        TTRIS = varTRIS
    Else
        TTRIS = 0#
    End If
    
    done = False
    
    T = 0#
    ' Convert from mmol/TV to mol/L
    TCa = ((TCa / Vol) / 1000#)
    TPO4 = ((TPO4 / Vol) / 1000#)
    TOx = ((TOx / Vol) / 1000#)
    TNa = (TNa / Vol) / 1000#
    TK = (TK / Vol) / 1000#
    TMg = ((TMg / Vol) / 1000#)
    TNH4 = (TNH4 / Vol) / 1000#
    TCit = ((TCit / Vol) / 1000#)
    TSO4 = (TSO4 / Vol) / 1000#
    TU = ((TU / Vol) / 1000#)
    TCO2 = (TCO2 / Vol) / 1000#
    TCl = (TCl / Vol) / 1000#
    TPP = (TPP / Vol) / 1000#
    TTRIS = (TTRIS / Vol) / 1000#
    
    F1 = 0.7
    F2 = 0.3
    F3 = 0.1
    F4 = 0.02

    H = 10# ^ -pH
    
    TPP = 0#
    PP = 0#
        
    OldNa = 0#
    OldK = 0#
    OldCa = 0#
    OldMg = 0#
    OldPO4 = 0#
    OldSO4 = 0#
    OldOx = 0#
    OldCit = 0#
    OldCO2 = 0#
    
    Cl = TCl
    Na = 0.1 * TNa
    K = 0.1 * TK
    Ca = 0.1 * TCa
    Mg = 0.1 * TMg
    NH4 = 0.1 * TNH4
    PO4 = 0.1 * TPO4
    SO4 = 0.1 * TSO4
    Ox = 0.1 * TOx
    Cit = 0.1 * TCit
    U = 0.1 * TU
    PP = 0.1 * TPP
    HPP = 0.01 * PP
    CO2 = 0.1 * TCO2
    'H2O = 55.6
    
    P1X1 = 1730000000000# ' 1520000000000#
    P11X1 = 14900000# '15200000#
    P111X1 = 162# '164#
    P1X2 = 145.5 '100#
    P1X3 = 20750# '215000#
    P1X4 = 2640000# '2720000#
    P11X4 = 55210# '56100#
    P111X4 = 1247# '1270#
    P11X5 = 294000# '308000#
    P21X1 = 12.9
    P2X2 = 5.433 '5.25
    P2X3 = 13.4 '13.4
    P2X4 = 8.5
    P2X6 = 216# '190.5
    P21X6 = 33.1 '33.1
    P22X6 = 251.2
    P31X1 = 10#
    P3X2 = 8.831001 '9.11
    P3X3 = 13.4 '13.4
    P3X4 = 12.6 '12.6
    P3X6 = 143# '199.5
    P4X1 = 3597000# '3460000#
    P41X1 = 685# '681#
    P411X1 = 31.3 '31.9
    P4X2 = 229.6 '200#
    P4X3 = 2746#  '2746#
    P4X33 = 17.3
    P44X3 = 71.4
    P4X4 = 60000#
    P41X4 = 505.2
    P411X4 = 12.5
    P5X1 = 3460000#
    P51X1 = 1014#  '741#
    P511X1 = 31.9
    P5X2 = 188.4  '269#
    P5X3 = 4020#
    P55X3 = 4.75
    P5X33 = 5.93
    P5X4 = 69900#
    P51X4 = 316.7
    P511X4 = 5#
    P61X1 = 10#
    P6X2 = 12.9
    P6X3 = 13#
    P6X4 = 8.5
    P1X8 = 58800000# ' New
    P1X6 = 2440000000# '6150000000#
    P11X6 = 4970000#  '6150000#
    P111X6 = 171#  '190#
    PH4X6 = 7.05 '10#
    P4X6 = 562000#
    P41X6 = 5500#
    P4X1A6 = 794000000#
    P4X1A = 23.1 '29.512
    P5X1A = 380.19
    P5X6 = 19770000# '15650000#
    P5X1A6 = 1995000000#
    H2O = 55.6 'New
    P17X1 = 4900#  '2240000#
    P7X1 = 15800000000#
    P7 = 0.00229
    P7X2 = 18.6
    P7X22 = 1.03
    P7X4 = 1585#
    P7X5 = 2512#

    NCTC = 0

    OH = 10# ^ (-13.593 + pH) '10# ^ (-(14 - pH))

    NEQUAL = 0

    Do
        HPO4 = P1X1 * (F3 / F2) * H * PO4
        H2PO4 = P11X1 * (F2 / F1) * H * HPO4
        H3PO4 = P111X1 * F1 * H * H2PO4
        H2CO3 = P7 * CO2 * H2O
        HCO3 = H2CO3 / (H * P17X1 * F1)
        CO3 = HCO3 / (H * P7X1 * F2)
        NaCO3 = P7X2 * Na * CO3 * F2
        Na2CO3 = P7X22 * Na * NaCO3 * F1 * F1
        CaCO3 = P7X4 * Ca * CO3 * F2 * F2
        MgCO3 = P7X5 * Mg * CO3 * F2 * F2
        HSO4 = P1X2 * (F2 / F1) * H * SO4
        HOx = P1X3 * (F2 / F1) * H * Ox
        HCit = P1X4 * (F3 / F2) * H * Cit
        H2Cit = P11X4 * (F2 / F1) * H * HCit
        H3Cit = P111X4 * F1 * H * H2Cit
        NaHPO4 = P21X1 * F2 * Na * HPO4
        NaSO4 = P2X2 * F2 * Na * SO4
        NaOx = P2X3 * F2 * Na * Ox
        NaCit = P2X4 * (F3 * F1 / F2) * Na * Cit
        NaPP = P2X6 * Na * PP * F1 * F4 / F3
        Na2PP = P22X6 * Na * NaPP * F1 * F3 / F2
        NaHPP = P21X6 * Na * HPP * F1 * F3 / F2
        KHPO4 = P31X1 * F2 * K * HPO4
        KSO4 = P3X2 * F2 * K * SO4
        KOx = P3X3 * F2 * K * Ox
        KCit = P3X4 * (F3 * F1 / F2) * K * Cit
        KPP = P3X6 * K * PP * F1 * F4 / F3
        CaPO4 = P4X1 * (F3 * F2 / F1) * Ca * PO4
        CaHPO4 = P41X1 * (F2 * F2) * Ca * HPO4
        CaH2PO = P411X1 * F2 * Ca * H2PO4
        CaSO4 = P4X2 * (F2 * F2) * Ca * SO4
        CaOx = P4X3 * (F2 * F2) * Ca * Ox
        Ca2Ox = P44X3 * Ca * CaOx
        CaOx2 = P4X33 * CaOx * Ox
        CaCit = P4X4 * (F3 * F2 / F1) * Ca * Cit
        CaHCit = P41X4 * (F2 * F2) * Ca * HCit
        CaH2CT = P411X4 * F2 * Ca * H2Cit
        MgPO4 = P5X1 * (F3 * F2 / F1) * Mg * PO4
        MgHPO4 = P51X1 * (F2 * F2) * Mg * HPO4
        MgH2PO = P511X1 * F2 * Mg * H2PO4
        MgSO4 = P5X2 * (F2 * F2) * Mg * SO4
        MgOx = P5X3 * (F2 * F2) * Mg * Ox
        Mg2Ox = P55X3 * Mg * MgOx
        MgOx2 = P5X33 * MgOx * Ox
        MgCit = P5X4 * (F3 * F2 / F1) * Mg * Cit
        MgHCit = P51X4 * (F2 * F2) * Mg * HCit
        MgH2CT = P511X4 * F2 * Mg * H2Cit
        NH4HPO = P61X1 * F2 * NH4 * HPO4
        NH4SO4 = P6X2 * F2 * NH4 * SO4
        NH4Ox = P6X3 * F2 * NH4 * Ox
        NH4Cit = P6X4 * (F3 * F1 / F2) * NH4 * Cit
        HU = 79430000000# * F2 * H * U ' New
        H2U = P11X5 * F1 * H * HU
        NaU = 358000# * F2 * Na * U  ' New
        NH4U = 27800# * F2 * NH4 * U  ' New
        KU = 10400# * F2 * K * U  ' New
        HPP = P1X6 * (F4 / F3) * H * PP
        H2PP = P11X6 * (F3 / F2) * H * HPP
        H3PP = P111X6 * (F2 / F1) * H * H2PP
        H4PP = PH4X6 * F1 * H * H3PP
        CaPP = P4X6 * F4 * Ca * PP
        CaHPP = P41X6 * (F2 * F3 / F1) * Ca * HPP
        CaOHPP = P4X1A6 * (F4 * F2 / F3) * Ca * OH * PP
        CaOH = P4X1A * (F2 / F1) * Ca * OH
        MgOH = P5X1A * (F2 / F1) * Mg * OH
        MgPP = P5X6 * F4 * Mg * PP
        MgOHPP = P5X1A6 * (F2 * F4 / F3) * Mg * OH * PP
        Struv = F1 * F2 * F3 * Mg * PO4 * NH4 ' New

        STNa = Na + NaHPO4 + NaSO4 + NaOx + NaCit + NaPP + NaHPP + 2 * Na2PP
        STNa = STNa + NaCO3 + Na2CO3
        STK = K + KHPO4 + KSO4 + KOx + KCit + KPP
        STNH4 = NH4 + NH4HPO + NH4SO4 + NH4Ox + NH4Cit + Struv ' STRUV is new
        STCa = Ca + CaPO4 + CaHPO4 + CaH2PO + CaSO4 + CaOx + 2 * Ca2Ox + CaCit + CaHCit
        STCa = STCa + CaOx2 + CaH2CT + CaCO3 + CaPP + CaHPP + CaOHPP + CaOH
        STMg = Mg + MgPO4 + MgHPO4 + MgH2PO + MgSO4 + MgOx + 2 * Mg2Ox + MgCit + MgHCit
        STMg = STMg + MgH2CT + MgOx2 + MgCO3 + Struv + MgOH + MgPP + MgOHPP
        STPO4 = PO4 + HPO4 + H2PO4 + H3PO4 + NaHPO4 + KHPO4 + CaPO4 + CaHPO4 + CaH2PO + MgPO4
        STPO4 = STPO4 + MgHPO4 + MgH2PO + NH4HPO + Struv
        STSO4 = SO4 + HSO4 + NaSO4 + KSO4 + CaSO4 + MgSO4 + NH4SO4
        STOx = Ox + HOx + CaOx + Ca2Ox + MgOx + Mg2Ox + NaOx + KOx + NH4Ox + 2 * CaOx2 + 2 * MgOx2
        STCit = Cit + HCit + H2Cit + H3Cit + NaCit + KCit + NH4Cit + CaCit + CaHCit + CaH2CT
        STCit = STCit + MgCit + MgHCit + MgH2CT
        STPP = PP + HPP + H2PP + H3PP + CaPP + CaHPP + CaOHPP + MgPP + MgOHPP + NaPP + NaHPP
        STPP = STPP + Na2PP + KPP + H4PP
        STU = HU + H2U + U
        STCO3 = CO2 + CO3 + HCO3 + H2CO3 + NaCO3 + Na2CO3 + CaCO3 + MgCO3
        
        If (TCa < 0.000000000000001) Then TCa = 0#
        If (TMg < 0.000000000000001) Then TMg = 0#
        If (TNH4 < 0.000000000000001) Then TNH4 = 0#
        If (TPO4 < 0.000000000000001) Then TPO4 = 0#
        If (TOx < 0.000000000000001) Then TOx = 0#
        If (TU < 0.000000000000001) Then TU = 0#
        If (TCit < 0.000000000000001) Then TCit = 0#
        
'        If (TNa < 0.000000000000001) Then TNa = 0#
'        If (TK < 0.000000000000001) Then TK = 0#
'        If (TSO4 < 0.000000000000001) Then TSO4 = 0#
'        If (TPP < 0.000000000000001) Then TPP = 0#
'        If (TCO2 < 0.000000000000001) Then TCO2 = 0#

        If (TNa <> 0#) Then
            Na = TNa * Na / STNa
        Else
            Na = 0#
        End If
        
        If (TK <> 0#) Then
            K = TK * K / STK
        Else
            K = 0#
        End If
        
        If (TCa <> 0#) Then
            Ca = TCa * Ca / STCa
        Else
            Ca = 0#
        End If
        
        If (TMg <> 0#) Then
            Mg = TMg * Mg / STMg
        Else
            Mg = 0#
        End If

        If (TNH4 <> 0#) Then
            NH4 = TNH4 * NH4 / STNH4
        Else
            NH4 = 0#
        End If

        If (TPO4 <> 0#) Then
            PO4 = TPO4 * PO4 / STPO4
        Else
            PO4 = 0#
        End If

        If (TSO4 <> 0#) Then
            SO4 = TSO4 * SO4 / STSO4
        Else
            SO4 = 0#
        End If

        If (TOx <> 0#) Then
            Ox = TOx * Ox / STOx
        Else
            Ox = 0#
        End If

        If (TCit <> 0#) Then
            Cit = TCit * Cit / STCit
        Else
            Cit = 0#
        End If

        If (TU <> 0#) Then
            U = TU * U / STU
        Else
            U = 0#
        End If

        TRIS = TTRIS / (1# + (P1X8 * H) / F1)
        HTRIS = (P1X8 * H * TRIS) / F1
        
        If (TPP <> 0#) Then
            PP = TPP * PP / STPP
        Else
            PP = 0#
        End If

        If (TCO2 <> 0#) Then
            CO2 = TCO2 * CO2 / STCO2
        Else
            CO2 = 0#
        End If
        
        If TCl = 0# Then
            Sum1 = Ca + Mg + Ca2Ox + Mg2Ox - (SO4 + CaOx2 + Ox + HCit + HPO4 + NaCit + KCit + NH4Cit)
            Cl = H + Na + K + NH4 + CaH2PO + CaH2CT + MgH2PO + MgH2CT + 2! * Sum1
            Cl = Cl - HU - H2PO4 - HSO4 - HOx - H2Cit - NaHPO4 - NaSO4 - NaOx - KHPO4 - KSO4 - KOx
            Cl = Cl - CaPO4 - CaCit - MgPO4 - MgCit - NH4PO4 - NH4Ox - 3! * (Cit + PO4)
            Cl = Cl + HTRIS - 2! * (CaOx2 + MgOx2) - 3! * (NaPP + KPP + MgOHPP)
            Sum2 = 4! * PP + 3! * CaOHPP + 2! * (H2PP + CaPP) + H3PP + CaHPP
            Cl = Cl - 2! * (Na2PP + NaHPP + MgPP) - NaU - KU - NH4U - 2 * U - Sum2 - HCO3 - CO3 - NaCO3
            TCl = Cl
        End If
        
        S1 = (H + OH) / F1 + Na + K + NH4 + HU + Cl + NaHPO4 + NaSO4 + NaOx + NaCO3 + KHPO4
        S1 = S1 + KSO4 + KOx + NH4PO4 + NH4SO4 + NH4Ox + CaPO4 + CaH2PO + CaCit + CaH2CT + CaHPP
        S1 = S1 + CaOH + H2PO4 + HCO3 + HSO4 + HOx + H2Cit + H3PP + HTRIS + NaU + KU + NH4U
        S2 = Ca + Mg + SO4 + Ox + CO3 + NaCit + Na2PP + KCit + NH4Cit + CaPP + NaHPP
        S2 = S2 + MgPP + HPO4 + HCit + H2PP + Ca2Ox + Mg2Ox + CaOx2 + MgOx2 + U
        S2 = 4# * S2
        S3 = 9# * (PO4 + Cit + NaPP + KPP + HPP + CaOHPP + MgOHPP)
        S4 = 16# * PP
        s = (S1 + S2 + S3 + S4) / 2#
        If s > 1# Then s = 1#
        If s < 0.000001 Then s = 0.000001
        SS = Sqr(s)
        F1 = Exp(-1.20218 * ((SS / (1# + SS)) - 0.285 * s))
        F2 = F1 ^ 4#
        F3 = F1 ^ 9#
        F4 = F1 ^ 16#
        M = 0
        
        If (Ca <> 0#) Then
            T = Abs((Ca - OldCa) / Ca)
            If (T > 0.0001) Then M = 1
        End If
        If (Mg <> 0#) Then
            T = Abs((Mg - OldMg) / Mg)
            If (T > 0.0001) Then M = 1
        End If
        If (PO4 <> 0#) Then
            T = Abs((PO4 - OldPO4) / PO4)
            If (T > 0.0001) Then M = 1
        End If
        If (Ox <> 0#) Then
            T = Abs((Ox - OldOx) / Ox)
            If (T > 0.0001) Then M = 1
        End If
        If (Cit <> 0#) Then
            T = Abs((Cit - OldCit) / Cit)
            If (T > 0.0001) Then M = 1
        End If
        If (CO2 <> 0#) Then
            T = Abs((CO2 - OldCO2) / CO2)
            If (T > 0.0001) Then M = 1
        End If
        
        OldCa = Ca
        OldMg = Mg
        OldPO4 = PO4
        OldOx = Ox
        OldCit = Cit
        OldCO2 = CO2
        
        NEQUAL = NEQUAL + 1

        If (NEQUAL > 500) Then
            intErr = 3
            Exit Sub
        End If
    
        NCTC = NCTC + 1
    
    Loop While M = 1

    RCaOx = CaOx / (0.00000616)
    
    AP = 1#
    If (Ca < 0.0000000001) Then AP = 0#
    If (PO4 < 0.0000000001) Then AP = 0#

    Brush = Ca * HPO4 * F2 * F2
    
    ZZZ = 9.999999E-21
    
    RAP = AP / ZZZ
    
    RBrush = Brush / 0.0000003981
    RStruv = Struv / 0.000000000000071
    RSU = H2U / (0.000261)
    
    ' Not used any more
    RCaOH2 = Ca * (OH ^ 2) * F2 / 0.0000069183
    RMgOH2 = Mg * (OH ^ 2) * F2 / 0.00000000001122
    RWhit = 1#
    If Ca < 0.0000000001 Then RWhit = 0#
    If PO4 < 0.0000000001 Then RWhit = 0#
    If RWhit > 0# Then RWhit = 0#
    RMgPO4 = 1#
    If Mg < 0.0000000001 Then RMgPO4 = 0#
    If PO4 < 0.0000000001 Then RMgPO4 = 0#
    If RMgPO4 > 0 Then RMgPO4 = 0#

    ' Save output variables
    ' Activity products
    varAPCaOx = CaOx
    varAPBr = Brush
    varAPStru = Struv
    varAPUA = H2U
    varAPNaU = NaU
    ' Saturations (RSRs)
    varRSRCaOx = RCaOx
    varRSRBr = RBrush
    varRSRStru = RStruv
    varRSRUA = RSU
    ' Total concentrations
    varTCa = TCa
    varTP = TPO4
    varTOx = TOx
    varTNa = TNa
    varTK = TK
    varTMg = TMg
    varTNH4 = TNH4
    varTCit = TCit
    varTSO4 = TSO4
    varTUA = TU
    varTCl = TCl
    varTCO2 = TCO2
    varTPP = TPP
    varTTRIS = TTRIS
    
    ' Ionic Strength
    varIonicStrength = s
    ' Factors
    varF1 = F1
    varF2 = F2
    varF3 = F3
    varF4 = F4
    ' Ionic Species
    varISHPO4 = HPO4
    varISH2PO4 = H2PO4
    varISH3PO4 = H3PO4
    varISH2CO3 = H2CO3
    varISHCO3 = HCO3
    varISCO3 = CO3
    varISNaCO3 = NaCO3
    varISNa2CO3 = Na2CO3
    varISCaCO3 = CaCO3
    varISMgCO3 = MgCO3
    varISHSO4 = HSO4
    varISHOx = HOx
    varISHCit = HCit
    varISH2Cit = H2Cit
    varISH3Cit = H3Cit
    varISH2U = H2U
    varISHPP = HPP
    varISH2PP = H2PP
    varISH3PP = H3PP
    varISH4PP = H4PP
    varISNaHPO4 = NaHPO4
    varISNaSO4 = NaSO4
    varISNaOx = NaOx
    varISNaCit = NaCit
    varISNaPP = NaPP
    varISNa2PP = Na2PP
    varISNaHPP = NaHPP
    varISKHPO4 = KHPO4
    varISKSO4 = KSO4
    varISKOx = KOx
    varISKCit = KCit
    varISKPP = KPP
    varISCaPO4 = CaPO4
    varISCaHPO4 = CaHPO4
    varISCaH2PO4 = CaH2PO
    varISCaSO4 = CaSO4
    varISCaOx = CaOx
    varISCa2Ox = Ca2Ox
    varISCaOx2 = CaOx2
    varISCaCit = CaCit
    varISCaHCit = CaHCit
    varISCaH2Cit = CaH2CT
    varISCaPP = CaPP
    varISCaHPP = CaHPP
    varISCaOHPP = CaOHPP
    varISCaOH = CaOH
    varISMgPO4 = MgPO4
    varISMgHPO4 = MgHPO4
    varISMgH2PO4 = MgH2PO
    varISMgSO4 = MgSO4
    varISMgOx = MgOx
    varISMg2Ox = Mg2Ox
    varISMgOx2 = MgOx2
    varISMgCit = MgCit
    varISMgHCit = MgHCit
    varISMgH2Cit = MgH2CT
    varISMgPP = MgPP
    varISMgOHPP = MgOHPP
    varISMgOH = MgOH
    varISNH4HPO4 = NH4HPO
    varISNH4SO4 = NH4SO4
    varISNH4Ox = NH4Ox
    varISNH4Cit = NH4Cit
    varISNa = Na
    varISK = K
    varISCa = Ca
    varISMg = Mg
    varISNH4 = NH4
    varISPO4 = PO4
    varISSO4 = SO4
    varISOx = Ox
    varISCit = Cit
    varISHU = HU
    varISCl = Cl
    varISPP = PP
    varISCO2 = CO2
    ' convert H2U to mg/day from moles/liter
'    H2U = H2U * 166400# * Vol
    varH2U = H2U
    
End Sub

Public Property Get pH() As Variant

    pH = varpH
    
End Property

Public Property Let pH(ByVal vNewValue As Variant)

    If IsNumeric(vNewValue) Then
        varpH = vNewValue
    Else
        varpH = Empty
    End If
    
End Property

Public Property Get Vol() As Variant

    Vol = varVol
    
End Property

Public Property Let Vol(ByVal vNewValue As Variant)

    If IsNumeric(vNewValue) Then
        varVol = vNewValue
    Else
        varVol = Empty
    End If
    
End Property

Public Property Get Ca() As Variant

    Ca = varCa
    
End Property

Public Property Let Ca(ByVal vNewValue As Variant)

    If IsNumeric(vNewValue) Then
        varCa = vNewValue
    Else
        varCa = Empty
    End If
    
End Property

Public Property Get CO2() As Variant

    CO2 = varCO2
    
End Property

Public Property Let CO2(ByVal vNewValue As Variant)

    If IsNumeric(vNewValue) Then
        varCO2 = vNewValue
    Else
        varCO2 = Empty
    End If
    
End Property

Public Property Get P() As Variant

    P = varP
    
End Property

Public Property Let P(ByVal vNewValue As Variant)

    If IsNumeric(vNewValue) Then
        varP = vNewValue
    Else
        varP = Empty
    End If
    
End Property

Public Property Get Ox() As Variant

    Ox = varOx
    
End Property

Public Property Let Ox(ByVal vNewValue As Variant)

    If IsNumeric(vNewValue) Then
        varOx = vNewValue
    Else
        varOx = Empty
    End If
    
End Property

Public Property Get Na() As Variant

    Na = varNa
    
End Property

Public Property Let Na(ByVal vNewValue As Variant)

    If IsNumeric(vNewValue) Then
        varNa = vNewValue
    Else
        varNa = Empty
    End If
    
End Property

Public Property Get K() As Variant

    K = varK
    
End Property

Public Property Let K(ByVal vNewValue As Variant)

    If IsNumeric(vNewValue) Then
        varK = vNewValue
    Else
        varK = Empty
    End If
    
End Property

Public Property Get Mg() As Variant

    Mg = varMg
    
End Property

Public Property Let Mg(ByVal vNewValue As Variant)

    If IsNumeric(vNewValue) Then
        varMg = vNewValue
    Else
        varMg = Empty
    End If
    
End Property

Public Property Get NH4() As Variant

    NH4 = varNH4
    
End Property

Public Property Let NH4(ByVal vNewValue As Variant)

    If IsNumeric(vNewValue) Then
        varNH4 = vNewValue
    Else
        varNH4 = Empty
    End If
    
End Property

Public Property Get Cit() As Variant

    Cit = varCit
    
End Property

Public Property Let Cit(ByVal vNewValue As Variant)

    If IsNumeric(vNewValue) Then
        varCit = vNewValue
    Else
        varCit = Empty
    End If
    
End Property

Public Property Get SO4() As Variant

    SO4 = varSO4
    
End Property

Public Property Let SO4(ByVal vNewValue As Variant)

    If IsNumeric(vNewValue) Then
        varSO4 = vNewValue
    Else
        varSO4 = Empty
    End If
    
End Property

Public Property Get UA() As Variant

    UA = varUA
    
End Property

Public Property Let UA(ByVal vNewValue As Variant)

    If IsNumeric(vNewValue) Then
        varUA = vNewValue
    Else
        varUA = Empty
    End If
    
End Property

Public Property Get Cl() As Variant

    Cl = varCl
    
End Property

Public Property Let Cl(ByVal vNewValue As Variant)

    If IsNumeric(vNewValue) Then
        varCl = vNewValue
    Else
        varCl = Empty
    End If
    
End Property

Public Property Get PP() As Variant

    PP = varPP
    
End Property

Public Property Let PP(ByVal vNewValue As Variant)

    If IsNumeric(vNewValue) Then
        varPP = vNewValue
    Else
        varPP = Empty
    End If
    
End Property

Public Property Get TRIS() As Variant

    TRIS = varTRIS
    
End Property

Public Property Let TRIS(ByVal vNewValue As Variant)

    If IsNumeric(vNewValue) Then
        varTRIS = vNewValue
    Else
        varTRIS = Empty
    End If
    
End Property

Public Property Get RSRCaOx() As Variant

    RSRCaOx = varRSRCaOx
    
End Property

Public Property Get RSRBr() As Variant

    RSRBr = varRSRBr
    
End Property

Public Property Get RSRUA() As Variant

    RSRUA = varRSRUA
    
End Property

Public Property Get RSRStruv() As Variant

    RSRStruv = varRSRStru
    
End Property

Public Property Get IonicStrength() As Variant

    IonicStrength = varIonicStrength

End Property

Public Property Get Err() As Variant

    Err = intErr
    
End Property

Public Sub Reset()

    varpH = Empty
    varVol = Empty
    varCa = Empty
    varP = Empty
    varOx = Empty
    varNa = Empty
    varK = Empty
    varMg = Empty
    varNH4 = Empty
    varCit = Empty
    varSO4 = Empty
    varUA = Empty
    varCl = Empty
    varCO2 = Empty
    varPP = Empty
    varTRIS = Empty
    ' Activity Products
    varAPCaOx = Empty    ' Moles squared
    varAPBr = Empty
    varAPStru = Empty
    varAPUA = Empty
    varAPNaU = Empty
    ' Relative Saturation Ratio's
    varRSRCaOx = Empty
    varRSRBr = Empty
    varRSRStru = Empty
    varRSRUA = Empty
    ' Undissociated Uric Acid
    varH2U = Empty       ' mg/day
    ' Total concentrations, mol/L
    varTCa = Empty
    varTP = Empty
    varTOx = Empty
    varTNa = Empty
    varTK = Empty
    varTMg = Empty
    varTNH4 = Empty
    varTCit = Empty
    varTSO4 = Empty
    varTUA = Empty
    varTCl = Empty
    varTCO2 = Empty
    varTPP = Empty
    varTTRIS = Empty
    ' Ionic Strength
    varIonicStrength = Empty
    ' Ionic Species
    varISNa = Empty
    varISK = Empty
    varISCa = Empty
    varISMg = Empty
    varISNH4 = Empty
    varISPO4 = Empty
    varISSO4 = Empty
    varISOx = Empty
    varISCit = Empty
    varISHU = Empty
    varISCl = Empty
    varISPP = Empty
    varISCO2 = Empty
    varISH2O = Empty
    varISHPO4 = Empty
    varISH2PO4 = Empty
    varISH3PO4 = Empty
    varISH2CO3 = Empty
    varISHCO3 = Empty
    varISCO3 = Empty
    varISNaCO3 = Empty
    varISNa2CO3 = Empty
    varISCaCO3 = Empty
    varISMgCO3 = Empty
    varISHSO4 = Empty
    varISHOx = Empty
    varISHCit = Empty
    varISH2Cit = Empty
    varISH3Cit = Empty
    varISH2U = Empty
    varISHPP = Empty
    varISH2PP = Empty
    varISH3PP = Empty
    varISH4PP = Empty
    varISNaHPO4 = Empty
    varISNaSO4 = Empty
    varISNaOx = Empty
    varISNaCit = Empty
    varISNaPP = Empty
    varISNa2PP = Empty
    varISNaHPP = Empty
    varISKHPO4 = Empty
    varISKSO4 = Empty
    varISKOx = Empty
    varISKCit = Empty
    varISKPP = Empty
    varISCaPO4 = Empty
    varISCaHPO4 = Empty
    varISCaH2PO4 = Empty
    varISCaSO4 = Empty
    varISCaOx = Empty
    varISCa2Ox = Empty
    varISCaOx2 = Empty
    varISCaCit = Empty
    varISCaHCit = Empty
    varISCaH2Cit = Empty
    varISCaPP = Empty
    varISCaHPP = Empty
    varISCaOHPP = Empty
    varISCaOH = Empty
    varISMgPO4 = Empty
    varISMgHPO4 = Empty
    varISMgH2PO4 = Empty
    varISMgSO4 = Empty
    varISMgOx = Empty
    varISMg2Ox = Empty
    varISMgOx2 = Empty
    varISMgCit = Empty
    varISMgHCit = Empty
    varISMgH2Cit = Empty
    varISMgPP = Empty
    varISMgOHPP = Empty
    varISMgOH = Empty
    varISNH4HPO4 = Empty
    varISNH4SO4 = Empty
    varISNH4Ox = Empty
    varISNH4Cit = Empty
    varF1 = Empty
    varF2 = Empty
    varF3 = Empty
    varF4 = Empty
    intErr = 0
    
End Sub

Public Property Get Species(intIndex As Integer) As Variant

    Select Case intIndex
        Case 1
            Species = varpH
        Case 2
            Species = varVol
        Case 3
            Species = varTCa
        Case 4
            Species = varTMg
        Case 5
            Species = varTP
        Case 6
            Species = varTNa
        Case 7
            Species = varTK
        Case 8
            Species = varTNH4
        Case 9
            Species = varTCit
        Case 10
            Species = varTOx
        Case 11
            Species = varTSO4
        Case 12
            Species = varTUA
        Case 13
            Species = varTCl
        Case 14
            Species = varTCO2
        Case 15
            Species = varIonicStrength
        Case 16
            Species = varISHPO4
        Case 17
            Species = varISH2PO4
        Case 18
            Species = varISH3PO4
        Case 19
            Species = varISH2CO3
        Case 20
            Species = varISHCO3
        Case 21
            Species = varISNaCO3
        Case 22
            Species = varISNa2CO3
        Case 23
            Species = varISCaCO3
        Case 24
            Species = varISMgCO3
        Case 25
            Species = varISHSO4
        Case 26
            Species = varISHOx
        Case 27
            Species = varISHCit
        Case 28
            Species = varISH2Cit
        Case 29
            Species = varISH3Cit
        Case 30
            Species = varISH2U
        Case 31
            Species = varISHPP
        Case 32
            Species = varISH2PP
        Case 33
            Species = varISH3PP
        Case 34
            Species = varISH4PP
        Case 35
            Species = varISNaHPO4
        Case 36
            Species = varISNaSO4
        Case 37
            Species = varISNaOx
        Case 38
            Species = varISNaCit
        Case 39
            Species = varISNaPP
        Case 40
            Species = varISNa2PP
        Case 41
            Species = varISNaHPP
        Case 42
            Species = varISKHPO4
        Case 43
            Species = varISKSO4
        Case 44
            Species = varISKOx
        Case 45
            Species = varISKCit
        Case 46
            Species = varISKPP
        Case 47
            Species = varISCaPO4
        Case 48
            Species = varISCaHPO4
        Case 49
            Species = varISCaH2PO4
        Case 50
            Species = varISCaSO4
        Case 51
            Species = varISCaOx
        Case 52
            Species = varISCa2Ox
        Case 53
            Species = varISCaOx2
        Case 54
            Species = varISCaCit
        Case 55
            Species = varISCaHCit
        Case 56
            Species = varISCaH2Cit
        Case 57
            Species = varISCaPP
        Case 58
            Species = varISCaHPP
        Case 59
            Species = varISCaOHPP
        Case 60
            Species = varISCaOH
        Case 61
            Species = varISMgPO4
        Case 62
            Species = varISMgHPO4
        Case 63
            Species = varISMgH2PO4
        Case 64
            Species = varISMgSO4
        Case 65
            Species = varISMgOx
        Case 66
            Species = varISMg2Ox
        Case 67
            Species = varISMgOx2
        Case 68
            Species = varISMgCit
        Case 69
            Species = varISMgHCit
        Case 70
            Species = varISMgH2Cit
        Case 71
            Species = varISMgPP
        Case 72
            Species = varISMgOHPP
        Case 73
            Species = varISMgOH
        Case 74
            Species = varISNH4HPO4
        Case 75
            Species = varISNH4SO4
        Case 76
            Species = varISNH4Ox
        Case 77
            Species = varISNH4Cit
        Case 78
            Species = varISNa
        Case 79
            Species = varISK
        Case 80
            Species = varISCa
        Case 81
            Species = varISMg
        Case 82
            Species = varISNH4
        Case 83
            Species = varISPO4
        Case 84
            Species = varISSO4
        Case 85
            Species = varISOx
        Case 86
            Species = varISCit
        Case 87
            Species = varISHU
        Case 88
            Species = varISCl
        Case 89
            Species = varISPP
        Case 90
            Species = varISCO2
        Case 91
            Species = varF1
        Case 92
            Species = varF2
        Case 93
            Species = varF3
        Case 94
            Species = varF4
        Case 95
            Species = varAPCaOx
        Case 96
            Species = varAPBr
        Case 97
            Species = varAPStru
        Case 98
            Species = varAPUA
        Case 99
            Species = varAPNaU
        Case 100
            Species = varRSRCaOx
        Case 101
            Species = varRSRBr
        Case 102
            Species = varRSRStru
        Case 103
            Species = varRSRUA
        Case Else
            Species = Null
    End Select

End Property
```
