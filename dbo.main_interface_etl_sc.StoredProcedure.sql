USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[main_interface_etl_sc]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   PROCEDURE [dbo].[main_interface_etl_sc]
@bussiness_date varchar(10)
	AS
BEGIN
	declare @LastDay varchar(10),
	@RC int = 0,
	@RC1 int
		  exec FindLoyaltyNoExistSKU 5,@bussiness_date	
		if exists(select 1 from R_LoyaltyNoExistSKU r where r.MatrixMemberId =5)
		begin
	
			update report_data..DailyTaskResult
			set FailCode = 1,
				 	FailReason = 'Missing SKU1',LastRunning=getdate()
			where RetailerId = 1 and DataDate = @bussiness_date 
			print 'Missing  sku return '
	   	return
      end

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	exec @RC1 = [dbo].[erp_ds_sc]  @bussiness_date
	if @RC1 <> 0 set @RC = @RC1

	exec @RC1 = [pointConvertCoupon_sc] @bussiness_date
	if @RC1 <> 0 set @RC = @RC1    

	exec @RC1 = [dbo].[pro_e1_single_leg_reward_sc]  @bussiness_date  --单法律实体积分发放
	if @RC1 <> 0 set @RC = @RC1

	exec @RC1 = [dbo].[pro_e2_single_redemption_sc] @bussiness_date    --单法律实体积分兑换
	if @RC1 <> 0 set @RC = @RC1    

	exec @RC1 = [dbo].[pro_e4_mult_reward_sc] @bussiness_date          --多法律实体积分发放
	if @RC1 <> 0 set @RC = @RC1

	exec @RC1 = [dbo].[pro_e5_mult_redemption_sc] @bussiness_date      --多法律实体积分兑换
	if @RC1 <> 0 set @RC = @RC1    

    exec @RC1 = [dbo].[pro_H1_promotionDiscountTran_sc] @bussiness_date 
	if @RC1 <> 0 set @RC = @RC1    

	if  @bussiness_date=  convert(varchar(10),dateadd(ms,-3,DATEADD(mm, DATEDIFF(m,0,@bussiness_date)+1, 0)),120)  --本月的最后一天
	begin 
		set @LastDay=convert(varchar(10),dateadd(day,-1,convert(date,@bussiness_date,120)),120)
		exec @RC1 = [dbo].[pro_e7_point_expired_sc] @LastDay       --积分到期统计
		if @RC1 <> 0 set @RC = @RC1    
	end
            
	  
	if @RC = 0
	begin
		update report_data..DailyTaskResult
		set Success = 1
		where RetailerId = 3 and DataDate = @bussiness_date 
	end
	else
	begin 
		if exists(select 1 from R_LoyaltyNoExistSKU r where r.MatrixMemberId = 5)
		begin
			update report_data..DailyTaskResult
			set FailCode = 1,
				FailReason = 'Missing SKU'
			where RetailerId = 3 and DataDate = @bussiness_date 
		end
		else
		begin
			update report_data..DailyTaskResult
			set FailCode = 99,
				FailReason = 'Need to Check'
			where RetailerId = 3 and DataDate = @bussiness_date 
		end
	end

	update report_data..DailyTaskResult
	set LastRunning = getdate()
	where RetailerId = 3 and DataDate = @bussiness_date 
END





GO
