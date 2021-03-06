USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[main_interface_etl_sx]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
	--20200804CR312  对于DOCO站的折扣数据油品和非油都通过单法律实体优惠券接口上传ERP
  --  积分类型：J13，业务类型名称：DO促销折扣
  -- 20211118  v2.0
  --add exec pro_E3_DiscountTran_sx @createDate
-- =============================================
CREATE  PROCEDURE [dbo].[main_interface_etl_sx]
 @createDate varchar(10)
	AS
BEGIN
	set transaction isolation  level read uncommitted;

	declare @RC int = 0,
	@RC1 int
		  exec FindLoyaltyNoExistSKU  4,@createDate
		if exists(select 1 from R_LoyaltyNoExistSKU r where r.MatrixMemberId = 4)
		begin
	
			update report_data..DailyTaskResult
			set FailCode = 1,
				FailReason = 'Missing SKU1',LastRunning=getdate()
			where RetailerId = 1 and DataDate = @createDate 
			print 'Missing  sku return '
	   	return
      end

 -- exec  [dbo].[est] '2017-06-20','2017-06-22'
	print 'begin erp_ds_sx'
	print getdate(); 
	exec @RC1 = [dbo].[erp_ds_sx]  @createDate
	if @RC1 <> 0 set @RC = @RC1
	--print 'erp_ds_sx RC=' + convert(varchar,@RC) +',RC1=' + convert(varchar,@RC1)

	print 'begin pointConvertCoupon_sx'
	print getdate(); 
	exec @RC1 = pointConvertCoupon_sx @createDate
	if @RC1 <> 0 set @RC = @RC1
	--print 'pointConvertCoupon_sx RC=' + convert(varchar,@RC) +',RC1=' + convert(varchar,@RC1)

	print 'begin [pro_e2_single_redemption_sx]'
	print getdate(); 
	exec  @RC1 = [dbo].[pro_e2_single_redemption_sx] @createDate    --单法律实体积分兑换
	if @RC1 <> 0 set @RC = @RC1
	--print 'pro_e2_single_redemption_sx RC=' + convert(varchar,@RC) +',RC1=' + convert(varchar,@RC1)

	print 'begin [pro_e1_single_leg_reward_sx]'
	print getdate(); 
	exec @RC1 = [dbo].[pro_e1_single_leg_reward_sx]  @createDate  --单法律实体积分发放
	if @RC1 <> 0 set @RC = @RC1
	--print 'pro_e1_single_leg_reward_sx RC=' + convert(varchar,@RC) +',RC1=' + convert(varchar,@RC1)

	print 'begin [pro_e4_mult_reward_sx]'
	print getdate(); 
	exec  @RC1 = [dbo].[pro_e4_mult_reward_sx] @createDate          --多法律实体积分发放
	if @RC1 <> 0 set @RC = @RC1
	--print 'pro_e4_mult_reward_sx RC=' + convert(varchar,@RC) +',RC1=' + convert(varchar,@RC1)

	print 'begin [pro_e5_mult_redemption_sx]'
	print getdate(); 
	exec  @RC1 = [dbo].[pro_e5_mult_redemption_sx] @createDate      --多法律实体积分兑换
	if @RC1 <> 0 set @RC = @RC1
	--print 'pro_e5_mult_redemption_sx RC=' + convert(varchar,@RC) +',RC1=' + convert(varchar,@RC1)

	print 'begin [pro_e7_point_expired_sx]'
	print getdate(); 
    exec  @RC1 = [dbo].[pro_e7_point_expired_sx]  @createDate --积分到期统计
	if @RC1 <> 0 set @RC = @RC1
	--print 'pro_e7_point_expired_sx RC=' + convert(varchar,@RC) +',RC1=' + convert(varchar,@RC1)

	print 'begin [pro_H1_promotionDiscountTran_sx]'
	print getdate(); 
	exec  @RC1 = [dbo].[pro_H1_promotionDiscountTran_sx] @createDate 
	if @RC1 <> 0 set @RC = @RC1
	--print 'pro_H1_promotionDiscountTran_sx RC=' + convert(varchar,@RC) +',RC1=' + convert(varchar,@RC1)
	print 'finished all'
	print getdate(); 


	--20200804CR312  对于DOCO站的折扣数据油品和非油都通过单法律实体优惠券接口上传ERP
  --  积分类型：J13，业务类型名称：DO促销折扣
     exec pro_e3_single_coupon_sx @createDate
 --2021-11-18
 exec pro_E3_DiscountTran_sx @createDate
	if @RC = 0
	begin
		update report_data..DailyTaskResult
		set Success = 1
		where RetailerId = 2 and DataDate = @createDate 
	end
	else
	begin 
		if exists(select 1 from R_LoyaltyNoExistSKU r where r.MatrixMemberId = 4)
		begin
			update report_data..DailyTaskResult
			set FailCode = 1,
				FailReason = 'Missing SKU'
			where RetailerId = 2 and DataDate = @createDate 
		end
		else
		begin
			update report_data..DailyTaskResult
			set FailCode = 99,
				FailReason = 'Need to Check'
			where RetailerId = 2 and DataDate = @createDate 
		end
	end

	update report_data..DailyTaskResult
	set LastRunning = getdate()
	where RetailerId = 2 and DataDate = @createDate 

 
END





GO
