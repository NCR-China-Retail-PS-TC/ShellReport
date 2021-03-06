USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[member_point_redem_bak]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description: 积分进销存	完成积分兑换功能,首先添加过期积分到积分兑换明细表,置过期积分balance为0
--计算兑换积分,显示未过期的积分.
-- =============================================
create   PROCEDURE  [dbo].[member_point_redem_bak]
--	@business_date varchar(10)	
	
AS
BEGIN
declare  @createdate_end1 varchar(10);
declare @PosTranInternalKey  [int] ,
    	@AccountInternalKey [int] ,
		@BuyingUnitInternalKey [int] ,
		@MatrixMemberId [smallint] ,
		@PosDateTime [smalldatetime],
		@ProcessDate [smalldatetime] ,
		@EarnValue [money] ,
		@RedeemValue [money],
		@InitialValue [money],
		@ExpirationDate [smalldatetime] ,
		@ReasonCode [tinyint] ,
		@Remarks [nvarchar](256) ,
		@SourcePosTranInternalKey [int],
		@balance float, 
		@pos_key int
	--	@business_date varchar(10)	;
		set @balance=0;

	 
	 --  set @business_date=convert(varchar(10),dateadd(day,-1,getdate()),120);
	 
	    declare   @table VARCHAR(max) ='promotion_list'
		  ,@Server VARCHAR(max)   ='Loyalty_Shell_1.dbo.'
		  ,@FilePath NVARCHAR(100)=  'C:\Retalix\HQ\uploadfile_host\a\'  
		  ,@Expoprtfilename nvarchar(200)
		  ,@bal int =50; --per 6  point  for 1 rmb
    declare @tableDate_cur varchar(6) ,@tableDate_pre varchar(6) 
	,@atd_Server nvarchar(max) ='ATD_Shell'		
	,@ServerHost nvarchar(max)='HOST_Shell_1'
	,@loyalty_server varchar(max)='Loyalty_Shell_1'
	,@sql_text  nvarchar(max)
	,@sql_text_org nvarchar(max)
	, @MatrixMemberId1 int=1
	 
	
	--置过期积分balance为0
	/*delete [CRM_POSAccountsActivitRedemDetail]
	delete CRM_POSAccountsActivityReward
	delete [CRM_POSAccountsredem] 
	*/
 
 

 insert into report_data.dbo.CRM_POSAccountsActivityReward
      (PosTranInternalKey,AccountInternalKey,BuyingUnitInternalKey,MatrixMemberId,
	PosDateTime,ProcessDate,EarnValue,RedeemValue,ExpirationDate,ReasonCode,
	SourcePosTranInternalKey,balance )
select PosTranInternalKey,AccountInternalKey,BuyingUnitInternalKey,MatrixMemberId,
	PosDateTime,ProcessDate,EarnValue,0,ExpirationDate,ReasonCode,
	SourcePosTranInternalKey,EarnValue from Loyalty_Shell_prod.dbo.CRM_POSAccountsActivity  cpaa  (nolock) --loyalty  
	 where   cpaa.AccountInternalKey=2 and cpaa.EarnValue<>0  and   not exists
	(select  cpaar.PosTranInternalKey  from  report_data.dbo.CRM_POSAccountsActivityReward cpaar  (nolock) --reportdata  
     where cpaar.PosTranInternalKey=cpaa.PosTranInternalKey  and cpaa.MatrixMemberId=cpaar.MatrixMemberId) 
	 	 order by PosTranInternalKey,BuyingUnitInternalKey ;
 --更新余额不等于0的获得积分记录
 update report_data.dbo.CRM_POSAccountsActivityReward  set  RedeemValue=a.redeemValue,balance=EarnValue-a.redeemValue
 from  (select  cparl.Earn_PosTranInternalKey, sum(cparl.RedeemValue)  redeemValue from Loyalty_Shell_prod.dbo.CRM_PosAccountsActivity_RewardLog cparl
    group by cparl.Earn_PosTranInternalKey   ) a where a.Earn_PosTranInternalKey= report_data.dbo.CRM_POSAccountsActivityReward.PosTranInternalKey
	and  report_data.dbo.CRM_POSAccountsActivityReward.balance<>0 
	
 

	
END
GO
