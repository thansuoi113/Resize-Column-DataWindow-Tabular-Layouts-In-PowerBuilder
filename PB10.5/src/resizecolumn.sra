$PBExportHeader$resizecolumn.sra
$PBExportComments$Generated Application Object
forward
global type resizecolumn from application
end type
global transaction sqlca
global dynamicdescriptionarea sqlda
global dynamicstagingarea sqlsa
global error error
global message message
end forward

global type resizecolumn from application
string appname = "resizecolumn"
end type
global resizecolumn resizecolumn

on resizecolumn.create
appname="resizecolumn"
message=create message
sqlca=create transaction
sqlda=create dynamicdescriptionarea
sqlsa=create dynamicstagingarea
error=create error
end on

on resizecolumn.destroy
destroy(sqlca)
destroy(sqlda)
destroy(sqlsa)
destroy(error)
destroy(message)
end on

event open;open(w_main)
end event

