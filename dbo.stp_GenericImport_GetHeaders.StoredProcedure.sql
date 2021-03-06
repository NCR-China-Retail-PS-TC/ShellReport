USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[stp_GenericImport_GetHeaders]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
/*
stp_GenericImport_GetHeaders 1,
'<XmlFilterData>
<Population MatrixMemberId="6"/>
<Retailer RetailerId="4"/>
<LogDates StartDate="2020/09/01"  EndDate="2020/09/30" />
<FileNameOperation FileName_Operation="3"/>
<FileTypeOperation FileType_Operation="3" FileType="17" Status="2"/>
<Status Success="1" Partial="1" Failure="1" InProcess="1" Error="1"/>
</XmlFilterData>'
,1
*/

/*
EXEC dbo.TK_ObjectRolePermission_WA 'HQ_App_Admin_Role', 1;
EXEC dbo.TK_ObjectRolePermission_WA 'HQ_App_User_Role', 1;
2020-09-13
*/
CREATE   PROCEDURE [dbo].[stp_GenericImport_GetHeaders]
	(	
		@xmlFilter1				nvarchar(max), 
	  @RetVal 				int output
	)
	As
--	select '<ImportHeader><Details Id="P_1" MatrixMemberId="2" RetailerId="2" ExternalImportId="198" ExternalFileType="" Status="997" StatusDescription="Failure" ImportDescription="import-01-2020-04-07T113457-GT.xml" StartDate="2020/04/07 11:20:37" EndDate="2020/04/07 11:21:03" EffectiveDate="" DownloadRequestStatus="0"/><Details Id="P_2" MatrixMemberId="5" RetailerId="5" ExternalImportId="30" ExternalFileType="" Status="997" StatusDescription="Failure" ImportDescription="Import-01-2019-09-25T151411-IT.xml" StartDate="2019/09/25 15:15:45" EndDate="2019/09/25 15:16:25" EffectiveDate="" DownloadRequestStatus="0"/><Details Id="P_3" MatrixMemberId="5" RetailerId="5" ExternalImportId="25" ExternalFileType="" Status="997" StatusDescription="Failure" ImportDescription="Import-01-2019-08-01T014000-IT.xml" StartDate="2019/09/23 23:13:14" EndDate="2019/09/23 23:13:53" EffectiveDate="" DownloadRequestStatus="0"/><Details Id="P_4" MatrixMemberId="6" RetailerId="6" ExternalImportId="15" ExternalFileType="" Status="997" StatusDescription="Failure" ImportDescription="Import-01-2019-08-01T013000-IT.xml" StartDate="2019/08/01 01:39:25" EndDate="2019/08/01 01:39:59" EffectiveDate="" DownloadRequestStatus="0"/><Details Id="P_5" MatrixMemberId="9" RetailerId="8" ExternalImportId="2" ExternalFileType="" Status="997" StatusDescription="Failure" ImportDescription="Import-01-2019-07-07T183117-IT.xml" StartDate="2019/07/07 23:57:12" EndDate="2019/07/07 23:57:49" EffectiveDate="" DownloadRequestStatus="0"/><Details Id="P_6" MatrixMemberId="2" RetailerId="2" ExternalImportId="153" ExternalFileType="" Status="997" StatusDescription="Failure" ImportDescription="import-01-2019-07-06T171452-GT.xml" StartDate="2019/07/06 18:23:07" EndDate="2019/07/06 18:23:31" EffectiveDate="" DownloadRequestStatus="0"/>
--	</ImportHeader>'
	declare @xmlfilter xml
	set @xmlfilter=@xmlFilter1
	exec MP_Shell..stp_GenericImport_GetHeaders_shell 0 ,@xmlFilter,@retval 


GO
