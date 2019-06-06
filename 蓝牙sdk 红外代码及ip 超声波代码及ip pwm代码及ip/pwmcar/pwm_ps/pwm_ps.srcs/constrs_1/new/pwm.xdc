##LEDs
set_property -dict {PACKAGE_PIN R14       IOSTANDARD LVCMOS33}   [get_ports   {   ld_tri_o[0]   } ] ;  #I0_
set_property -dict {PACKAGE_PIN P14       IOSTANDARD LVCMOS33}   [get_ports   {   ld_tri_o[1]   } ] ;  #I0_
set_property -dict {PACKAGE_PIN N16       IOSTANDARD LVCMOS33}   [get_ports   {   ld_tri_o[2]   } ] ;  #I0_
set_property -dict {PACKAGE_PIN M14       IOSTANDARD LVCMOS33}   [get_ports   {   ld_tri_o[3]   } ] ;  #I0_

##Buttons
set_property -dict {PACKAGE_PIN D19       IOSTANDARD LVCMOS33}   [get_ports   {   btn_tri_i[0]   } ] ;  #I0_
set_property -dict {PACKAGE_PIN D20       IOSTANDARD LVCMOS33}   [get_ports   {   btn_tri_i[1]   } ] ;  #I0_
set_property -dict {PACKAGE_PIN L20       IOSTANDARD LVCMOS33}   [get_ports   {   btn_tri_i[2]   } ] ;  #I0_
set_property -dict {PACKAGE_PIN L19       IOSTANDARD LVCMOS33}   [get_ports   {   btn_tri_i[3]   } ] ;  #I0_


##ChipKit Digital     I/0    Low
set_property -dict {PACKAGE_PIN T14       IOSTANDARD LVCMOS33}   [get_ports   {   dir_out[0]   } ] ;  #I0_
set_property -dict {PACKAGE_PIN U12       IOSTANDARD LVCMOS33}   [get_ports   {   dir_out[1]   } ] ;  #I0_
set_property -dict {PACKAGE_PIN U13       IOSTANDARD LVCMOS33}   [get_ports   {   PWM_o[0]   } ] ;  #I0_
set_property -dict {PACKAGE_PIN T15       IOSTANDARD LVCMOS33}   [get_ports   {   dir_out[2]   } ] ;  #I0_
set_property -dict {PACKAGE_PIN R16       IOSTANDARD LVCMOS33}   [get_ports   {   dir_out[3]   } ] ;  #I0_
set_property -dict {PACKAGE_PIN U17       IOSTANDARD LVCMOS33}   [get_ports   {   PWM_o[1]   } ] ;  #I0_
