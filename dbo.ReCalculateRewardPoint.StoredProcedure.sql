USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[ReCalculateRewardPoint]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ReCalculateRewardPoint]
	@date varchar(10)
AS
BEGIN


  
 
--set @date='2018-12-02'
print 'get loyaty ce ' 
 exec  getLoyaltyCE   @date
  
 --select  *  from   check_loaytyPoint  where loytranid='513801'
update   check_loaytyPoint  set mark='1' 
 delete  FO_TranPromotionRewardApportionment

--insert into  FO_TranPromotionRewardApportionment (TicketInternalKey,RewardValue, EntityId) 
 --select *    from ATD_Shell..FO_TranPromotionRewardApportionment201907  where PromotionId not in (14,15,16)
 print '1'
 insert into FO_TranPromotionRewardApportionment(TicketInternalKey,RewardValue, EntityId) 
 select    fth.TicketInternalKey, case  when  case  when fts.amount>0 then  floor((fts.amount-isnull(ftpra.RewardValue,0))/fts.Price)
   else  ceiling ((fts.amount-isnull(ftpra.RewardValue,0))/fts.Price)  end >80 then 80 else   case  when fts.amount>0 then  floor((fts.amount-isnull(ftpra.RewardValue,0))/fts.Price)
   else  ceiling ((fts.amount-isnull(ftpra.RewardValue,0))/fts.Price)  end end  as jf,fts.ItemId 
 from  ATD_Shell..FO_TranCollection(nolock)  ftc 
 inner join report_data..store_gs gs  on ftc.StoreId=gs.storeid  and gs.MatrixMemberId=1
left join ATD_Shell..fo_tranheader201907(nolock)  fth  on fth.CollectionInternalKey= ftc.CollectionInternalKey
left join (  select  TicketInternalKey,itemid, price,sum(amount) amount   from ( select  fts1.TicketInternalKey,itemid, price,sum(amount) amount  
        from (select  distinct   fts.TicketInternalKey,fts.Price,amount ,ItemId  from   ATD_Shell..FO_TranSale201907(nolock) fts
		  left join item_cat item(nolock) on item.MainItemId=fts.ItemId and item.MatrixMemberId=1
		  where (item.midtypeCode in  ('1001'))   ) fts1  group by fts1.TicketInternalKey,itemid, price  
		union all 
		select distinct  ftt.TicketInternalKey,fts.ItemId,fts.Price,-1*ftt.Amount  as amount   from     ATD_Shell..FO_TranTender201907(nolock)  ftt   
		left join(  select distinct  fts.TicketInternalKey,fts.Price,ItemId  from   ATD_Shell..FO_TranSale201907(nolock) fts
		  left join item_cat(nolock) item on item.MainItemId=fts.ItemId and item.MatrixMemberId=1
		  where (item.midtypeCode in  ('1001')) )  fts on ftt.TicketInternalKey = fts.TicketInternalKey
		
				) aa   group by TicketInternalKey,itemid, price   ) fts   on fts.TicketInternalKey=fth.TicketInternalKey
left join report_data..check_loaytyPoint clp on clp.loytranid=fth.TranId and clp.posid=ftc.TillId 

and  clp.StoreInternalKey=gs.StoreInternalKey
left join ( select  ft.TicketInternalKey,ft.EntityId,sum(ft.RewardValue) rewardvalue  from  ATD_Shell..FO_TranPromotionRewardApportionment201907(nolock) ft  
         where ft.RewardMethodId=4   group by ft.TicketInternalKey,ft.EntityId)  ftpra    
   on ftpra.TicketInternalKey=fts.TicketInternalKey and fts.ItemId=ftpra.EntityId 
   left join item_cat item on item.MainItemId=fts.ItemId and item.MatrixMemberId=1
where   clp.mark='1'  and ftc.BusinessDate= @date and( (item.midtypeCode in  ('1001') /* and  item.MainItemId  not in ('1032') */)  or item.MainItemId in ('1032','1035','1036') )

-- and fth.TicketInternalKey<>1775950
 --and  fts.TicketInternalKey=1691406
 print '2'
insert into FO_TranPromotionRewardApportionment(TicketInternalKey,RewardValue, EntityId) 
 select    fth.TicketInternalKey, case  when  case  when fts.amount>0 then  floor((fts.amount-isnull(ftpra.RewardValue,0))/fts.Price/2)
   else  ceiling ((fts.amount-isnull(ftpra.RewardValue,0))/fts.Price/2)  end >40 then  40 else   case  when fts.amount>0 then  floor((fts.amount-isnull(ftpra.RewardValue,0))/fts.Price/2)
   else  ceiling ((fts.amount-isnull(ftpra.RewardValue,0))/fts.Price/2)  end end as jf,fts.ItemId 
   from  ATD_Shell..FO_TranCollection(nolock)  ftc 
   inner join report_data..store_gs gs  on ftc.StoreId=gs.storeid  and gs.MatrixMemberId=1
left join ATD_Shell..fo_tranheader201907(nolock)  fth  on fth.CollectionInternalKey= ftc.CollectionInternalKey
left join (select  fts1.TicketInternalKey,itemid, price,sum(amount) amount  
        from  ATD_Shell..fo_transale201907(nolock)  fts1  group by fts1.TicketInternalKey,itemid, price  ) fts  on fts.TicketInternalKey=fth.TicketInternalKey
left join report_data..check_loaytyPoint clp on clp.loytranid=fth.TranId and clp.posid=ftc.TillId 

and  clp.StoreInternalKey=gs.StoreInternalKey
left join ( select  ft.TicketInternalKey,ft.EntityId,sum(ft.RewardValue) rewardvalue  from  ATD_Shell..FO_TranPromotionRewardApportionment201907(nolock) ft  
         where ft.RewardMethodId=4   group by ft.TicketInternalKey,ft.EntityId)  ftpra    
   on ftpra.TicketInternalKey=fts.TicketInternalKey and fts.ItemId=ftpra.EntityId 
   left join item_cat(nolock) item on item.MainItemId=fts.ItemId and item.MatrixMemberId=1
where   clp.mark='1'  and ftc.BusinessDate= @date and( item.midtypeCode in  ('1002')       /*   or item.MainItemId in ('1032') */ )

--and  fts.TicketInternalKey= 2461900 



  -----
delete   FO_TranPromotionRewardApportionment_t



print '3'
insert into FO_TranPromotionRewardApportionment_t(TicketInternalKey,RewardValue, EntityId)  
 select  ftsa.TicketInternalKey, round(mx.amount/ftsa.amountz   *ftsa.earvalue,2) ,mx.ItemId  from 
 (
select TicketInternalKey,sum(amount)  amountz ,  avg(fth1.earValue)  earvalue from  
(select  ItemId, ftpra1.TicketInternalKey,amount,clp1.earValue  from ( --22
select   ItemId,TicketInternalKey,  sum(fts.Amount)  amount from  ATD_Shell..FO_TranSale201907(nolock) 
fts  left join item_cat item on item.MainItemId=fts.ItemId  and item.MatrixMemberId=1 
			   where    (item.midtypeCode   in  ('1001','1002')   or item.midtypeCode in  ('1001')  or item.MainItemId in ('1032','1035','1036') ) 

     and fts.TicketInternalKey<> 581777  and  fts.TicketInternalKey in 
 (   ---1
select   ftpra.TicketInternalKey 
 from  ATD_Shell..FO_TranCollection(nolock)  ftc 
 inner join report_data..store_gs gs  on ftc.StoreId=gs.storeid  and gs.MatrixMemberId=1
left join ATD_Shell..fo_tranheader201907(nolock)  fth  on fth.CollectionInternalKey= ftc.CollectionInternalKey
left join report_data..check_loaytyPoint clp on clp.loytranid=fth.TranId and clp.posid=ftc.TillId 

and  clp.StoreInternalKey=gs.StoreInternalKey
left join ( select TicketInternalKey,sum(RewardValue) rewardvalue  from (  select  ft.TicketInternalKey,sum(ft.RewardValue) rewardvalue  from  FO_TranPromotionRewardApportionment ft  
          group by ft.TicketInternalKey   
		   union  all
		  select  ftpra.TicketInternalKey,ftpra.RewardValue 
		    from  ATD_Shell..FO_TranPromotionRewardApportionment201907(nolock) ftpra    where  ftpra.PromotionId  not in (14,15)
			 and ftpra .RewardMethodId=1 and RewardId=100
	  ) ft1 
		 group by TicketInternalKey   )  ftpra     on ftpra.TicketInternalKey=fth.TicketInternalKey

where   clp.mark='1'  and ftc.BusinessDate=@date  and clp.earValue<>ftpra.rewardvalue   )  --1 --found the <> tick
group by   ItemId,TicketInternalKey)  ftpra1  -- 22 caculate zs 

 left join 
(
select  fth.TicketInternalKey, clp.earValue earvaluez ,clp.earValue-isnull(ftpra.earvalue,0) as earvalue 
 from  ATD_Shell..FO_TranCollection  ftc 
 inner join report_data..store_gs gs  on ftc.StoreId=gs.storeid  and gs.MatrixMemberId=1 
left join ATD_Shell..fo_tranheader201907(nolock)  fth  on fth.CollectionInternalKey= ftc.CollectionInternalKey
left join report_data..check_loaytyPoint clp on clp.loytranid=fth.TranId and clp.posid=ftc.TillId 
 and  clp.StoreInternalKey=gs.StoreInternalKey
left join  (select ftpra.TicketInternalKey,sum(ftpra.RewardValue) earvalue 
         from  ATD_Shell..FO_TranPromotionRewardApportionment201907(nolock) ftpra
		 where  ftpra.PromotionId  not in (14,15) and
		  RewardMethodId=1 and RewardId=100  group by ftpra.TicketInternalKey ) ftpra
		  on fth.TicketInternalKey=ftpra.TicketInternalKey
		--  where fth.TicketInternalKey=1106776  
		  )  clp1  on ftpra1.TicketInternalKey=clp1.TicketInternalKey   )  fth1  group by TicketInternalKey ) ftsa

left join (select  ItemId, ftpra1.TicketInternalKey,amount,earValue  from (
select   ItemId,TicketInternalKey,  sum(fts.Amount)  amount from  ATD_Shell..FO_TranSale201907(nolock)
 fts   left join item_cat item on item.MainItemId=fts.ItemId  and item.MatrixMemberId=1 
			   where   (item.midtypeCode   in  ('1001','1002')   or item.midtypeCode in  ('1001')  or item.MainItemId in ('1032','1035','1036') ) 

     and  fts.TicketInternalKey in (
select   ftpra.TicketInternalKey 
 from  ATD_Shell..FO_TranCollection  ftc 
 inner join report_data..store_gs gs  on ftc.StoreId=gs.storeid  and gs.MatrixMemberId=1
left join ATD_Shell..fo_tranheader201907(nolock)  fth  on fth.CollectionInternalKey= ftc.CollectionInternalKey
left join report_data..check_loaytyPoint clp on clp.loytranid=fth.TranId and clp.posid=ftc.TillId 

and  clp.StoreInternalKey=gs.StoreInternalKey
left join ( select TicketInternalKey,sum(RewardValue) rewardvalue  from (  select  ft.TicketInternalKey,sum(ft.RewardValue) rewardvalue  from  FO_TranPromotionRewardApportionment ft  
          group by ft.TicketInternalKey   
		   union  all
		  select  ftpra.TicketInternalKey,ftpra.RewardValue 
		    from  ATD_Shell..FO_TranPromotionRewardApportionment201907(nolock) ftpra    where  ftpra.PromotionId  not in (14,15)
			 and ftpra .RewardMethodId=1 and RewardId=100
	  ) ft1 
		 group by TicketInternalKey   )  ftpra     on ftpra.TicketInternalKey=fth.TicketInternalKey

where   clp.mark='1'  and ftc.BusinessDate=@date  and clp.earValue<>ftpra.rewardvalue ) 
group by   ItemId,TicketInternalKey)  ftpra1 

 left join 
(

select  fth.TicketInternalKey, clp.earValue earvaluez ,clp.earValue-isnull(ftpra.earvalue,0) as earvalue 
 from  ATD_Shell..FO_TranCollection  ftc 
 inner join report_data..store_gs gs  on ftc.StoreId=gs.storeid  and gs.MatrixMemberId=1  
left join ATD_Shell..fo_tranheader201907(nolock)  fth  on fth.CollectionInternalKey= ftc.CollectionInternalKey
left join report_data..check_loaytyPoint clp on clp.loytranid=fth.TranId and clp.posid=ftc.TillId 
and  clp.StoreInternalKey=gs.StoreInternalKey
left join  (select ftpra.TicketInternalKey,sum(ftpra.RewardValue) earvalue 
         from  ATD_Shell..FO_TranPromotionRewardApportionment201907(nolock) ftpra
		 where  ftpra.PromotionId  not in (14,15) and
		  RewardMethodId=1 and RewardId=100  group by ftpra.TicketInternalKey ) ftpra
		  on fth.TicketInternalKey=ftpra.TicketInternalKey 
		-- where fth.TicketInternalKey=1063651  
		  )  clp1  on ftpra1.TicketInternalKey=clp1.TicketInternalKey ) mx
on mx.TicketInternalKey=ftsa.TicketInternalKey
--where  ftsa.TicketInternalKey=1063651
delete  FO_TranPromotionRewardApportionment  where 
	 exists   (select 1  from FO_TranPromotionRewardApportionment_t t where t.TicketInternalKey=FO_TranPromotionRewardApportionment.TicketInternalKey
	 and t.EntityId=FO_TranPromotionRewardApportionment.EntityId )
	 print '4'
	 insert into FO_TranPromotionRewardApportionment(TicketInternalKey,RewardValue, EntityId,LineId)  
select TicketInternalKey,RewardValue, EntityId,999   from  FO_TranPromotionRewardApportionment_t t



---********
/*select gs.storename, clp.posDatetime, ftpra.TicketInternalKey,ftpra.rewardvalue  ,clp.earValue,clp.loytranid,clp.posInternalKey 
 from  ATD_Shell..FO_TranCollection  ftc 
left join ATD_Shell..fo_tranheader201907  fth  on fth.CollectionInternalKey= ftc.CollectionInternalKey
left join report_data..check_loaytyPoint clp on clp.loytranid=fth.TranId and clp.posid=ftc.TillId 
inner join report_data..store_gs gs  on ftc.StoreId=gs.storeid  and gs.MatrixMemberId=1
and  clp.StoreInternalKey=gs.StoreInternalKey 
left join ( select TicketInternalKey,sum(RewardValue) rewardvalue  from (  select  ft.TicketInternalKey,sum(ft.RewardValue) rewardvalue 
            from  FO_TranPromotionRewardApportionment ft  
          group by ft.TicketInternalKey   
		   union  all
		  select  ftpra.TicketInternalKey,ftpra.RewardValue 
		    from  ATD_Shell..FO_TranPromotionRewardApportionment201907 ftpra    where  ftpra.PromotionId  not in (14,15,16)
			 and ftpra .RewardMethodId=1 and RewardId=100
	  ) ft1 
		 group by TicketInternalKey   )  ftpra     on ftpra.TicketInternalKey=fth.TicketInternalKey

where   clp.mark='1'  and ftc.BusinessDate=@date  and (clp.earValue<>ftpra.rewardvalue  or ftpra.rewardvalue  is null )
  order by rewardvalue   */
----*******


--*************
print '5'
insert into FO_TranPromotionRewardApportionment(TicketInternalKey,RewardValue, EntityId,LineId) 
select fth.TicketInternalKey,-1*RewardValue, EntityId  ,999 
 from ATD_Shell..FO_TranPromotionRewardApportionment201907 ftpra 
 left join ATD_Shell..fo_tranheader201907  fth  on ftpra.TicketInternalKey=fth.TicketInternalKey
 left join   ATD_Shell..FO_TranCollection  ftc   on fth.CollectionInternalKey= ftc.CollectionInternalKey
  
  where  ftpra.PromotionId   in (14,15)
  and fth.TicketInternalKey in (  select TicketInternalKey  from  FO_TranPromotionRewardApportionment fa )
			 and ftpra .RewardMethodId=1 and RewardId=100  and ftc.BusinessDate=@date

 select  sum(RewardValue)    from  FO_TranPromotionRewardApportionment 
END


GO
