USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[getLoyaltyCE]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [dbo].[getLoyaltyCE]
	@date varchar(10)
AS
BEGIN
 declare  @ce float;
delete check_loaytyPoint;
insert check_loaytyPoint 
select  cpa.PosDateTime, cp.TranId loytranid,sum(  case  when cp.IsTransactionVoid=1 then -1*redeemValue else    cpa.EarnValue end ) ear
,sum(case  when cp.IsTransactionVoid=1 then -1*cpa.EarnValue else  redeemValue end)  redeem
,cp.StoreInternalKey,cp.POSTranInternalKey,cp.PosId,cpa.ProcessDate ,0
 FROM 
 [report_data].[dbo].[CRM_POSAccountsActivity](nolock)cpa
 inner join  Loyalty_Shell_prod. [dbo].[CRM_POSTran](nolock) cp on cpa.PosTranInternalKey=cp.POSTranInternalKey
  where --  convert(varchar(10),cpa.ProcessDate,120)=@date and   --cpa.PosDateTime<'2018-05-04'   and 
convert(varchar(10),cp.PosDateTime,120)=@date and
  cpa.MatrixMemberId=1
 --and  not  (posid=-66 or  posid=-99)
  group by cp.TranId,cpa.PosDateTime,cp.StoreInternalKey,cp.POSTranInternalKey,cp.PosId,cpa.ProcessDate



 
	--select *  from  check_loaytyPoint where convert(varchar(10),processDate,120)<>posDatetime
delete check_AtdPoint;
	
delete check_AtdPoint1 
 insert check_AtdPoint1  --reward
	 select  store.storeid, store.StoreInternalKey ,
 ftc.BusinessDate,ftc.TillId,  fth.TranId, 
	 sum( case  when  (RewardMethodId=1 )  then ftprd1.RewardValue else 0 end ) as RewardvaluePoint
	 ,0 ,fth.CreatedDate      --22获得积分
	  from   
		   [ATD_Shell].dbo.FO_TranHeader201907 fth
			  inner  join [ATD_Shell].[dbo].[FO_TranCollection] ftc
on ftc.CollectionInternalKey=fth.CollectionInternalKey
 inner  join  [report_data].[dbo].store_gs store on store.storeid=ftc.storeid and store.MatrixMemberId=1
   left join  Loyalty_Shell_prod. [dbo].[CRM_POSTran] cp 
    on cp.TranId=fth.TranId and cp.PosDateTime=ftc.BusinessDate and cp.StoreInternalKey=store.StoreInternalKey
	  and  cp.MatrixMemberId=1 and cp.PosId=ftc.TillId
	  left join Loyalty_Shell_Prod.dbo.CRM_Member cm on cm.BuyingUnitInternalKey=cp.BuyingUnitInternalKey
	
 left join (select  distinct  TicketInternalKey, ftprd1.PromotionId ,ftprd1.RewardValue , entityid ,RewardMethodId
  from  [ATD_Shell].dbo.FO_TranPromotionRewardApportionment201907 ftprd1 where ((RewardMethodId=1  and  RewardId=100) or  RewardMethodId=5  )) ftprd1
  on ftprd1.TicketInternalKey=fth.TicketInternalKey   --and ftprd1.EntityId=fts.ItemId 
 --   	inner join   [ATD_Shell].[dbo].[FO_TranPromotionMemberAccount201704] ftpma 
--	on ftprd1.TicketInternalKey=ftpma.TicketInternalKey and ftpma.PromotionId=ftprd1.PromotionId
     left join [Loyalty_Shell_prod].[dbo].[PromotionHeader_PR] phpr 
	on phpr.PromotionHeaderId=ftprd1.PromotionId and phpr.MatrixMemberId=1
	left join  [report_data].[dbo].item_cat  item    on item.MainItemId=ftprd1.EntityId  and item.MatrixMemberId=1 
	left join store_gs s on s.storeid=ftc.StoreId 

 	/* */ where  ftc.BusinessDate=@date 	  and 
	   phpr.PromotionHeaderId is not null and cp.MatrixMemberId=1
		
		 group by  store.storeid, store.StoreInternalKey ,ftc.TillId,
 ftc.BusinessDate,  fth.TranId,fth.CreatedDate

  insert check_AtdPoint1    --redeem 
 select   store.storeid, store.StoreInternalKey ,
 ftc.BusinessDate,ftc.TillId,  fth.TranId, 0,sum( case when ftprds.RewardValue=0 then ftpma.AdjustmentValue else 
  cast(ftprd.rewardValue/ftprds.RewardValue*ftpma.AdjustmentValue as  decimal(10,4))  end )   Redemption_quantity,   --23                --19积分兑换数量 
 
 fth.CreatedDate
 from  Loyalty_Shell_prod. [dbo].[CRM_POSTran] cp
    inner join   [report_data].[dbo].store_gs  store1 on store1.StoreInternalKey=cp.StoreInternalKey  and cp.MatrixMemberId=1
    and store1.MatrixMemberId=1   
	 inner  join [ATD_Shell].[dbo].[FO_TranCollection] ftc  on ftc.BusinessDate=cp.PosDateTime  and store1.storeid=ftc.StoreId
 	  inner join	   [ATD_Shell].dbo.FO_TranHeader201907    fth
    on fth.CollectionInternalKey=ftc.CollectionInternalKey  and fth.TranId=cp.TranId  
inner join (
    select   ftprd1.TicketInternalKey, ftprd1.PromotionId ,sum(ftprd1.RewardValue) RewardValue  
    from  [ATD_Shell].[dbo].[FO_TranPromotionRewardApportionment201907] ftprd1  
	   where RewardMethodId in (5,3) 
	   group by ftprd1.TicketInternalKey, ftprd1.PromotionId  /* having sum(ftprd1.RewardValue)<>0 */) ftprds
	   on ftprds.TicketInternalKey=fth.TicketInternalKey
	inner join      [ATD_Shell].[dbo].[FO_TranPromotionRewardApportionment201907] ftprd  
	-- on ftprd.TicketInternalKey=fth.TicketInternalKey  
	 on  ftprds.TicketInternalKey=ftprd.TicketInternalKey and ftprd.PromotionId=ftprds.PromotionId
	  and ftprd.RewardMethodId in (5,3) 

	inner join   [ATD_Shell].[dbo].[FO_TranPromotionMemberAccount201907] ftpma 
	on ftprds.TicketInternalKey=ftpma.TicketInternalKey and ftpma.PromotionId=ftprds.PromotionId
  left join  report_data.[dbo].[PromotionHeader_PR] phpr 	on phpr.PromotionHeaderId=ftprd.PromotionId  and phpr.MatrixMemberId=1
	left join  [report_data].[dbo].item_cat  item 	on item.MainItemId=ftprd.EntityId  and item.MatrixMemberId=1  
	 left join    [Loyalty_Shell_prod].[dbo].[CRM_Member] cm  on cp.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
   left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey --首次注册油站
 and s.MatrixMemberId=1  -- and cp.MatrixMemberId=store.MatrixMemberId
 left join [report_data].[dbo].store_gs  store on cp.StoreInternalKey=store.StoreInternalKey and store.MatrixMemberId=1
    where     ftc.BusinessDate=@date
  and cp.MatrixMemberId=1 -- and    
   -- ftprd.RewardValue<>0 --2018-06-23  add transactionVoid just
--	and cp.TranId=16223
group by 	store.storeid, store.StoreInternalKey ,
 ftc.BusinessDate,ftc.TillId,  fth.TranId, fth.CreatedDate
 delete  check_AtdPoint 
 insert   check_AtdPoint
 select  storeid,cat.storeInternalKey,businessDate,posid,tranid,sum(rewardvalue) as rew,sum(redeemvalue) red,processDate
   from  check_AtdPoint1  cat
   group by storeid,cat.storeInternalKey,businessDate,posid,tranid,processDate


--get point


 /*select s.storename ,  l.*,a.*,l.earValue-isnull(a.rewardValue,0)  as ce from check_loaytyPoint l  left join check_AtdPoint  a
 on l.loytranid=a.tranId and l.StoreInternalKey=a.storeInternalKey   and a.posid=l.posid
  --and a.businessdate=l.posDatetime
  left join report_data.dbo.store_gs  s on l.StoreInternalKey=s.StoreInternalKey and s.MatrixMemberId=1
 where     not  (l.posid=-66 or  l.posid=-99) 
    and   
	((l.earValue<>a.rewardValue) or (a.rewardValue is null ))  
order by  l.posDatetime */

select @ce=sum(l.earValue-isnull(a.rewardValue,0))  from check_loaytyPoint l  left join   check_AtdPoint  a
 on l.loytranid=a.tranId and l.StoreInternalKey=a.storeInternalKey   and a.posid=l.posid
  --and a.businessdate=l.posDatetime
  left join report_data.dbo.store_gs  s on l.StoreInternalKey=s.StoreInternalKey and s.MatrixMemberId=1
 where     not  (l.posid=-66 or  l.posid=-99) 
    and   
	((l.earValue<>a.rewardValue) or (a.rewardValue is null )) 
	 print '------' 
print 'ce is  ' ;
print  @ce
 print '------'
delete check_loaytyPoint   where  posInternalKey not  in (
 select  l.posInternalKey from check_loaytyPoint l  left join check_AtdPoint  a
 on l.loytranid=a.tranId and l.StoreInternalKey=a.storeInternalKey   and a.posid=l.posid
  --and a.businessdate=l.posDatetime
  left join report_data.dbo.store_gs  s on l.StoreInternalKey=s.StoreInternalKey and s.MatrixMemberId=1
 where     not  (l.posid=-66 or  l.posid=-99) 
    and   
	((l.earValue<>a.rewardValue) or (a.rewardValue is null ))  )

select @ce=sum(l.earValue-isnull(a.rewardValue,0))  from check_loaytyPoint l  left join check_AtdPoint  a
 on l.loytranid=a.tranId and l.StoreInternalKey=a.storeInternalKey   and a.posid=l.posid
  --and a.businessdate=l.posDatetime
  left join report_data.dbo.store_gs  s on l.StoreInternalKey=s.StoreInternalKey and s.MatrixMemberId=1
 where     not  (l.posid=-66 or  l.posid=-99) 
    and   
	((l.earValue<>a.rewardValue) or (a.rewardValue is null )) 
	 print '------' 
print 'ce2 is  ' ;
print  @ce
 print '------'

END

GO
