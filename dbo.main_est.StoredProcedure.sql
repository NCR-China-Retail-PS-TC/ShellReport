USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[main_est]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	CALL THE EST  TO CREATE THE  report  for finicance 
--2020-03-18 chang T+2  to t+1
--  财务报表主程序,调用财务报表及新会员采用拉链技术生成 =================
CREATE PROCEDURE [dbo].[main_est] @MatrixMemberId INT
AS
  BEGIN
      DECLARE @dataDate VARCHAR(20);
      DECLARE @dataDateEnd VARCHAR(20);
      DECLARE @day VARCHAR(2)
      SET @day=Substring(CONVERT(VARCHAR(10), Getdate(), 120), 9, 2);

	 SET @dataDate=CONVERT(VARCHAR(10), Dateadd(day, -1, Getdate()), 120);

            EXEC dbo.Est @dataDate   ,@MatrixMemberId
            EXEC [dbo].[Member_point_detail] @dataDate,@MatrixMemberId --提取会员积分余额
		    exec dbo.pointConvertCoupon @dataDate,@MatrixMemberId
     
		if @day = '15'
		 exec [dbo].[GetBecomingExpirePoint] @MatrixMemberId

 if  @dataDate=  convert(varchar(10),dateadd(ms,-3,DATEADD(mm, DATEDIFF(m,0,@dataDate)+1, 0)),120)  --本月的最后一天
	
		exec getExpiredPoint @MatrixMemberId, @dataDate  --新增2019-03-27
              
		     

		   exec CouponAndRegProm  @dataDate,@MatrixMemberId   --2019-12-05 提取优惠券及注册促销

		   exec dbo.est_upload_file @MatrixMemberId
 
  END 

GO
