#
# Copyright 2009 (c) Pointwise, Inc.
# All rights reserved.
# 
# This sample Pointwise script is not supported by Pointwise, Inc.
# It is provided freely for demonstration purposes only.  
# SEE THE WARRANTY DISCLAIMER AT THE BOTTOM OF THIS FILE.
#

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

  pack [label .buttons.logo -image [pwLogo] -bd 0 -relief flat] \
    -side left -padx 5

  bind . <KeyPress-Escape> { .buttons.cancel invoke }
  bind . <Control-KeyPress-Return> { .buttons.ok invoke }
}

proc pwLogo {} {
  set logoData "
R0lGODlheAAYAIcAAAAAAAICAgUFBQkJCQwMDBERERUVFRkZGRwcHCEhISYmJisrKy0tLTIyMjQ0
NDk5OT09PUFBQUVFRUpKSk1NTVFRUVRUVFpaWlxcXGBgYGVlZWlpaW1tbXFxcXR0dHp6en5+fgBi
qQNkqQVkqQdnrApmpgpnqgpprA5prBFrrRNtrhZvsBhwrxdxsBlxsSJ2syJ3tCR2siZ5tSh6tix8
ti5+uTF+ujCAuDODvjaDvDuGujiFvT6Fuj2HvTyIvkGKvkWJu0yUv2mQrEOKwEWNwkaPxEiNwUqR
xk6Sw06SxU6Uxk+RyVKTxlCUwFKVxVWUwlWWxlKXyFOVzFWWyFaYyFmYx16bwlmZyVicyF2ayFyb
zF2cyV2cz2GaxGSex2GdymGezGOgzGSgyGWgzmihzWmkz22iymyizGmj0Gqk0m2l0HWqz3asznqn
ynuszXKp0XKq1nWp0Xaq1Hes0Xat1Hmt1Xyt0Huw1Xux2IGBgYWFhYqKio6Ojo6Xn5CQkJWVlZiY
mJycnKCgoKCioqKioqSkpKampqmpqaurq62trbGxsbKysrW1tbi4uLq6ur29vYCu0YixzYOw14G0
1oaz14e114K124O03YWz2Ie12oW13Im10o621Ii22oi23Iy32oq52Y252Y+73ZS51Ze81JC625G7
3JG825K83Je72pW93Zq92Zi/35G+4aC90qG+15bA3ZnA3Z7A2pjA4Z/E4qLA2KDF3qTA2qTE3avF
36zG3rLM3aPF4qfJ5KzJ4LPL5LLM5LTO4rbN5bLR6LTR6LXQ6r3T5L3V6cLCwsTExMbGxsvLy8/P
z9HR0dXV1dbW1tjY2Nra2tzc3N7e3sDW5sHV6cTY6MnZ79De7dTg6dTh69Xi7dbj7tni793m7tXj
8Nbk9tjl9N3m9N/p9eHh4eTk5Obm5ujo6Orq6u3t7e7u7uDp8efs8uXs+Ozv8+3z9vDw8PLy8vL0
9/b29vb5+/f6+/j4+Pn6+/r6+vr6/Pn8/fr8/Pv9/vz8/P7+/gAAACH5BAMAAP8ALAAAAAB4ABgA
AAj/AP8JHEiwoMGDCBMqXMiwocOHECNKnEixosWLGDNqZCioo0dC0Q7Sy2btlitisrjpK4io4yF/
yjzKRIZPIDSZOAUVmubxGUF88Aj2K+TxnKKOhfoJdOSxXEF1OXHCi5fnTx5oBgFo3QogwAalAv1V
yyUqFCtVZ2DZceOOIAKtB/pp4Mo1waN/gOjSJXBugFYJBBflIYhsq4F5DLQSmCcwwVZlBZvppQtt
D6M8gUBknQxA879+kXixwtauXbhheFph6dSmnsC3AOLO5TygWV7OAAj8u6A1QEiBEg4PnA2gw7/E
uRn3M7C1WWTcWqHlScahkJ7NkwnE80dqFiVw/Pz5/xMn7MsZLzUsvXoNVy50C7c56y6s1YPNAAAC
CYxXoLdP5IsJtMBWjDwHHTSJ/AENIHsYJMCDD+K31SPymEFLKNeM880xxXxCxhxoUKFJDNv8A5ts
W0EowFYFBFLAizDGmMA//iAnXAdaLaCUIVtFIBCAjP2Do1YNBCnQMwgkqeSSCEjzzyJ/BFJTQfNU
WSU6/Wk1yChjlJKJLcfEgsoaY0ARigxjgKEFJPec6J5WzFQJDwS9xdPQH1sR4k8DWzXijwRbHfKj
YkFO45dWFoCVUTqMMgrNoQD08ckPsaixBRxPKFEDEbEMAYYTSGQRxzpuEueTQBlshc5A6pjj6pQD
wf9DgFYP+MPHVhKQs2Js9gya3EB7cMWBPwL1A8+xyCYLD7EKQSfEF1uMEcsXTiThQhmszBCGC7G0
QAUT1JS61an/pKrVqsBttYxBxDGjzqxd8abVBwMBOZA/xHUmUDQB9OvvvwGYsxBuCNRSxidOwFCH
J5dMgcYJUKjQCwlahDHEL+JqRa65AKD7D6BarVsQM1tpgK9eAjjpa4D3esBVgdFAB4DAzXImiDY5
vCFHESko4cMKSJwAxhgzFLFDHEUYkzEAG6s6EMgAiFzQA4rBIxldExBkr1AcJzBPzNDRnFCKBpTd
gCD/cKKKDFuYQoQVNhhBBSY9TBHCFVW4UMkuSzf/fe7T6h4kyFZ/+BMBXYpoTahB8yiwlSFgdzXA
5JQPIDZCW1FgkDVxgGKCFCywEUQaKNitRA5UXHGFHN30PRDHHkMtNUHzMAcAA/4gwhUCsB63uEF+
bMVB5BVMtFXWBfljBhhgbCFCEyI4EcIRL4ChRgh36LBJPq6j6nS6ISPkslY0wQbAYIr/ahCeWg2f
ufFaIV8QNpeMMAkVlSyRiRNb0DFCFlu4wSlWYaL2mOp13/tY4A7CL63cRQ9aEYBT0seyfsQjHedg
xAG24ofITaBRIGTW2OJ3EH7o4gtfCIETRBAFEYRgC06YAw3CkIqVdK9cCZRdQgCVAKWYwy/FK4i9
3TYQIboE4BmR6wrABBCUmgFAfgXZRxfs4ARPPCEOZJjCHVxABFAA4R3sic2bmIbAv4EvaglJBACu
IxAMAKARBrFXvrhiAX8kEWVNHOETE+IPbzyBCD8oQRZwwIVOyAAXrgkjijRWxo4BLnwIwUcCJvgP
ZShAUfVa3Bz/EpQ70oWJC2mAKDmwEHYAIxhikAQPeOCLdRTEAhGIQKL0IMoGTGMgIBClA9QxkA3U
0hkKgcy9HHEQDcRyAr0ChAWWucwNMIJZ5KilNGvpADtt5JrYzKY2t8nNbnrzm+B8SEAAADs="

  return [image create photo -format GIF -data $logoData]
}

# create the Tk window and place it
makeWindow
::tk::PlaceWindow . widget

# process Tk events until the window is destroyed
tkwait window .

#
# DISCLAIMER:
# TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, POINTWISE DISCLAIMS
# ALL WARRANTIES, EITHER EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED
# TO, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE, WITH REGARD TO THIS SCRIPT.  TO THE MAXIMUM EXTENT PERMITTED 
# BY APPLICABLE LAW, IN NO EVENT SHALL POINTWISE BE LIABLE TO ANY PARTY 
# FOR ANY SPECIAL, INCIDENTAL, INDIRECT, OR CONSEQUENTIAL DAMAGES 
# WHATSOEVER (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF 
# BUSINESS INFORMATION, OR ANY OTHER PECUNIARY LOSS) ARISING OUT OF THE 
# USE OF OR INABILITY TO USE THIS SCRIPT EVEN IF POINTWISE HAS BEEN 
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGES AND REGARDLESS OF THE 
# FAULT OR NEGLIGENCE OF POINTWISE.
#
