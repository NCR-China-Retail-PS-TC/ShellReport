USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[stp_GenericImport_OutPutErrors]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	2020-09-13
-- =============================================
create 	PROCEDURE [dbo].[stp_GenericImport_OutPutErrors]
                @iUserId int,
                @MatrixMemberid smallint,
                @ExternalImportId int,  
                @RetVal int output,
				  @Debug bit = 0,
                @ReturnMode tinyint = 0 -- 0 = Return result set, 1 = Return XML
As 
declare @p5 int
set @p5=0
--select ' <ImportDetails><Details EntityTypeId="0" EntityTypeName="Item" 
--EntityId="1002" StatusCode="29" Severity="10"
-- StatusDescription="Category Id does not exist in Hierarchy tree .Existing Item" 
--ErrorDetails="&lt;View ViewId=&quot;0&quot; CategoryId=&quot;999999&quot; /&gt;"/>
--</ImportDetails>'
exec HOST_Shell_Prod..stp_GenericImport_OutPutErrors 0,@MatrixMemberid,@ExternalImportId,0,@retval=@p5 output,@ReturnMode=1


GO
