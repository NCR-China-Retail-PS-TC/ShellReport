USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[est_upload_file]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	CALL xxx.bat to upload R report file to share folder
-- =================
CREATE   PROCEDURE [dbo].[est_upload_file] @MatrixMemberId INT
AS
  BEGIN
    
	if @MatrixMemberId = 1 -- HB
	begin
		exec sys.xp_cmdshell 'M:\upload\hb\cop.bat'  
		exec sys.xp_cmdshell 'M:\upload\HBDO\cop.bat' 
	end
	if @MatrixMemberId = 4 -- SX
	begin
		exec sys.xp_cmdshell 'M:\upload\sx\cop.bat'  
		exec sys.xp_cmdshell 'M:\upload\SXDO\cop.bat' 
	end
	if @MatrixMemberId = 5 -- SC
	begin
		exec sys.xp_cmdshell 'M:\upload\sc\cop.bat' 
   	exec sys.xp_cmdshell 'M:\upload\scDO\cop.bat'
	end
	if @MatrixMemberId = 6 -- WOFE
	begin
		exec sys.xp_cmdshell 'M:\upload\sh\cop.bat' 
	end
	if @MatrixMemberId = 7 -- FJ
	begin
		exec sys.xp_cmdshell 'M:\upload\fj\cop.bat' 
	end
	if @MatrixMemberId = 8 -- Crown
	begin
		exec sys.xp_cmdshell 'M:\upload\jx\cop.bat' 
	end
  END 



GO
