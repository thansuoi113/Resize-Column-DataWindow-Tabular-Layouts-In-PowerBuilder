$PBExportHeader$w_main.srw
forward
global type w_main from window
end type
type dw_1 from datawindow within w_main
end type
end forward

global type w_main from window
integer width = 2377
integer height = 1132
boolean titlebar = true
string title = "Resize Column"
boolean controlmenu = true
boolean minbox = true
boolean maxbox = true
boolean resizable = true
long backcolor = 67108864
string icon = "AppIcon!"
boolean center = true
dw_1 dw_1
end type
global w_main w_main

type variables
nvo_dw_listview invo_dw_lv
end variables
on w_main.create
this.dw_1=create dw_1
this.Control[]={this.dw_1}
end on

on w_main.destroy
destroy(this.dw_1)
end on

event open;invo_dw_lv = Create nvo_dw_listview

invo_dw_lv.SetParentWindow( This )
invo_dw_lv.idw_Parent( dw_1 ) 




end event

type dw_1 from datawindow within w_main
event mousemove pbm_dwnmousemove
event lbuttonup pbm_dwnlbuttonup
integer width = 2318
integer height = 964
integer taborder = 10
string title = "none"
string dataobject = "d_example"
boolean hscrollbar = true
boolean vscrollbar = true
boolean livescroll = true
borderstyle borderstyle = stylelowered!
end type

event mousemove;Any la_Args[]

la_Args[ 1 ] = xpos
la_Args[ 2 ] = ypos
la_Args[ 3 ] = row
la_Args[ 4 ] = dwo

invo_dw_lv.Perform( 'mousemove', la_Args )
end event

event lbuttonup;Any la_Args[]

la_Args[ 1 ] = xpos
la_Args[ 2 ] = ypos
la_Args[ 3 ] = row
la_Args[ 4 ] = dwo

invo_dw_lv.Perform( 'lbuttonup', la_Args )

end event

event clicked;Any la_Args[]

la_Args[ 1 ] = xpos
la_Args[ 2 ] = ypos
la_Args[ 3 ] = row
la_Args[ 4 ] = dwo

invo_dw_lv.Perform( 'clicked', la_Args )

end event

event doubleclicked;Any la_Args[]

la_Args[ 1 ] = xpos
la_Args[ 2 ] = ypos
la_Args[ 3 ] = row
la_Args[ 4 ] = dwo

invo_dw_lv.Perform( 'doubleclicked', la_Args )


end event

