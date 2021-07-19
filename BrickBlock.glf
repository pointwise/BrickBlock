#############################################################################
#
# (C) 2021 Cadence Design Systems, Inc. All rights reserved worldwide.
#
# This sample script is not supported by Cadence Design Systems, Inc.
# It is provided freely for demonstration purposes only.
# SEE THE WARRANTY DISCLAIMER AT THE BOTTOM OF THIS FILE.
#
#############################################################################

###############################################################################
##
## BrickBlock.glf
##
## Script with Tk interface to create a rectangular structured block
##
###############################################################################

package require PWI_Glyph 2

# enable Tk in Glyph 2
pw::Script loadTk

# set some default input values
set xyz1 "0 0 0"
set xyz2 "10 10 10"
set dimi 10
set dimj 10
set dimk 10

############################################################################
# checkInputStatus: check that all required parameters are valid
############################################################################
proc checkInputStatus { } {
  global BrickBlock
  if {0 == $BrickBlock(xyz1) || 0 == $BrickBlock(xyz2) || \
      0 == $BrickBlock(iDim) || 0 == $BrickBlock(jDim) || \
      0 == $BrickBlock(kDim)} {
    $BrickBlock(okButton) configure -state disabled
  } else {
    $BrickBlock(okButton) configure -state normal
  }
}

############################################################################
# makeConnector: create a dimensioned 2 point connector
############################################################################
proc makeConnector { pt1 pt2 dim } {
  set s [pw::SegmentSpline create]
  $s addPoint $pt1
  $s addPoint $pt2
  set c [pw::Connector create]
  $c addSegment $s
  $c setDimension $dim
  return $c
}

############################################################################
# makeRectangularPrism: Generates a block
############################################################################
proc makeRectangularPrism { x1 y1 z1 x2 y2 z2 {dx 10} {dy 10} {dz 10} } {

  if { $x1 == $x2 || $y1 == $y2 || $z1 == $z2 } {
    tk_messageBox -icon error -title "Error..." -message [concat \
    "Cannot create block with any opposite corner x,y,z values equal " \
    "(zero volume).\n" \
    "Please modify either the min coordinate or the max coordinate."] -type ok
    return 0;
  }

  set creator [pw::Application begin Create]

  if { [catch {
    set con(0,0,2) [makeConnector [list $x1 $y1 $z1] [list $x1 $y1 $z2] $dz]
    set con(1,1,2) [makeConnector [list $x2 $y2 $z1] [list $x2 $y2 $z2] $dz]
    set con(0,1,2) [makeConnector [list $x1 $y2 $z1] [list $x1 $y2 $z2] $dz]
    set con(1,0,2) [makeConnector [list $x2 $y1 $z1] [list $x2 $y1 $z2] $dz]

    set con(0,2,0) [makeConnector [list $x1 $y1 $z1] [list $x1 $y2 $z1] $dy]
    set con(1,2,1) [makeConnector [list $x2 $y1 $z2] [list $x2 $y2 $z2] $dy]
    set con(0,2,1) [makeConnector [list $x1 $y1 $z2] [list $x1 $y2 $z2] $dy]
    set con(1,2,0) [makeConnector [list $x2 $y1 $z1] [list $x2 $y2 $z1] $dy]

    set con(2,0,0) [makeConnector [list $x1 $y1 $z1] [list $x2 $y1 $z1] $dx]
    set con(2,1,1) [makeConnector [list $x1 $y2 $z2] [list $x2 $y2 $z2] $dx]
    set con(2,0,1) [makeConnector [list $x1 $y1 $z2] [list $x2 $y1 $z2] $dx]
    set con(2,1,0) [makeConnector [list $x1 $y2 $z1] [list $x2 $y2 $z1] $dx]

    set dom(0) [pw::DomainStructured createFromConnectors \
        [list $con(2,0,0) $con(0,0,2) $con(2,0,1) $con(1,0,2)] ]

    set dom(1) [pw::DomainStructured createFromConnectors \
        [list $con(2,1,0) $con(0,1,2) $con(2,1,1) $con(1,1,2)] ]

    set dom(2) [pw::DomainStructured createFromConnectors \
        [list $con(0,2,0) $con(2,0,0) $con(1,2,0) $con(2,1,0)] ]

    set dom(3) [pw::DomainStructured createFromConnectors \
        [list $con(0,2,1) $con(2,0,1) $con(1,2,1) $con(2,1,1)] ]

    set dom(4) [pw::DomainStructured createFromConnectors \
        [list $con(0,2,0) $con(0,0,2) $con(0,2,1) $con(0,1,2)] ]

    set dom(5) [pw::DomainStructured createFromConnectors \
        [list $con(1,2,0) $con(1,0,2) $con(1,2,1) $con(1,1,2)] ]

    set blk [pw::BlockStructured createFromDomains \
        [list $dom(0) $dom(1) $dom(2) $dom(3) $dom(4) $dom(5)]]

  } retVal] == 1 } {
    tk_messageBox -icon error -title "Error..." -message [concat \
        "Could not create a block with these min max coordinates.\n" \
        "All intermediate entities will be deleted.\n" $retVal] -type ok

    # Abort the creation mode
    $creator abort
  } else {

    # End the creation mode
    $creator end
  }
  return 1;
}

############################################################################
# isCoordinate: Check that a string is a valid XYZ coordinate
############################################################################
proc isCoordinate { str } {
  global errorCode
  set a "?"
  set x "?"
  set y "?"
  set z "?"
  set re {^\s*([-.eE0-9]+)[, ]+([-.eE0-9]+)[, ]+([-.eE0-9]+)\s*$}
  catch { regexp $re $str a x y z }
  if {[string is double $x] == 0 || [string is double $y] == 0 || \
      [string is double $z] == 0 } {
    set st 0
  } else {
    set st 1
  }
  return $st
}

############################################################################
# checkCoordinateInput: Check that widget field contains a valid XYZ coord
############################################################################
proc checkCoordinateInput { w var text action } {
  global BrickBlock

  # Ignore force validations
  if {$action == -1} {
    return 1
  }

  if {![isCoordinate $text]} {
    set BrickBlock($var) 0
    $w configure -bg "#FFCCCC"
  } else {
    set BrickBlock($var) 1
    $w configure -bg "#FFFFFF"
  }

  checkInputStatus
  return 1
}

############################################################################
# checkIntegerInput: Check that a widget field contains a valid integer
############################################################################
proc checkIntegerInput { w var text action } {
  global BrickBlock

  # Ignore force validations
  if {$action == -1} {
    return 1
  }

  if {![string is integer $text] || 2 > $text} {
    set BrickBlock($var) 0
    $w configure -bg "#FFCCCC"
  } else {
    set BrickBlock($var) 1
    $w configure -bg "#FFFFFF"
  }

  checkInputStatus
  return 1
}

############################################################################
# makeInputField: create a Tk text widget
############################################################################
proc makeInputField { parent name title variable {width 7} {valid ""}} {
  label .lbl$name -text $title
  entry .ent$name -textvariable $variable -width $width
  if { [string compare $valid ""]!=0 } {
    .ent$name configure -validate all
    .ent$name configure -validatecommand $valid
  }

  set row [lindex [grid size $parent] 1]
  grid .lbl$name -row $row -column 0 -sticky e -in $parent
  grid .ent$name -row $row -column 1 -sticky w -in $parent
  grid columnconfigure $parent "0 1" -weight 1

  return $parent.$name
}

############################################################################
# create: make the brick block
############################################################################
proc create { } {
  global xyz1 xyz2 dimi dimj dimk
  set re {^\s*([-.eE0-9]+)[, ]+([-.eE0-9]+)[, ]+([-.eE0-9]+)\s*$}
  regexp $re $xyz1 a x y z
  regexp $re $xyz2 a x1 y1 z1
  return [makeRectangularPrism $x $y $z $x1 $y1 $z1 $dimi $dimj $dimk]
}

############################################################################
# makeWindow: create the Tk script window
############################################################################
proc makeWindow { } {
  global BrickBlock logo
  wm title . "Brick Block"
  label .title -text "Draw Brick Block"
  set font [.title cget -font]
  set fontSize [font actual $font -size]
  set wfont [font create -family [font actual $font -family] -weight bold \
    -size [expr {int(1.5 * $fontSize)}]]
  .title configure -font $wfont
  pack .title -expand 1 -side top

  pack [frame .hr1 -relief sunken -height 2 -bd 1] \
        -side top -padx 2 -fill x -pady 1
  pack [frame .inputs] -fill x -padx 2

  makeInputField .inputs coord1 "Pt (1,1,1):" xyz1 10 [list \
        checkCoordinateInput %W xyz1 %P %d]
  makeInputField .inputs coord2 "Pt (I,J,K):" xyz2 10 [list \
        checkCoordinateInput %W xyz2 %P %d]

  makeInputField .inputs di "Dimension-i:" dimi 10 [list \
        checkIntegerInput %W iDim %P %d]
  makeInputField .inputs dj "Dimension-j:" dimj 10 [list \
        checkIntegerInput %W jDim %P %d]
  makeInputField .inputs dk "Dimension-k:" dimk 10 [list \
        checkIntegerInput %W kDim %P %d]

  pack [frame .hr2 -relief sunken -height 2 -bd 1] \
        -side top -padx 2 -fill x -pady 1

  pack [frame .buttons] -fill x -padx 2 -pady 1
  pack [button .buttons.cancel -text "Cancel" -command { exit }] \
        -side right -padx 2
  pack [button .buttons.ok -text "OK" -command {create; exit;}] \
        -side right -padx 2
  set BrickBlock(okButton) .buttons.ok
  set BrickBlock(xyz1) 1
  set BrickBlock(xyz2) 1
  set BrickBlock(iDim) 1
  set BrickBlock(jDim) 1
  set BrickBlock(kDim) 1

  pack [label .buttons.logo -image [cadenceLogo] -bd 0 -relief flat] \
    -side left -padx 5

  bind . <KeyPress-Escape> { .buttons.cancel invoke }
  bind . <Control-KeyPress-Return> { .buttons.ok invoke }
}

proc cadenceLogo {} {
  set logoData "
R0lGODlhgAAYAPQfAI6MjDEtLlFOT8jHx7e2tv39/RYSE/Pz8+Tj46qoqHl3d+vq62ZjY/n4+NT
T0+gXJ/BhbN3d3fzk5vrJzR4aG3Fubz88PVxZWp2cnIOBgiIeH769vtjX2MLBwSMfIP///yH5BA
EAAB8AIf8LeG1wIGRhdGF4bXD/P3hwYWNrZXQgYmVnaW49Iu+7vyIgaWQ9Ilc1TTBNcENlaGlIe
nJlU3pOVGN6a2M5ZCI/PiA8eDp4bXBtdGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1w
dGs9IkFkb2JlIFhNUCBDb3JlIDUuMC1jMDYxIDY0LjE0MDk0OSwgMjAxMC8xMi8wNy0xMDo1Nzo
wMSAgICAgICAgIj48cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudy5vcmcvMTk5OS8wMi
8yMi1yZGYtc3ludGF4LW5zIyI+IDxyZGY6RGVzY3JpcHRpb24gcmY6YWJvdXQ9IiIg/3htbG5zO
nhtcE1NPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vIiB4bWxuczpzdFJlZj0iaHR0
cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL3NUcGUvUmVzb3VyY2VSZWYjIiB4bWxuczp4bXA9Imh
0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD0idX
VpZDoxMEJEMkEwOThFODExMUREQTBBQzhBN0JCMEIxNUM4NyB4bXBNTTpEb2N1bWVudElEPSJ4b
XAuZGlkOkIxQjg3MzdFOEI4MTFFQjhEMv81ODVDQTZCRURDQzZBIiB4bXBNTTpJbnN0YW5jZUlE
PSJ4bXAuaWQ6QjFCODczNkZFOEI4MTFFQjhEMjU4NUNBNkJFRENDNkEiIHhtcDpDcmVhdG9yVG9
vbD0iQWRvYmUgSWxsdXN0cmF0b3IgQ0MgMjMuMSAoTWFjaW50b3NoKSI+IDx4bXBNTTpEZXJpZW
RGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6MGE1NjBhMzgtOTJiMi00MjdmLWE4ZmQtM
jQ0NjMzNmNjMWI0IiBzdFJlZjpkb2N1bWVudElEPSJ4bXAuZGlkOjBhNTYwYTM4LTkyYjItNDL/
N2YtYThkLTI0NDYzMzZjYzFiNCIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g
6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PgH//v38+/r5+Pf29fTz8vHw7+7t7Ovp6Ofm5e
Tj4uHg397d3Nva2djX1tXU09LR0M/OzczLysnIx8bFxMPCwcC/vr28u7q5uLe2tbSzsrGwr66tr
KuqqainpqWko6KhoJ+enZybmpmYl5aVlJOSkZCPjo2Mi4qJiIeGhYSDgoGAf359fHt6eXh3dnV0
c3JxcG9ubWxramloZ2ZlZGNiYWBfXl1cW1pZWFdWVlVUU1JRUE9OTUxLSklIR0ZFRENCQUA/Pj0
8Ozo5ODc2NTQzMjEwLy4tLCsqKSgnJiUkIyIhIB8eHRwbGhkYFxYVFBMSERAPDg0MCwoJCAcGBQ
QDAgEAACwAAAAAgAAYAAAF/uAnjmQpTk+qqpLpvnAsz3RdFgOQHPa5/q1a4UAs9I7IZCmCISQwx
wlkSqUGaRsDxbBQer+zhKPSIYCVWQ33zG4PMINc+5j1rOf4ZCHRwSDyNXV3gIQ0BYcmBQ0NRjBD
CwuMhgcIPB0Gdl0xigcNMoegoT2KkpsNB40yDQkWGhoUES57Fga1FAyajhm1Bk2Ygy4RF1seCjw
vAwYBy8wBxjOzHq8OMA4CWwEAqS4LAVoUWwMul7wUah7HsheYrxQBHpkwWeAGagGeLg717eDE6S
4HaPUzYMYFBi211FzYRuJAAAp2AggwIM5ElgwJElyzowAGAUwQL7iCB4wEgnoU/hRgIJnhxUlpA
SxY8ADRQMsXDSxAdHetYIlkNDMAqJngxS47GESZ6DSiwDUNHvDd0KkhQJcIEOMlGkbhJlAK/0a8
NLDhUDdX914A+AWAkaJEOg0U/ZCgXgCGHxbAS4lXxketJcbO/aCgZi4SC34dK9CKoouxFT8cBNz
Q3K2+I/RVxXfAnIE/JTDUBC1k1S/SJATl+ltSxEcKAlJV2ALFBOTMp8f9ihVjLYUKTa8Z6GBCAF
rMN8Y8zPrZYL2oIy5RHrHr1qlOsw0AePwrsj47HFysrYpcBFcF1w8Mk2ti7wUaDRgg1EISNXVwF
lKpdsEAIj9zNAFnW3e4gecCV7Ft/qKTNP0A2Et7AUIj3ysARLDBaC7MRkF+I+x3wzA08SLiTYER
KMJ3BoR3wzUUvLdJAFBtIWIttZEQIwMzfEXNB2PZJ0J1HIrgIQkFILjBkUgSwFuJdnj3i4pEIlg
eY+Bc0AGSRxLg4zsblkcYODiK0KNzUEk1JAkaCkjDbSc+maE5d20i3HY0zDbdh1vQyWNuJkjXnJ
C/HDbCQeTVwOYHKEJJwmR/wlBYi16KMMBOHTnClZpjmpAYUh0GGoyJMxya6KcBlieIj7IsqB0ji
5iwyyu8ZboigKCd2RRVAUTQyBAugToqXDVhwKpUIxzgyoaacILMc5jQEtkIHLCjwQUMkxhnx5I/
seMBta3cKSk7BghQAQMeqMmkY20amA+zHtDiEwl10dRiBcPoacJr0qjx7Ai+yTjQvk31aws92JZ
Q1070mGsSQsS1uYWiJeDrCkGy+CZvnjFEUME7VaFaQAcXCCDyyBYA3NQGIY8ssgU7vqAxjB4EwA
DEIyxggQAsjxDBzRagKtbGaBXclAMMvNNuBaiGAAA7"

  return [image create photo -format GIF -data $logoData]
}

# create the Tk window and place it
makeWindow
::tk::PlaceWindow . widget

# process Tk events until the window is destroyed
tkwait window .

#############################################################################
#
# This file is licensed under the Cadence Public License Version 1.0 (the
# "License"), a copy of which is found in the included file named "LICENSE",
# and is distributed "AS IS." TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE
# LAW, CADENCE DISCLAIMS ALL WARRANTIES AND IN NO EVENT SHALL BE LIABLE TO
# ANY PARTY FOR ANY DAMAGES ARISING OUT OF OR RELATING TO USE OF THIS FILE.
# Please see the License for the full text of applicable terms.
#
#############################################################################
