USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[main_est_manual]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	CALL THE EST  TO CREATE THE  report  for finicance 
--  财务报表主程序,调用财务报表及新会员采用拉链技术生成 =================
CREATE  PROCEDURE [dbo].[main_est_manual] @MatrixMemberId INT
    , @dataDate VARCHAR(10)
AS
  BEGIN
      set transaction isolation  level read uncommitted;
      DECLARE @dataDateEnd VARCHAR(20);
      DECLARE @day VARCHAR(2)
      SET @day=Substring(CONVERT(VARCHAR(10),@dataDate, 120), 9, 2);
    
		if @day = '15'
		 exec [dbo].[GetBecomingExpirePoint] @MatrixMemberId

    if  @dataDate=  convert(varchar(10),dateadd(ms,-3,DATEADD(mm, DATEDIFF(m,0,@dataDate)+1, 0)),120)  --本月的最后一天
	BEGIN	
		exec getExpiredPoint @MatrixMemberId, @dataDate  --新增2019-03-27
    END; 
        
            EXEC dbo.Est @dataDate      ,@MatrixMemberId
            EXEC [dbo].[Member_point_detail] @dataDate        ,@MatrixMemberId --提取会员积分余额
            exec dbo.pointConvertCoupon @dataDate,@MatrixMemberId
		
      

		exec dbo.est_upload_file @MatrixMemberId
  END 

GO
