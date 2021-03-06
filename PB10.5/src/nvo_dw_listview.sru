$PBExportHeader$nvo_dw_listview.sru
$PBExportComments$Add listview features to your DW V1.1
forward
global type nvo_dw_listview from nonvisualobject
end type
type point from structure within nvo_dw_listview
end type
end forward

type point from structure
	long		l_x
	long		l_y
end type

global type nvo_dw_listview from nonvisualobject
end type
global nvo_dw_listview nvo_dw_listview

type prototypes
Private:
// Mouse Capture
Function long SetCap( long lhwnd ) library 'user32' Alias For SetCapture
Function long RelCap() library 'user32' Alias For ReleaseCapture

// Get text size
Function ulong GetDC(ulong hWnd) Library 'user32'
Function long ReleaseDC(ulong hWnd, ulong hdcr) Library 'user32'
Function boolean GetTextExtentPoint32A(ulong hdcr, string lpString, long nCount, ref point size) Library 'gdi32' alias for "GetTextExtentPoint32A;Ansi"
Function ulong SelectObject(ulong hdc, ulong hWnd) Library 'gdi32'

end prototypes

type variables
Protected:
Long		il_Gaps[]
Long		il_NGaps, il_CurGap
Long		il_HeaderHeight
Long 		il_I
String		is_ObjectNames[]
String		is_ColumnNames[]
Boolean		ib_Hot
Boolean		ib_Resize
Constant Long	cil_MinWidth=10

// added this so remove the requirement for my class library
Window		iw_ParentWindow
datawindow		idw_Parent
end variables
forward prototypes
public function integer perform (string as_event, ref any aa_args[])
protected subroutine findgap (integer xpos)
protected subroutine mouseresize (integer xpos)
protected subroutine releasecapture ()
protected subroutine setcapture ()
protected function window parentwindow ()
protected function integer extractcolumns (string as_widths, ref integer ai_widths[])
public function string savecolumns ()
public function integer loadcolumns (string as_widths)
public function integer il_curgap ()
public subroutine duplicatecolumn (integer ai_fromgap, integer ai_togap)
protected subroutine resizecolumns (integer xpos, integer ai_col)
public subroutine doubleclick (string as_name)
public subroutine idw_parent (datawindow adw_dw)
public subroutine setparentwindow (window aw_w)
public function datawindow idw_parent ()
end prototypes

public function integer perform (string as_event, ref any aa_args[]);//====================================================================
// Function: nvo_dw_listview.perform()
//--------------------------------------------------------------------
// Description: This function recieves the notification of the events
//				from the datawindow. The code is kept to a minimum
//				because we will be recieveing mousemove notifications of
//				which there will be loads so we need to execute this
//				function as quickly as possible.
//--------------------------------------------------------------------
// Arguments:
// 	      	string	as_event	: Event that occured	 
// 	ref   	any     	aa_args[]: Arguments to the event	
//--------------------------------------------------------------------
// Returns:  integer -1, error occured, 0, no processing, 1, event was processed
//--------------------------------------------------------------------
// Author:	PB.BaoGa		Date: 2020/11/27
//--------------------------------------------------------------------
//	Copyright (c) PB.BaoGa(TM), All rights reserved.
//--------------------------------------------------------------------
// Modify History:
//
//====================================================================

DWObject ldwo_DWO

Choose Case as_Event
	Case 'mousemove'
		If ib_Resize Then
			This.MouseResize( aa_Args[ 1 ] )
		Else
			il_CurGap = 0
			If aa_Args[ 2 ] > il_HeaderHeight Then Return 0
			FindGap( aa_Args[ 1 ] )
		End If
		
	Case 'clicked', 'lbuttondown'
		This.SetCapture()
		If il_CurGap > 0 Then
			ib_Resize = True
			Post Function SetPointer( SizeWE! )
		End If
		
	Case 'doubleclicked'
		ldwo_DWO = aa_Args[ 4 ]
		If ldwo_DWO.Type = 'text' Then
			If ldwo_DWO.band = 'header' Then
				This.DoubleClick( ldwo_DWO.Name )
			End If
		End If
		
	Case 'lbuttonup'
		ib_Resize = False
		This.ReleaseCapture()
		
	Case Else
		Return 0
End Choose

Return 1

end function

protected subroutine findgap (integer xpos);//====================================================================
// Function: nvo_dw_listview.findgap()
//--------------------------------------------------------------------
// Description: 	Figure out if the mouse is positioned over a gap in the column headers. If it is then switch the mouse pointer.
//--------------------------------------------------------------------
// Arguments:
// 	integer	xpos: X Position of the mouse.	
//--------------------------------------------------------------------
// Returns:  (none)
//--------------------------------------------------------------------
// Author:	PB.BaoGa		Date: 2020/11/27
//--------------------------------------------------------------------
//	Copyright (c) PB.BaoGa(TM), All rights reserved.
//--------------------------------------------------------------------
// Modify History:
//
//====================================================================

Long ll_X

ll_X = Long( idw_Parent().Describe( 'datawindow.horizontalscrollposition' ) )
If ll_X > 0 Then &
xpos += UnitsToPixels( ll_X, XUnitsToPixels! )

For il_I = 1 To il_NGaps
	If xpos < il_Gaps[ il_I ] Then Exit
	If xpos = il_Gaps[ il_I ] Or xpos = il_Gaps[ il_I ] + 1 Then
		SetPointer( SizeWE! )
		il_CurGap = il_I
		Return
	End If
Next


end subroutine

protected subroutine mouseresize (integer xpos);//====================================================================
// Function: nvo_dw_listview.mouseresize()
//--------------------------------------------------------------------
// Description: Call the resize columns function.
//--------------------------------------------------------------------
// Arguments:
// 	integer	xpos: X Position of the mouse drag that resized the columns.	
//--------------------------------------------------------------------
// Returns:  (none)
//--------------------------------------------------------------------
// Author:	PB.BaoGa		Date: 2020/11/27
//--------------------------------------------------------------------
//	Copyright (c) PB.BaoGa(TM), All rights reserved.
//--------------------------------------------------------------------
// Modify History:
//
//====================================================================

SetPointer( SizeWE! )

Long ll_X

ll_X = Long( idw_Parent().Describe( 'datawindow.horizontalscrollposition' ) )
If ll_X > 0 Then xpos += UnitsToPixels( ll_X, XUnitsToPixels! )

This.ResizeColumns( xpos, il_CurGap )


end subroutine

protected subroutine releasecapture ();
RelCap()
end subroutine

protected subroutine setcapture ();
SetCap( Handle( This.idw_Parent() ) )


end subroutine

protected function window parentwindow ();
Return iw_parentwindow


end function

protected function integer extractcolumns (string as_widths, ref integer ai_widths[]);//====================================================================
// Function: nvo_dw_listview.extractcolumns()
//--------------------------------------------------------------------
// Description: Extract the internal column width settings from the string created by the SaveColumns function and 
//				view and return them in an encoded string.
//--------------------------------------------------------------------
// Arguments:
// 	      	string	as_widths: encoded string to remove the settings from.
// 	ref   	integer  	ai_widths[]: Reference variable to load the widths into.	
//--------------------------------------------------------------------
// Returns:  integer: The number of column widths extracted from the string.
//--------------------------------------------------------------------
// Author:	PB.BaoGa		Date: 2020/11/27
//--------------------------------------------------------------------
//	Copyright (c) PB.BaoGa(TM), All rights reserved.
//--------------------------------------------------------------------
// Modify History:
//
//====================================================================

Long ll_Pos, ll_I

If LenA( as_Widths ) = 0 Then Return 0
ll_Pos = PosA( as_Widths, '~t' )
Do While ll_Pos > 0
	ll_I ++
	ai_Widths[ ll_I ] = Long( LeftA( as_Widths, ll_Pos - 1 ) )
	as_Widths = MidA( as_Widths, ll_Pos + 1 )
	ll_Pos = PosA( as_Widths, '~t' )
Loop

Return ll_I

end function

public function string savecolumns ();//====================================================================
// Function: nvo_dw_listview.savecolumns()
//--------------------------------------------------------------------
// Description: Extract the internal column width settings and return them in an encoded string
//--------------------------------------------------------------------
// Arguments:
//--------------------------------------------------------------------
// Returns:  string: An encoded string containing the columns widths
//--------------------------------------------------------------------
// Author:	PB.BaoGa		Date: 2020/11/27
//--------------------------------------------------------------------
//	Copyright (c) PB.BaoGa(TM), All rights reserved.
//--------------------------------------------------------------------
// Modify History:
//
//====================================================================

Long ll_Cols, ll_I
String ls_Details

ll_Cols = il_NGaps
For ll_I = 1 To ll_Cols
	ls_Details += String( il_Gaps[ ll_I ] ) + '~t'
Next
Return ls_Details


end function

public function integer loadcolumns (string as_widths);//====================================================================
// Function: nvo_dw_listview.loadcolumns()
//--------------------------------------------------------------------
// Description: Load the columns widths create by the savecolumns function back into the datawindow.
//--------------------------------------------------------------------
// Arguments:
// 	string	as_widths: The encoded width string containing the column widths.	
//--------------------------------------------------------------------
// Returns:  integer: 1 all loaded ok , -1 load failed
//--------------------------------------------------------------------
// Author:	PB.BaoGa		Date: 2020/11/27
//--------------------------------------------------------------------
//	Copyright (c) PB.BaoGa(TM), All rights reserved.
//--------------------------------------------------------------------
// Modify History: 
//
//====================================================================

Integer li_Widths[], li_Cols, li_i
Integer li_X, li_Width
String ls_Modify
Datawindow ldw_DW

ldw_DW = idw_Parent()
li_Cols = This.ExtractColumns( as_Widths, li_Widths )
For li_i = 1 To li_Cols
	// Alter the width and height based on the extracted values
	If li_i > 1 Then
		// Alter the X value based on the new gap
		// Alter the width based on the difference betweene th gaps
		li_X = li_Widths[ li_i - 1 ]
		li_Width = li_Widths[ li_i ] - li_X
	Else
		// its the first one so we base it on the current start X
		li_X = UnitsToPixels( Long( ldw_DW.Describe( is_ObjectNames[ 1 ] + '.x' ) ), XUnitstoPixels! ) -4
		li_Width = li_Widths[ 1 ] - li_X
	End If
	ls_Modify += is_ObjectNames[ li_i ] + '.x=' + String( PixelsToUnits( li_X + 4, XPixelsToUnits! ) ) + ' '
	ls_Modify += is_ObjectNames[ li_i ] + '.width=' + String( PixelsToUnits( li_Width - 4, XPixelsToUnits! ) ) + ' '
	ls_Modify += is_ColumnNames[ li_i ] + '.x=' + String( PixelsToUnits( li_X + 4, XPixelsToUnits! ) ) + ' '
	ls_Modify += is_ColumnNames[ li_i ] + '.width=' + String( PixelsToUnits( li_Width - 4, XPixelsToUnits! ) ) + ' '
	// do this rather than a straight copy, in case there are none
	il_gaps[ li_i ] = li_Widths[ li_i ]
Next


ldw_DW.Modify( ls_Modify )

Return 1


end function

public function integer il_curgap ();
Return il_CurGap


end function

public subroutine duplicatecolumn (integer ai_fromgap, integer ai_togap);//====================================================================
// Function: nvo_dw_listview.duplicatecolumn()
//--------------------------------------------------------------------
// Description: Resize a column to be the same width as the specified column.
//--------------------------------------------------------------------
// Arguments:
// 	integer	ai_fromgap: Columns whose width we want to use.	
// 	integer	ai_togap: Column that want the new width.  	
//--------------------------------------------------------------------
// Returns:  (none)
//--------------------------------------------------------------------
// Author:	PB.BaoGa		Date: 2020/11/27
//--------------------------------------------------------------------
//	Copyright (c) PB.BaoGa(TM), All rights reserved.
//--------------------------------------------------------------------
// Modify History:
//
//====================================================================


Long ll_LWidth, ll_LX, ll_RX, ll_I
String ls_Modify
Datawindow ldw_DW

ldw_DW = This.idw_parent()

ll_LWidth = UnitsToPixels( Long( ldw_DW.Describe( is_ObjectNames[ ai_FromGap ] + '.Width' ) ), XUnitsToPixels! )
ll_LX = UnitsToPixels( Long( ldw_DW.Describe( is_ObjectNames[ ai_togap ] + '.X' ) ), XUnitsToPixels! )

This.ResizeColumns( ll_LX + ll_LWidth, ai_togap )


end subroutine

protected subroutine resizecolumns (integer xpos, integer ai_col);//====================================================================
// Function: nvo_dw_listview.resizecolumns()
//--------------------------------------------------------------------
// Description: Resize the two columns to the new location the left hand
//				column's width should be X to the new pos if the new pos
//				< x then = 0 the right hand column X and width should
//				change to be the difference between current and new. We
//				always recalc from scratch as we may have missed some
//				mouse move events due to queue overflow.
//--------------------------------------------------------------------
// Arguments:
// 	integer	xpos: X Position of the mouse drag that resized the columns.  	
// 	integer	ai_col: Column that was resized.
//--------------------------------------------------------------------
// Returns:  (none)
//--------------------------------------------------------------------
// Author:	PB.BaoGa		Date: 2020/11/27
//--------------------------------------------------------------------
//	Copyright (c) PB.BaoGa(TM), All rights reserved.
//--------------------------------------------------------------------
// Modify History:
//
//====================================================================

Long ll_LWidth, ll_LX, ll_RX, ll_I
String ls_Modify
Datawindow ldw_DW

ldw_DW = This.idw_parent()

ll_LX = UnitsToPixels( Long( ldw_DW.Describe( is_ObjectNames[ ai_Col ] + '.X' ) ), XUnitsToPixels! )
If xpos < ll_LX Then
	// Make column small.
	ll_LWidth = cil_MinWidth
	ls_Modify = is_ObjectNames[ ai_Col ] + '.Width=' + String( cil_MinWidth )
	ls_Modify += is_ColumnNames[ ai_Col ] + '.Width=' + String( cil_MinWidth )
	xpos = ll_LX + UnitsToPixels( cil_MinWidth, XUnitsToPixels! )
Else
	// Calc new column width
	ll_LWidth = xpos - ll_LX
	ls_Modify = is_ObjectNames[ ai_Col ] + '.Width=' + String( PixelsToUnits( ll_LWidth , XPixelsToUnits! ) )
	ls_Modify += is_ColumnNames[ ai_Col ] + '.Width=' + String( PixelsToUnits( ll_LWidth , XPixelsToUnits! ) )
End If

// If this is not the last column then modify the next column too!
If ai_Col < il_NGaps Then
	For ll_I = ai_Col + 1 To il_NGaps
		ll_RX = UnitsToPixels( Long( ldw_DW.Describe( is_ObjectNames[ ll_I ] + '.X' ) ), XUnitsToPixels! )
		// Calc the right hand column X
		ll_RX = ll_RX + xpos - il_Gaps[ ai_Col ]
		il_Gaps[ ll_I ] += xpos - il_Gaps[ ai_Col ]
		ls_Modify += ' ' + is_ObjectNames[ ll_I ] + '.X=' + String( PixelsToUnits( ll_RX , XPixelsToUnits! ) )
		ls_Modify += ' ' + is_ColumnNames[ ll_I ] + '.X=' + String( PixelsToUnits( ll_RX , XPixelsToUnits! ) )
	Next
End If

ldw_DW.Modify( ls_Modify )

// set the new gap to be the current x
il_Gaps[ ai_Col ] = xpos



end subroutine

public subroutine doubleclick (string as_name);//====================================================================
// Function: nvo_dw_listview.doubleclick()
//--------------------------------------------------------------------
// Description: This fucntion works out the maximum width of the column and resizes the column to fit this size
//--------------------------------------------------------------------
// Arguments:
// 	string	as_name	: The name of the column header double clicked.
//--------------------------------------------------------------------
// Returns:  (none)
//--------------------------------------------------------------------
// Author:	PB.BaoGa		Date: 2020/11/27
//--------------------------------------------------------------------
//	Copyright (c) PB.BaoGa(TM), All rights reserved.
//--------------------------------------------------------------------
// Modify History:
//
//====================================================================

String ls_Text, ls_FontFace, ls_Column
Integer li_FontSize, li_I, li_Weight, li_Max, li_MaxWidth, li_Col
Integer li_Size, li_Len, li_Return, li_WM_GETFONT = 49, li_Gap
ULong lul_Hdc, lul_Handle, lul_hFont
Datawindow ldw_DW
Point lstr_Size
StaticText	lst_Text

// a text item in the header was double clicked, figure out
// which one was double clicked and then create an object
// we can use to figure out the column widths.
For li_I = 1 To il_NGaps
	If is_objectnames[ li_I ] = as_Name Then
		ls_Column = is_columnnames[ li_I ]
		Exit
	End If
Next
If ls_Column = '' Then Return
li_Gap = li_I
ldw_DW = This.idw_Parent()
li_Col = Integer( ldw_DW.Describe( ls_Column + '.id' ) )

// Datawindow syntax specifies font point size is negative
li_FontSize = Long( ldw_DW.Describe( ls_Column + '.Font.Height' ) )
li_FontSize = -1 * li_FontSize
ls_FontFace = ldw_DW.Describe( ls_Column + '.Font.Face' )
li_Weight = Long( ldw_DW.Describe( ls_Column + '.Font.Weight' ) )

If Lower( ls_FontFace ) = 'courier new' Then
	// its a fixed width font so we do not need the API processing
	li_Max = ldw_DW.RowCount()
	li_MaxWidth = 0
	For li_I = 1 To li_Max
		li_Len = LenA( String( ldw_DW.Object.Data[ li_I, li_Col ] ) )
		li_Len *= 7
		If li_Len > li_MaxWidth Then li_MaxWidth = li_Len
	Next
	li_MaxWidth += UnitsToPixels( Long( ldw_DW.Describe(	is_objectnames[ li_Gap ] + '.X' ) ), XUnitsToPixels! )
	ResizeColumns( li_MaxWidth, li_Gap )
Else
	li_Return = This.ParentWindow().OpenUserObject( lst_Text )
	If li_Return = 1 Then
		If Lower( ls_FontFace ) = 'tahoma' Then
			lst_Text.FaceName = 'MS Sans Serif'
		Else
			lst_Text.FaceName = ls_FontFace
		End If
		lst_Text.TextSize = li_FontSize
		lst_Text.Weight = li_Weight
		
		lul_Handle = Handle( lst_Text )
		lul_Hdc = GetDC( lul_Handle )
		
		lul_hFont = Send( lul_Handle, li_WM_GETFONT, 0, 0 )
		SelectObject( lul_Hdc, lul_hFont )
		
		// Now the text object is set up, loop through the
		// data and figure out the largest size.
		li_Max = ldw_DW.RowCount()
		li_MaxWidth = 0
		For li_I = 1 To li_Max
			ls_Text = String( ldw_DW.Object.Data[ li_I, li_Col ] ) + 'W'
			li_Len = LenA(ls_Text)
			GetTextExtentpoint32A(lul_Hdc, ls_Text, li_Len, lstr_Size )
			If lstr_Size.l_X > li_MaxWidth Then li_MaxWidth = lstr_Size.l_X
		Next
		
		ReleaseDC(lul_Handle, lul_Hdc)
		This.ParentWindow().CloseUserObject( lst_Text )
		// Now we have the max width, alter the column and header
		// widths occordingly.
		li_MaxWidth += UnitsToPixels( Long( ldw_DW.Describe( &
			is_objectnames[ li_Gap ] + '.X' ) ), XUnitsToPixels! )
		ResizeColumns( li_MaxWidth, li_Gap )
	End If
	
End If


end subroutine

public subroutine idw_parent (datawindow adw_dw);//====================================================================
// Function: nvo_dw_listview.idw_parent()
//--------------------------------------------------------------------
// Description: This function overrides the ancestor function so that we
//				can interagate the datawindow and cache some values for
//				later use. This function is called automatically by the
//				datawindow manager.
//				
//				Function gets all the header text items, ending in _t
//				and check that they have matching columns. Load them
//				into an array then sort them in to ascending sequence.
//				Then calculate where the gaps are. NOTE THIS ROUTINE
//				ASSUMES THE DATAWINDOW UNITS ARE PIXELS!
//--------------------------------------------------------------------
// Arguments:
// 	datawindow	adw_dw: Datawindow being processed by the manager.	
//--------------------------------------------------------------------
// Returns:  (none)
//--------------------------------------------------------------------
// Author:	PB.BaoGa		Date: 2020/11/27
//--------------------------------------------------------------------
//	Copyright (c) PB.BaoGa(TM), All rights reserved.
//--------------------------------------------------------------------
// Modify History:
//
//====================================================================

idw_Parent = adw_dw

Long ll_I, ll_Max, ll_Pos, ll_O, ll_J, ll_OM1
Long ll_X[], ll_Width[], ll_SX
String ls_DWObjects, ls_ObjectNames[], ls_ObjectName, ls_Chk
Boolean lb_Swap

ls_DWObjects = adw_dw.Describe( 'datawindow.objects' ) + '~t'
ll_Pos = PosA( ls_DWObjects, '~t' )
Do While ll_Pos > 0
	ls_ObjectName = LeftA( ls_DWObjects, ll_Pos - 1 )
	ls_DWObjects = MidA( ls_DWObjects, ll_Pos + 1 )
	ll_Pos = PosA( ls_DWObjects, '~t' )
	
	// Check to see if the object name ends in _t, it
	// is in the header and there is a matching column
	If RightA( ls_ObjectName, 2 ) <> '_t' Then Continue
	ls_Chk = adw_dw.Describe( ls_ObjectName + '.band' )
	If ls_Chk <> 'header' Then Continue
	ls_Chk = adw_dw.Describe( LeftA( ls_ObjectName, LenA( ls_ObjectName ) - 2 ) + '.ColType' )
	If ls_Chk = '!' Then Continue
	
	// Header is good so add it to the list
	ll_O++
	ls_ObjectNames[ ll_O ] = ls_ObjectName
	ll_X[ ll_O ] = Long( adw_dw.Describe( ls_ObjectName + '.X' ) )
Loop

// If we did not find any useable headers then quit!
If ll_O = 0 Then Return

// Sort the headers in order of X position.
ll_OM1 = ll_O - 1
For ll_I = 1 To ll_O
	lb_Swap = False
	For ll_J = 1 To ll_OM1
		If ll_X[ ll_J ] > ll_X[ ll_J + 1 ] Then
			lb_Swap = True
			ll_SX = ll_X[ ll_J ]
			ls_ObjectName = ls_ObjectNames[ ll_J ]
			ll_X[ ll_J ] = ll_X[ ll_J + 1 ]
			ls_ObjectNames[ ll_J ] = ls_ObjectNames[ ll_J + 1 ]
			ls_ObjectNames[ ll_J + 1 ] = ls_ObjectName
			ll_X[ ll_J + 1 ] = ll_SX
		End If
	Next
	If Not lb_Swap Then Exit
Next

// Therefore the gap for the resizing of the columns must be at the
// X + width of all the number of text items.
il_NGaps = ll_O
For ll_I = 1 To il_NGaps
	ll_SX = Long( adw_dw.Describe( ls_ObjectNames[ ll_I ] + '.Width' ) )
	// All coord calulations should be done in pixels...
	il_Gaps[ ll_I ] = UnitsToPixels( ll_X[ ll_I ], XUnitsToPixels! ) + UnitsToPixels( ll_SX, XUnitsToPixels! )
Next

// Record the object/column names and the Height of the header
is_ObjectNames = ls_ObjectNames
For ll_I = 1 To ll_O
	is_ColumnNames[ ll_I ] = LeftA( ls_ObjectNames[ ll_I ], LenA( ls_ObjectNames[ ll_I ] ) - 2 )
Next
il_HeaderHeight = UnitsToPixels( Long( adw_dw.Describe( 'datawindow.header.height' ) ), XUnitsToPixels! )


end subroutine

public subroutine setparentwindow (window aw_w);iw_ParentWindow = aw_W

end subroutine

public function datawindow idw_parent ();
RETURN idw_Parent
end function

on nvo_dw_listview.create
call super::create
TriggerEvent( this, "constructor" )
end on

on nvo_dw_listview.destroy
TriggerEvent( this, "destructor" )
call super::destroy
end on

event constructor;call super::constructor;
/********************************************************************
	nc_sdw_listview: Make your DW control act like a list view.

	<OBJECT>	This service allows the user to interact with the
				datawindow column headers of a tabular style datawindow
				as if the header was a listview control. Users can resize
				the column headers and double click the header to have it
				resize automatically to the maximum column width. The
				service also features a serialization type interface for
				recording the column widths and later restoring the
				column widths.
				
				This service monitors the event queue for the following
				event types:
				<LI>mousemove
				<LI>clicked or lbuttondown
				<LI>doubleclicked
				<LI>lbuttonup (must be mapped as pbm_lbuttonup)
				
				You may want to inherit this service and override
				the following functions to call the correct functions
				in your class library:
				<LI>GetSetting
				<LI>SetSetting
				<LI>TextWidth
				<LI>SetCapture
				<LI>GetCapture
				<LI>ParentWindow
				</OBJECT>

	<USAGE>	Add the service to the datawindow manager.</USAGE>

	<ALSO>	nc_service_datawindow</ALSO>

	Date		Ref	Author		Comments
 11/18/98			Ken Howe		First Version
 20/09/99			Ken Howe		Add Column Serialization functions
********************************************************************/

end event

