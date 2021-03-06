USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[checDifferentkPoint]    Script Date: 1/19/2022 9:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [dbo].[checDifferentkPoint]

	 
AS
BEGIN
 truncate  table DiffRecord
declare  @date varchar(10),@rq2 date
set @rq2='2020-08-19'

--while  @rq2<'2020-06-19'
 begin 
set @date=convert(varchar(10),@rq2,120)
set @rq2=dateadd(day,1,@rq2)
delete check_loaytyPoint;
insert check_loaytyPoint 
select  cpa.PosDateTime, cp.TranId loytranid,sum(  case  when cp.IsTransactionVoid=1 then -1*redeemValue else    cpa.EarnValue end ) ear
,sum(case  when cp.IsTransactionVoid=1 then -1*cpa.EarnValue else  redeemValue end)  redeem
,cp.StoreInternalKey,cp.POSTranInternalKey,cp.PosId,cp.CreatedAt ,0
 FROM 
 [report_data].[dbo].[CRM_POSAccountsActivity] cpa
 inner join  Loyalty_Shell_prod. [dbo].[CRM_POSTran] cp on cpa.PosTranInternalKey=cp.POSTranInternalKey
  where   convert(varchar(10),cp.CreatedAt,120)=@date and   --cpa.PosDateTime<'2018-05-04'   and 

  cpa.MatrixMemberId=1
 -- and cp.TranId=26845
 --and  not  (posid=-66 or  posid=-99)
  group by cp.TranId,cpa.PosDateTime,cp.StoreInternalKey,cp.POSTranInternalKey,cp.PosId,cp.CreatedAt

	--select *  from  check_loaytyPoint where convert(varchar(10),processDate,120)<>posDatetime
	
delete check_AtdPoint1 
 insert check_AtdPoint1  --reward
	 select  store.storeid, store.StoreInternalKey ,
 ftc.BusinessDate,ftc.TillId,  fth.TranId, 
	 sum( case  when  (RewardMethodId=1 )  then ftprd1.RewardValue else 0 end ) as RewardvaluePoint
	 ,0 ,cp.CreatedAt      --22获得积分
	  from   
		   [ATD_Shell].dbo.FO_TranHeader202006 fth
			  inner  join [ATD_Shell].[dbo].[FO_TranCollection] ftc
on ftc.CollectionInternalKey=fth.CollectionInternalKey
 inner  join  [report_data].[dbo].store_gs store on store.storeid=ftc.storeid and store.MatrixMemberId=1
   left join  Loyalty_Shell_prod. [dbo].[CRM_POSTran] cp 
    on cp.TranId=fth.TranId and cp.PosDateTime=ftc.BusinessDate and cp.StoreInternalKey=store.StoreInternalKey
	  and  cp.MatrixMemberId=1 and cp.PosId=ftc.TillId
	  left join Loyalty_Shell_Prod.dbo.CRM_Member cm on cm.BuyingUnitInternalKey=cp.BuyingUnitInternalKey
	
 left join (select  distinct  TicketInternalKey, ftprd1.PromotionId ,ftprd1.RewardValue , entityid ,RewardMethodId
  from  [ATD_Shell].dbo.FO_TranPromotionRewardApportionment202006 ftprd1 where ((RewardMethodId=1  and  RewardId=100) or  RewardMethodId=5  )) ftprd1
  on ftprd1.TicketInternalKey=fth.TicketInternalKey   --and ftprd1.EntityId=fts.ItemId 
 --   	inner join   [ATD_Shell].[dbo].[FO_TranPromotionMemberAccount202006] ftpma 
--	on ftprd1.TicketInternalKey=ftpma.TicketInternalKey and ftpma.PromotionId=ftprd1.PromotionId
     left join [Loyalty_Shell_prod].[dbo].[PromotionHeader_PR] phpr 
	on phpr.PromotionHeaderId=ftprd1.PromotionId and phpr.MatrixMemberId=1
	left join  [report_data].[dbo].item_cat  item    on item.MainItemId=ftprd1.EntityId  and item.MatrixMemberId=1 
	left join store_gs s on s.storeid=ftc.StoreId 
	left join   report_data.[dbo].[v_get_reg_compAndStore]   ss   on ss.BuyingUnitInternalKey=cm.BuyingUnitInternalKey --??????
   
 
 	/* */ where  convert(varchar(10),cp.CreatedAt,120)=@date 	  and 
	   phpr.PromotionHeaderId is not null and  s.MatrixMemberId=1
	   and  ss.MatrixMemberId=1
	 	--and fth.TranId=1127976
		 group by  store.storeid, store.StoreInternalKey ,ftc.TillId,
 ftc.BusinessDate,  fth.TranId,cp.CreatedAt 

  insert check_AtdPoint1  --reward
	 select  store.storeid, store.StoreInternalKey ,
 ftc.BusinessDate,ftc.TillId,  fth.TranId, 
	 sum( case  when  (RewardMethodId=1 )  then ftprd1.RewardValue else 0 end ) as RewardvaluePoint
	 ,0 ,cp.CreatedAt      --22获得积分
	  from   
		   [ATD_Shell].dbo.FO_TranHeader202007 fth
			  inner  join [ATD_Shell].[dbo].[FO_TranCollection] ftc
on ftc.CollectionInternalKey=fth.CollectionInternalKey
 inner  join  [report_data].[dbo].store_gs store on store.storeid=ftc.storeid and store.MatrixMemberId=1
   left join  Loyalty_Shell_prod. [dbo].[CRM_POSTran] cp 
    on cp.TranId=fth.TranId and cp.PosDateTime=ftc.BusinessDate and cp.StoreInternalKey=store.StoreInternalKey
	  and  cp.MatrixMemberId=1 and cp.PosId=ftc.TillId
	  left join Loyalty_Shell_Prod.dbo.CRM_Member cm on cm.BuyingUnitInternalKey=cp.BuyingUnitInternalKey
	
 left join (select  distinct  TicketInternalKey, ftprd1.PromotionId ,ftprd1.RewardValue , entityid ,RewardMethodId
  from  [ATD_Shell].dbo.FO_TranPromotionRewardApportionment202007 ftprd1 where ((RewardMethodId=1  and  RewardId=100) or  RewardMethodId=5  )) ftprd1
  on ftprd1.TicketInternalKey=fth.TicketInternalKey   --and ftprd1.EntityId=fts.ItemId 
 --   	inner join   [ATD_Shell].[dbo].[FO_TranPromotionMemberAccount202007] ftpma 
--	on ftprd1.TicketInternalKey=ftpma.TicketInternalKey and ftpma.PromotionId=ftprd1.PromotionId
     left join [Loyalty_Shell_prod].[dbo].[PromotionHeader_PR] phpr 
	on phpr.PromotionHeaderId=ftprd1.PromotionId and phpr.MatrixMemberId=1
	left join  [report_data].[dbo].item_cat  item    on item.MainItemId=ftprd1.EntityId  and item.MatrixMemberId=1 
	left join store_gs s on s.storeid=ftc.StoreId
	
  left join   report_data.[dbo].[v_get_reg_compAndStore]   ss   on ss.BuyingUnitInternalKey=cm.BuyingUnitInternalKey --??????
   
 	/* */ where  convert(varchar(10),cp.CreatedAt,120)=@date 	  and 
	   phpr.PromotionHeaderId is not null and  s.MatrixMemberId=1
and  ss.MatrixMemberId=1
	-- 	and fth.TranId=713456
		 group by  store.storeid, store.StoreInternalKey ,ftc.TillId,
 ftc.BusinessDate,  fth.TranId,cp.CreatedAt 



  insert check_AtdPoint1    --redeem 
 select   store.storeid, store.StoreInternalKey ,
 ftc.BusinessDate,ftc.TillId,  fth.TranId, 0,sum( case when ftprds.RewardValue=0 then ftpma.AdjustmentValue else 
  cast(ftprd.rewardValue/ftprds.RewardValue*ftpma.AdjustmentValue as  decimal(10,4))  end )   Redemption_quantity,   --23                --19积分兑换数量 
 
  cp.CreatedAt
 from  Loyalty_Shell_prod. [dbo].[CRM_POSTran] cp
    inner join   [report_data].[dbo].store_gs  store1 on store1.StoreInternalKey=cp.StoreInternalKey  and cp.MatrixMemberId=1
    and store1.MatrixMemberId=1   
	 inner  join [ATD_Shell].[dbo].[FO_TranCollection] ftc  on ftc.BusinessDate=cp.PosDateTime  and store1.storeid=ftc.StoreId
 	  inner join	   [ATD_Shell].dbo.FO_TranHeader202007    fth
    on fth.CollectionInternalKey=ftc.CollectionInternalKey  and fth.TranId=cp.TranId  
inner join (
    select   ftprd1.TicketInternalKey, ftprd1.PromotionId ,sum(ftprd1.RewardValue) RewardValue  
    from  [ATD_Shell].[dbo].[FO_TranPromotionRewardApportionment202007] ftprd1  
	   where RewardMethodId in (5,3) 
	   group by ftprd1.TicketInternalKey, ftprd1.PromotionId  /* having sum(ftprd1.RewardValue)<>0 */) ftprds
	   on ftprds.TicketInternalKey=fth.TicketInternalKey
	inner join      [ATD_Shell].[dbo].[FO_TranPromotionRewardApportionment202007] ftprd  
	-- on ftprd.TicketInternalKey=fth.TicketInternalKey  
	 on  ftprds.TicketInternalKey=ftprd.TicketInternalKey and ftprd.PromotionId=ftprds.PromotionId
	  and ftprd.RewardMethodId in (5,3) 

	inner join   [ATD_Shell].[dbo].[FO_TranPromotionMemberAccount202007] ftpma 
	on ftprds.TicketInternalKey=ftpma.TicketInternalKey and ftpma.PromotionId=ftprds.PromotionId
  left join  report_data.[dbo].[PromotionHeader_PR] phpr 	on phpr.PromotionHeaderId=ftprd.PromotionId  and phpr.MatrixMemberId=1
	left join  [report_data].[dbo].item_cat  item 	on item.MainItemId=ftprd.EntityId  and item.MatrixMemberId=1  
	 left join    [Loyalty_Shell_prod].[dbo].[CRM_Member] cm  on cp.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
   left join   report_data.[dbo].[v_get_reg_compAndStore]   s   on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey --首次注册油站
 and s.MatrixMemberId=1  -- and cp.MatrixMemberId=store.MatrixMemberId
 left join [report_data].[dbo].store_gs  store on cp.StoreInternalKey=store.StoreInternalKey and store.MatrixMemberId=1
    where     convert(varchar(10),cp.CreatedAt,120)=@date 
  and  s.MatrixMemberId=1 -- and    
   -- ftprd.RewardValue<>0 --2018-06-23  add transactionVoid just
--	and cp.TranId=16223
group by 	store.storeid, store.StoreInternalKey ,
 ftc.BusinessDate,ftc.TillId,  fth.TranId ,cp.CreatedAt

 delete  check_AtdPoint 
 insert   check_AtdPoint
 select  storeid,cat.storeInternalKey,businessDate,posid,tranid,sum(rewardvalue) as rew,sum(redeemvalue) red,processDate
   from  check_AtdPoint1  cat
   group by storeid,cat.storeInternalKey,businessDate,posid,tranid,processDate

  
--get point   l  cunzai
  insert into DiffRecord  select s.storeid, s.storename ,  l.*,a.*,isnull(l.earValue,0)-isnull(a.rewardValue,0)  as ce from check_loaytyPoint l  left join check_AtdPoint  a
 on l.loytranid=a.tranId and l.StoreInternalKey=a.storeInternalKey   and a.posid=l.posid
  --and a.businessdate=l.posDatetime
  left join report_data.dbo.store_gs  s on l.StoreInternalKey=s.StoreInternalKey and s.MatrixMemberId=1
 where     not  (l.posid=-66 or  l.posid=-99) 
    and   
	((l.earValue<>a.rewardValue) or (a.rewardValue is null ))  
--	and storename<>N'积分商城'
 order by  l.processDate

end;

-------------------**************************
select distinct storename,storeid   from DiffRecord

select sum(ce),convert(varchar(10),processDate,120) from DiffRecord   group by convert(varchar(10),processDate,120)
 select s.storeid, s.storename ,  l.*,a.*,ISNULL(l.earValue,0)-isnull(a.rewardValue,0)  as ce from   check_AtdPoint  a  left join  check_loaytyPoint l
 on l.loytranid=a.tranId and l.StoreInternalKey=a.storeInternalKey   and a.posid=l.posid  AND  not  (l.posid=-66 or  l.posid=-99)
  --and a.businessdate=l.posDatetime
  left join report_data.dbo.store_gs  s on a.StoreInternalKey=s.StoreInternalKey and s.MatrixMemberId=1
 where  
	(
--(l.earValue<>a.rewardValue) or
	 (l.loytranid is null )
	 )  
--	and storename<>N'积分商城'
order by  l.processDate
------reward  end 




 select s.storeid, s.storename ,
   l.*,a.*,isnull(a.earValue,0)-isnull(l.rewardValue,0)  as ce
  from  check_AtdPoint l  left join check_loaytyPoint  a
 on a.loytranid=l.tranId and l.StoreInternalKey=a.storeInternalKey   and a.posid=l.posid
  --and a.businessdate=l.posDatetime
left join report_data.dbo.store_gs  s on l.StoreInternalKey=s.StoreInternalKey and s.MatrixMemberId=1
 where     not  (l.posid=-66 or  l.posid=-99) 
    and   
	((a.earValue<>l.rewardValue) or (a.loytranid is null ))  
--	and   storename<>N'积分商城'
order by  a.posDatetime 
 

select sum(l.earValue-isnull(a.rewardValue,0))  as ce from check_loaytyPoint l  left join check_AtdPoint  a
 on l.loytranid=a.tranId and l.StoreInternalKey=a.storeInternalKey   and a.posid=l.posid
  --and a.businessdate=l.posDatetime
  left join report_data.dbo.store_gs  s on l.StoreInternalKey=s.StoreInternalKey and s.MatrixMemberId=1
 where     not  (l.posid=-66 or  l.posid=-99) 
    and   
	((l.earValue<>a.rewardValue) or (a.rewardValue is null ))   
/*
delete check_loaytyPoint   where  posInternalKey not  in (
 select  l.posInternalKey from check_loaytyPoint l  left join check_AtdPoint  a
 on l.loytranid=a.tranId and l.StoreInternalKey=a.storeInternalKey   and a.posid=l.posid
  --and a.businessdate=l.posDatetime
  left join report_data.dbo.store_gs  s on l.StoreInternalKey=s.StoreInternalKey and s.MatrixMemberId=1
 where     not  (l.posid=-66 or  l.posid=-99) 
    and   
	((l.earValue<>a.rewardValue) or (a.rewardValue is null ))  )
44359
*/


 --redeem point
	 select   s.storeid,   s.storename ,  l.*,a.*,l.redeemValue-isnull(a.redeemValue,0)  as ce   from check_loaytyPoint l
	   left join check_AtdPoint  a
 on l.loytranid=a.tranId and l.StoreInternalKey=a.storeInternalKey   and not  (l.posid=-66 or  l.posid=-99)
  --and a.businessdate=l.posDatetime
   left join report_data.dbo.store_gs  s on l.StoreInternalKey=s.StoreInternalKey and s.MatrixMemberId=1

 where   
	((l.redeemValue<>a.redeemValue) or (a.redeemValue is null )) and l.redeemValue-isnull(a.redeemValue,0)  <>0


	 select   s.storename ,  l.*,a.*,l.redeemValue-a.redeemValue  as ce   from  check_AtdPoint  a
	   left join   check_loaytyPoint l  
 on l.loytranid=a.tranId and l.StoreInternalKey=a.storeInternalKey   and not  (l.posid=-66 or  l.posid=-99)
  --and a.businessdate=l.posDatetime
   left join report_data.dbo.store_gs  s on a.StoreInternalKey=s.StoreInternalKey and s.MatrixMemberId=1

 where   
	((l.redeemValue<>a.redeemValue) or (l.redeemValue is  null )) and isnull(l.redeemValue,0)-a.redeemValue  <>0


select  *  from (select sum(rewardValue)  v ,c.tranId
  from  	check_AtdPoint  c  group by c.tranId
) b left join  (select sum(r.reward_point) v ,r.transaction_no  from R1_2_tran_reward r  group by r.transaction_no ) a
 on b.tranId=a.transaction_no 
 where   (b.v<>a.v)  or a.v is null 

select  *  from  (select sum(r.reward_point) v ,r.transaction_no  from R1_2_tran_reward r  group by r.transaction_no ) a
left join  (select sum(rewardValue)  v ,c.tranId
  from  	check_AtdPoint  c  group by c.tranId
) b   
 on b.tranId=a.transaction_no 
 where   (b.v<>a.v)  or a.transaction_no  is null 

/*
 select * from  	check_AtdPoint  c  where c.tranId not in (select r.transaction_no from  R1_2_tran_reward r ) and c.rewardValue<>0

select sum(r.reward_point) v    from R1_2_tran_reward r group by  r.transaction_no   order by r.transaction_no  where r.transaction_no=713456    
select * 
  from  	check_AtdPoint  c where c.tranId='713456'
  select sum(r.redemption_point_q) from R2_redemption_point r
  select sum(r.number_awarding) from R9_adjust r 
 exec est_hb '2020-07-31'
 select 
 * from R1_2_tran_reward
 */

/*
(No column name)	(No column name)
2562569	637150
select sum(rewardValue),sum(redeemvalue)
  from  	check_AtdPoint  
(No column name)	(No column name)
1556378	415070
select 1540422+15697-1556378
1369477
	select sum(earValue),sum(redeemvalue) 	 from check_loaytyPoint 
	 where       
	   not   (posid=-66 or  posid=-99)

	  select *  from  check_loaytyPoint  where redeemvalue=150 order by processdate
(No column name)	(No column name)
 select 56574-56514=60

select sum(earValue),sum(redeemvalue) from check_loaytyPoint 
	 where       
	     (posid=-66 or  posid=-99)  

		 select *  from check_loaytyPoint  
	 where       
	     (posid=-66 or  posid=-99) and  loytranid=99798589  order by loytranid
	 
	
	select sum(a.rewardValue),a.tranId   from  	check_AtdPoint   a group by a.tranId having sum(a.rewardValue)<>0       order by  tranid 
	

	
	select   *	 from check_loaytyPoint 
	 where  
	     not   (posid=-66 or  posid=-99)
		 and loytranid=656419
		 order by  2
		 
		 
	select * 	 from   r9_adjust   
	 where        transaction_no      not in (  select loytranid  from    check_loaytyPoint)
	  and   (posid=-66 or  posid=-99)
 select  *   from    r9_adjust
   select   sum(number_awarding)   from  [dbo].[DS_R9_adjust]

		 order by loytranid
 






;

 






 
 select  *  from Loyalty_Shell_Prod..CRM_POSTran  cpt  where cpt.BuyingUnitInternalKey=1687202
 select  *  from Loyalty_Shell_Prod..CRM_POSTran  cpt 
 left join  
 Loyalty_Shell_Prod.[dbo].[CRM_POSAccountsActivity] cpa on    cpa.PosTranInternalKey=cpt.POSTranInternalKey
 
  where  cpt.TranId=472492
 select  *  from Loyalty_Shell_Prod..CRM_POSTran  cpt  where  cpt.TranId= 61509293  and posdatetime='2019-04-10'



 select *  from Loyalty_Shell_Prod..CRM_Member  cm where cm.BuyingUnitInternalKey=1687202



 select *  from  Loyalty_Shell_Prod..CRM_BuyingUnit cbu where cbu.BuyingUnitInternalKey=1687202

*/


select *  from    Loyalty_Shell_Prod..CRM_POSAccountsActivity cpaa where  cpaa.PosTranInternalKey=10985841

select ftpra.*  from  ATD_Shell..FO_TranHeader202007 fth
left  join    ATD_Shell..FO_TranPromotionRewardApportionment202007 ftpra  on ftpra.TicketInternalKey=fth.TicketInternalKey
 where fth.TranId=20351


	
				  declare  @rq varchar(10)
				  set @rq='2019-07-02'
				  
        select  cpaa.PosDateTime,convert(varchar(10),ProcessDate,120) processdate ,sum(cpaa.EarnValue) ear  ,sum(cpaa.RedeemValue) redeem ,0  as a, 0  as b 
				 FROM [report_data].[dbo].[CRM_POSAccountsActivity]  cpaa  inner join Loyalty_Shell_Prod.dbo.CRM_POSTran cp  				 on cpaa.PosTranInternalKey=cp.PosTranInternalKey
		 		 where  		   
				  cpaa.AccountInternalKey=2  and convert(varchar(10),ProcessDate,120)=@rq --today not 
				  and cpaa.MatrixMemberId=1  and convert(varchar(10),cpaa.PosDateTime,120)<>@rq
				     group by  cpaa.PosDateTime,convert(varchar(10),ProcessDate,120)
		union all 
				 select  cpaa.PosDateTime, convert(varchar(10),ProcessDate,120),  0,0, sum(cpaa.EarnValue) ear  ,sum(cpaa.RedeemValue) redeem  
				 FROM [report_data].[dbo].[CRM_POSAccountsActivity]  cpaa  inner join Loyalty_Shell_Prod.dbo.CRM_POSTran cp 			 on cpaa.PosTranInternalKey=cp.PosTranInternalKey
		 		 where  		   
				  cpaa.AccountInternalKey=2  and convert(varchar(10),ProcessDate,120)<>@rq 	  and cpaa.MatrixMemberId=1  and convert(varchar(10),cpaa.PosDateTime,120)=@rq	  
                 group by cpaa.PosDateTime,convert(varchar(10),ProcessDate,120)
		  

				  set @rq='2019-04-27'
				  
select buaa.*		from       [Loyalty_Shell_Prod].[dbo].[CRM_Member] cm (nolock) 
  left join (	select cpaa.buyingUnitInternalKey,cpaa.balance  
				 FROM [report_data].[dbo].[CRM_POSAccountsActivity]  cpaa (nolock)
				 where   convert(varchar(10),cpaa.begin_date,120)<=@rq
				  and convert(varchar(10),end_date,120)>@rq and AccountInternalKey=2 
					and cpaa.MatrixMemberId=1 and cpaa.AccountInternalKey=2 )    buaa  --2017-11-22 增加matrixid
    on buaa.BuyingUnitInternalKey=cm.BuyingUnitInternalKey  
  left join  Loyalty_Shell_Prod.[dbo].[CRM_Clubcard]  cc (nolock) on  cc.ClubCardId=cm.ExternalMemberKey 
  left join  Loyalty_Shell_Prod.[dbo].CRM_BuyingUnit crmb (nolock) on cm.BuyingUnitInternalKey=crmb.BuyingUnitInternalKey 
  --and  crmb.MatrixMemberId=cc.MatrixMemberId
  left join  Loyalty_Shell_Prod.[dbo].[State_MP]  sp (nolock) on crmb.State=sp.StateId and sp.LanguageId=8

 left  join   report_data.[dbo].[v_get_reg_compAndStore]   s  (nolock) on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey --首次注册油站
 
   where  cm.externalmemberkey  is not null and s.MatrixMemberId=1  and cm.BuyingUnitInternalKey=1701279
  -- and  buaa.Balance  is not null
   --    declare   @rq varchar(10)
 
	  set @rq='2019-09-19'			

select sum(	balance)		from       [Loyalty_Shell_Prod].[dbo].[CRM_Member] cm (nolock) 
  left join (	select cpaa.buyingUnitInternalKey,cpaa.balance  
				 FROM [report_data].[dbo].[CRM_POSAccountsActivity]  cpaa (nolock)
				 where   convert(varchar(10),cpaa.begin_date,120)<=@rq
				  and convert(varchar(10),end_date,120)>@rq and AccountInternalKey=2 
				 )    buaa  --2017-11-22 增加matrixid
    on buaa.BuyingUnitInternalKey=cm.BuyingUnitInternalKey  
  left join  Loyalty_Shell_Prod.[dbo].[CRM_Clubcard]  cc (nolock) on  cc.ClubCardId=cm.ExternalMemberKey 
  left join  Loyalty_Shell_Prod.[dbo].CRM_BuyingUnit crmb (nolock) on cm.BuyingUnitInternalKey=crmb.BuyingUnitInternalKey 
  --and  crmb.MatrixMemberId=cc.MatrixMemberId
  left join  Loyalty_Shell_Prod.[dbo].[State_MP]  sp (nolock) on crmb.State=sp.StateId and sp.LanguageId=8

 left  join   report_data.[dbo].[v_get_reg_compAndStore]   s  (nolock) on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey --首次注册油站
 
   where  cm.externalmemberkey  is not null and s.MatrixMemberId=1 
  -- and  buaa.Balance  is not null
  drop table  r10_next
  drop table r10_last
--declare @rq varchar(10)
    set @rq='2019-10-24'
  select    balance ,buaa.BuyingUnitInternalKey into r10_last	from       [Loyalty_Shell_Prod].[dbo].[CRM_Member] cm (nolock) 
  left join (	select cpaa.buyingUnitInternalKey,cpaa.balance  
				 FROM [report_data].[dbo].[CRM_POSAccountsActivity]  cpaa (nolock)
				 where   convert(varchar(10),cpaa.begin_date,120)<=@rq
				  and convert(varchar(10),end_date,120)>@rq and AccountInternalKey=2 
				 )    buaa  --2017-11-22 增加matrixidext
    on buaa.BuyingUnitInternalKey=cm.BuyingUnitInternalKey  
  left join  Loyalty_Shell_Prod.[dbo].[CRM_Clubcard]  cc (nolock) on  cc.ClubCardId=cm.ExternalMemberKey 
  left join  Loyalty_Shell_Prod.[dbo].CRM_BuyingUnit crmb (nolock) on cm.BuyingUnitInternalKey=crmb.BuyingUnitInternalKey 
  --and  crmb.MatrixMemberId=cc.MatrixMemberId
  left join  Loyalty_Shell_Prod.[dbo].[State_MP]  sp (nolock) on crmb.State=sp.StateId and sp.LanguageId=8

 left  join   report_data.[dbo].[v_get_reg_compAndStore]   s  (nolock) on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey --首次注册油站
 
   where  cm.externalmemberkey  is not null and s.MatrixMemberId=1  and buaa.BuyingUnitInternalKey is not null 


 -- declare @rq varchar(10)

 drop table  TmpBuyingUnitExpired
    	  set @rq='2019-10-25'
					 
		select 		cpt.BuyingUnitInternalKey,   sum(cpard.RedeemValue) point_number
		 into TmpBuyingUnitExpired 
		
	  from  Loyalty_Shell_prod.dbo.CRM_PosAccountsActivity_RewardLog  cpard
	  left join Loyalty_Shell_prod.dbo.CRM_POSTran cpt  on cpard.Earn_PosTranInternalKey=cpt.POSTranInternalKey 
	  left join store_gs store on store.StoreInternalKey=cpt.StoreInternalKey and cpt.MatrixMemberId=store.MatrixMemberId
	  left join   Loyalty_Shell_prod.dbo.CRM_PosAccountsActivity cpaa on cpaa.PosTranInternalKey=cpard.Earn_PosTranInternalKey
	            
	  left join  report_data.dbo.v_get_reg_compAndStore  gs on cpt.BuyingUnitInternalKey=gs.BuyingUnitInternalKey and cpt.MatrixMemberId=1
	   and gs.MatrixMemberId=cpt.MatrixMemberId
	    where     --cpard.RewardStatusId=2 and convert(varchar(7),cpard.ProcessDate,120)='2019-06'
	  	cpard.RewardStatusId=2 and convert(varchar(10),cpard.ProcessDate,120)=@rq
		  and gs.MatrixMemberId=1 and cpaa.MatrixMemberId=1 and cpt.MatrixMemberId=1
		--  and cpt.BuyingUnitInternalKey=121
		  group by cpt.BuyingUnitInternalKey

   select sum(balance)  from r10_next
   select sum(balance)  from r10_last











   select  b.buyingUnitInternalKey,b.e,R1.*  from    ( select a.buyingUnitInternalKey , sum(a.balance) b ,sum(a.e) e ,sum(a.re) re 
	   from   ( select r.buyingUnitInternalKey,r.balance,0 e ,0 re  from 	r10_last   r
	 union   all
	 select    cpt.BuyingUnitInternalKey ,0,sum(clp.earValue) e ,sum(clp.redeemValue) re
	 from check_loaytyPoint clp left join Loyalty_Shell_Prod..CRM_POSTran cpt on cpt.POSTranInternalKey=clp.posInternalKey 
	group by  cpt.BuyingUnitInternalKey
	union all 
	select  e.BuyingUnitInternalKey,0,sum(-1*e.point_number) e,0   from  TmpBuyingUnitExpired e  group by e.BuyingUnitInternalKey
	)
  a  group by   BuyingUnitInternalKey  ) b left join 
   r10_next r1 on  
	  b.BuyingUnitInternalKey=r1.buyingUnitInternalKey 
	  where r1.buyingUnitInternalKey  is null 
	 OR  b.b +b.e-b.re<>r1.balance  
	 order by b.BuyingUnitInternalKey


  select  *   from  r10_last r where  r.buyingUnitInternalKey=12123   --69
  select  *   from  r10_next r where  r.buyingUnitInternalKey=9584548    --79
   select  *   from  TmpBuyingUnitExpired e where  e.buyingUnitInternalKey=12123    --79
  
   select    cpt.BuyingUnitInternalKey ,0,clp.earValue e ,clp.redeemValue re
	 from check_loaytyPoint clp left join Loyalty_Shell_Prod..CRM_POSTran cpt on cpt.POSTranInternalKey=clp.posInternalKey 
	where cpt.BuyingUnitInternalKey=121

	

SELECT * FROM RetailCode_MP
				  set @rq='2019-04-27' 
  select   cpaa.*  
				 FROM [report_data].[dbo].[CRM_POSAccountsActivity]  cpaa (nolock)
				 where --  convert(varchar(10),cpaa.begin_date,120)<=@rq
				--  and convert(varchar(10),end_date,120)>@rq and
				 AccountInternalKey=2 
					--and cpaa.MatrixMemberId=1
					 and cpaa.AccountInternalKey=2
					and cpaa.BuyingUnitInternalKey=9584548 ORDER BY PosTranInternalKey  DESC 
 

  
 SELECT *  FROM  Loyalty_Shell_Prod..CRM_Member CM WHERE CM.BuyingUnitInternalKey= 866484
 -- where    a.buyingUnitInternalKey not in 
(select   r1.buyingUnitInternalKey from  r10_tmo r1)
	SELECT *  FROM  report_data..RetailCode_MP  R WHERE R.MatrixMemberId=1 
select  sum(clp.earValue) e ,sum(clp.redeemValue) re
	 from check_loaytyPoint clp  left join Loyalty_Shell_Prod..CRM_POSTran cpt on cpt.POSTranInternalKey=clp.posInternalKey 
	 where cpt.BuyingUnitInternalKey not in (select  r.buyingUnitInternalKey from r10_26   r )
	 group by  cpt.BuyingUnitInternalKey  


select sum(ISNULL(a.e,0)),sum(isnull(a.re,0)),r.buyingUnitInternalKey ,a.BuyingUnitInternalKey     from 	   (
	select cpt.BuyingUnitInternalKey ,sum(clp.earValue) e ,sum(clp.redeemValue) re
	 from check_loaytyPoint clp left join Loyalty_Shell_Prod..CRM_POSTran cpt on cpt.POSTranInternalKey=clp.posInternalKey 
	group by  cpt.BuyingUnitInternalKey ) a  left join r10_26   r   on   r.buyingUnitInternalKey=a.BuyingUnitInternalKey 
	where r.buyingUnitInternalKey  is null 
	group by  r.buyingUnitInternalKey,a.BuyingUnitInternalKey

	select *  from   r10_26   r   where   r.buyingUnitInternalKey=1906918

  
				  set @rq='2019-04-27' 
select buaa.*,cm.*		from       [Loyalty_Shell_Prod].[dbo].[CRM_Member] cm (nolock) 
  left join (	select cpaa.buyingUnitInternalKey,cpaa.balance  
				 FROM [report_data].[dbo].[CRM_POSAccountsActivity]  cpaa (nolock)
				 where   convert(varchar(10),cpaa.begin_date,120)<=@rq
				  and convert(varchar(10),end_date,120)>@rq and AccountInternalKey=2 
					and cpaa.MatrixMemberId=1 and cpaa.AccountInternalKey=2 )    buaa  --2017-11-22 增加matrixid
    on buaa.BuyingUnitInternalKey=cm.BuyingUnitInternalKey  
  left join  Loyalty_Shell_Prod.[dbo].[CRM_Clubcard]  cc (nolock) on  cc.ClubCardId=cm.ExternalMemberKey 
  left join  Loyalty_Shell_Prod.[dbo].CRM_BuyingUnit crmb (nolock) on cm.BuyingUnitInternalKey=crmb.BuyingUnitInternalKey 
  --and  crmb.MatrixMemberId=cc.MatrixMemberId
   

-- left  join   report_data.[dbo].[v_get_reg_compAndStore]   s  (nolock) on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey --首次注册油站
 
   where  cm.externalmemberkey  is not null   and cm.BuyingUnitInternalKey=1701279

   --	  declare  @rq varchar(10)
				  set @rq='2019-05-31'
				  
        select  cpaa.PosDateTime,convert(varchar(10),ProcessDate,120) processdate ,sum(cpaa.EarnValue) ear  ,sum(cpaa.RedeemValue) redeem ,0  as a, 0  as b 
				 FROM [report_data].[dbo].[CRM_POSAccountsActivity]  cpaa  inner join Loyalty_Shell_Prod.dbo.CRM_POSTran cp  				 on cpaa.PosTranInternalKey=cp.PosTranInternalKey
		 		 where  		   
				  cpaa.AccountInternalKey=2  and convert(varchar(10),ProcessDate,120)=@rq --today not 
				  and cpaa.MatrixMemberId=1  and convert(varchar(10),cpaa.PosDateTime,120)<>@rq
				     group by  cpaa.PosDateTime,convert(varchar(10),ProcessDate,120)
		union all 
				 select  cpaa.PosDateTime, convert(varchar(10),ProcessDate,120),  0,0, sum(cpaa.EarnValue) ear  ,sum(cpaa.RedeemValue) redeem  
				 FROM [report_data].[dbo].[CRM_POSAccountsActivity]  cpaa  inner join Loyalty_Shell_Prod.dbo.CRM_POSTran cp 			 on cpaa.PosTranInternalKey=cp.PosTranInternalKey
		 		 where  		   
				  cpaa.AccountInternalKey=2  and convert(varchar(10),ProcessDate,120)<>@rq 	  and cpaa.MatrixMemberId=1  and convert(varchar(10),cpaa.PosDateTime,120)=@rq	  
                 group by cpaa.PosDateTime,convert(varchar(10),ProcessDate,120)


  --declare  @rq varchar(10)
				  set @rq='2019-12-01'
					 
		select 		convert(varchar(10),cpard.ProcessDate,120),   sum(cpard.RedeemValue) point_number, 'expired'
		 
		
	  from  Loyalty_Shell_prod.dbo.CRM_PosAccountsActivity_RewardLog  cpard
	  left join Loyalty_Shell_prod.dbo.CRM_POSTran cpt  on cpard.Earn_PosTranInternalKey=cpt.POSTranInternalKey 
	  left join store_gs store on store.StoreInternalKey=cpt.StoreInternalKey and cpt.MatrixMemberId=store.MatrixMemberId
	  left join   Loyalty_Shell_prod.dbo.CRM_PosAccountsActivity cpaa on cpaa.PosTranInternalKey=cpard.Earn_PosTranInternalKey
	            
	  left join  report_data.dbo.v_get_reg_compAndStore  gs on cpt.BuyingUnitInternalKey=gs.BuyingUnitInternalKey and cpt.MatrixMemberId=1
	   and gs.MatrixMemberId=cpt.MatrixMemberId
	    where     --cpard.RewardStatusId=2 and convert(varchar(7),cpard.ProcessDate,120)='2019-06'
	  	cpard.RewardStatusId=2 and cpard.ProcessDate>='2020-05-01' and  cpard.ProcessDate <'2020-06-01'
		  and gs.MatrixMemberId=1 and cpaa.MatrixMemberId=1 and cpt.MatrixMemberId=1
		  and cpaa.AccountInternalKey=2
		  group by convert(varchar(10),cpard.ProcessDate,120) 
		  order by  convert(varchar(10),cpard.ProcessDate,120) 

 
  --declare  @rq varchar(10)
  declare  @y table (busdate date,balance float)
   declare @i int ,@rq1 date
  set @rq1='2020-05-01'
  set @i=1
   while @rq1<'2020-06-01'
  begin 
  
   set @rq=convert(varchar(10),@rq1,120)
     insert into @y
		  select   @rq, sum(	balance)		from       [Loyalty_Shell_Prod].[dbo].[CRM_Member] cm (nolock) 
  left join (	select cpaa.buyingUnitInternalKey,cpaa.balance  
				 FROM [report_data].[dbo].[CRM_POSAccountsActivity]  cpaa (nolock)
				 where   convert(varchar(10),cpaa.begin_date,120)<=@rq
				  and convert(varchar(10),end_date,120)>@rq and AccountInternalKey=2 
					 )    buaa  --2017-11-22 增加matrixid
    on buaa.BuyingUnitInternalKey=cm.BuyingUnitInternalKey  
  left join  Loyalty_Shell_Prod.[dbo].[CRM_Clubcard]  cc (nolock) on  cc.ClubCardId=cm.ExternalMemberKey 
  left join  Loyalty_Shell_Prod.[dbo].CRM_BuyingUnit crmb (nolock) on cm.BuyingUnitInternalKey=crmb.BuyingUnitInternalKey 
  --and  crmb.MatrixMemberId=cc.MatrixMemberId
  left join  Loyalty_Shell_Prod.[dbo].[State_MP]  sp (nolock) on crmb.State=sp.StateId and sp.LanguageId=8

 left  join   report_data.[dbo].[v_get_reg_compAndStore]   s  (nolock) on s.BuyingUnitInternalKey=cm.BuyingUnitInternalKey --首次注册油站
   where  cm.externalmemberkey  is not null and s.MatrixMemberId=1 
   set @i=@i+1
   print @rq 
   set @rq1=dateadd(day,1,@rq1)
 end 
 select *  from  @y 

 --跨JV消费
 --declare  @rq varchar(10)
		

 select   convert(varchar(10),cpa.ProcessDate,120) ,sum(cpa.EarnValue),sum(RedeemValue ),sum(cpa.EarnValue)-sum(RedeemValue ) as je
 FROM 
 [report_data].[dbo].[CRM_POSAccountsActivity] cpa
 inner join  Loyalty_Shell_prod. [dbo].[CRM_POSTran] cp on cpa.PosTranInternalKey=cp.POSTranInternalKey
 left  join   report_data.[dbo].[v_get_reg_compAndStore]   s  (nolock) on s.BuyingUnitInternalKey=cpa.BuyingUnitInternalKey --首次注册油站
 
  where    convert(varchar(7),cpa.ProcessDate,120)= '2020-05' and
    s.MatrixMemberId=1 and cpa.MatrixMemberId not  in (0,1) 
	group by  convert(varchar(10),cpa.ProcessDate,120) 
	order by 1

-- and cp.BuyingUnitInternalKey=323812
 -- and cp.TranId=26845
 --and  not  (posid=-66 or  posid=-99)
 
 



END




GO
