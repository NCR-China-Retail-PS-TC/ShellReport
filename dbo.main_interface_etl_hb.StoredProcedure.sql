USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[main_interface_etl_hb]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [dbo].[main_interface_etl_hb]
@bussiness_date varchar(10)
	AS
BEGIN
	
	set transaction isolation  level read uncommitted;
	declare @LastDay varchar(10),
	@RC int = 0,
	@RC1 int
	  exec FindLoyaltyNoExistSKU  1,@bussiness_date	
		if exists(select 1 from R_LoyaltyNoExistSKU r where r.MatrixMemberId = 1)
		begin
	
			update report_data..DailyTaskResult
			set FailCode = 1,
				FailReason = 'Missing SKU1',
				LastRunning=getdate()
			where RetailerId = 1 and DataDate = @bussiness_date 
			print 'Missing  sku return '
	   	return
      end



	exec @RC1 = [dbo].[erp_ds_hb]  @bussiness_date
	if @RC1 <> 0 set @RC = @RC1

	exec @RC1 =[pointConvertCoupon_hb] @bussiness_date
	if @RC1 <> 0 set @RC = @RC1     
 
    exec @RC1 = [pro_e3_single_coupon_hb] @bussiness_date
	if @RC1 <> 0 set @RC = @RC1     

	exec @RC1 = [dbo].[pro_e1_single_leg_reward_hb]  @bussiness_date  --单法律实体积分发放
	if @RC1 <> 0 set @RC = @RC1
  print 'e1'+str(@rc)
	exec @RC1 = [dbo].[pro_e2_single_redemption_hb] @bussiness_date    --单法律实体积分兑换
	if @RC1 <> 0 set @RC = @RC1
	print 'e2'+str(@rc)
	exec @RC1 = [dbo].[pro_e4_mult_reward_hb] @bussiness_date          --多法律实体积分发放
	if @RC1 <> 0 set @RC = @RC1
	print 'e4'+str(@rc)
	exec @RC1 = [dbo].[pro_e5_mult_redemption_hb] @bussiness_date      --多法律实体积分兑换
	if @RC1 <> 0 set @RC = @RC1
    print 'e5'+str(@rc)
 
	if  @bussiness_date=  convert(varchar(10),dateadd(ms,-3,DATEADD(mm, DATEDIFF(m,0,@bussiness_date)+1, 0)),120)  --本月的最后一天
	begin 
		-- set  @LastDay=convert(varchar(10),dateadd(day,-1,convert(date,@bussiness_date,120)),120)

		exec @RC1 = [dbo].[pro_e7_point_expired_hb] @bussiness_date       --积分到期统计
		if @RC1 <> 0 set @RC = @RC1
		print 'e7'+str(@rc)
	end
  
	if @RC = 0
	begin
		update report_data..DailyTaskResult
		set Success = 1
		where RetailerId = 1 and DataDate = @bussiness_date 
	
	end
	else
	begin 
	
		if exists(select 1 from R_LoyaltyNoExistSKU r where r.MatrixMemberId = 1)
		begin
	
			update report_data..DailyTaskResult
			set FailCode = 1,
				FailReason = 'Missing SKU'
			where RetailerId = 1 and DataDate = @bussiness_date 
		
		
		end
		else
		begin
			update report_data..DailyTaskResult
			set FailCode = 99,
				FailReason = 'Need to Check'
			where RetailerId = 1 and DataDate = @bussiness_date 
		end
	end

	update report_data..DailyTaskResult
	set LastRunning = getdate()
	where RetailerId = 1 and DataDate = @bussiness_date 
    
END





GO
