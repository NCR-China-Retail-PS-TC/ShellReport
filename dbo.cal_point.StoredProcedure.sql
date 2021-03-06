USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[cal_point]    Script Date: 1/19/2022 9:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure  [dbo].[cal_point] 
( @date varchar(20))
as 
begin 

select mx.TicketInternalKey,1 as lineid,'3794' as promotionId ,1 as rewardMethodid,100 as rewardid
,round((cpa.EarnValue-cpa.RedeemValue)*(mx.amount/mx.zje),0) as rewardValue,'' as referencelined, mx.ItemId as entityid, 0 as entitytype,
'' as hierarchid, 3 as hlever ,1 as rewardedqty
,round((cpa.EarnValue-cpa.RedeemValue),2)  zreward into report_data..FO_TranPromotionRewardApportionment2020041
  from Loyalty_Shell_Prod..CRM_POSAccountsActivity  cpa
inner join Loyalty_Shell_Prod..CRM_POSTran cpt on cpa.PosTranInternalKey=cpt.PosTranInternalKey
inner join report_data..store_gs store on cpt.StoreInternalKey=store.StoreInternalKey
inner join ( 
select sum(fts.Amount) as amount,  fth.TicketInternalKey,  ftt.amount as zje, fts.ItemId,ftc.BusinessDate,ftc.TillId ,fth.TranId  , ftc.StoreId  
from  ATD_Shell..FO_TranCollection ftc 
left join ATD_Shell..FO_TranHeader202004 fth  on ftc.CollectionInternalKey=fth.CollectionInternalKey
left join  ATD_Shell..FO_TranSale202004 fts  on fth.TicketInternalKey=fts.TicketInternalKey
left join (  select fts.TicketInternalKey,sum(fts.Amount) amount   from   ATD_Shell..FO_TranSale202004 fts  group by fts.TicketInternalKey ) ftt
 on  ftt.TicketInternalKey=fts.TicketInternalKey
where ftc.RetailerId=2 and fth.CreatedDate>='2020-04-09'  and fth.CreatedDate<'2020-04-21' 

group by   fth.TicketInternalKey,  ftt.amount  , fts.ItemId,ftc.BusinessDate,ftc.TillId ,fth.TranId  , ftc.StoreId 


    )
mx on cpa.PosDateTime=mx.BusinessDate and cpt.PosId=mx.TillId and mx.TranId=cpt.TranId and mx.StoreId=store.storeid
 and cpt.MatrixMemberId=4 and zje<>0
 order by mx.TicketInternalKey

select *   from  Loyalty_Shell_Prod..CRM_POSTran cpt
inner join Loyalty_Shell_Prod..CRM_POSAccountsActivity  cpa  on cpa.PosTranInternalKey=cpt.PosTranInternalKey
inner join report_data..store_gs store on cpt.StoreInternalKey=store.StoreInternalKey
where cpt.PosId=1 and cpt.TranId=620362 and cpt.StoreInternalKey=125 and store.MatrixMemberId=4 and cpt.POSTranInternalKey=''

select *  from report_data..store_gs where storeid='600Z'
 exec est_sx_tmp '2020-04-09'
 exec est_sx_tmp '2020-04-10'
  exec est_sx_tmp '2020-04-11'
   exec est_sx_tmp '2020-04-12'
    exec est_sx_tmp '2020-04-13'
	 exec est_sx_tmp '2020-04-14'
 exec est_sx_tmp '2020-04-15'
  exec est_sx_tmp '2020-04-16'
   exec est_sx_tmp '2020-04-17'
 exec est_sx_tmp '2020-04-18'
 exec est_sx_tmp '2020-04-19'
 exec est_sx_tmp '2020-04-20'
 
 select  sum(r.reward_point) from DS_R1_2_tran_reward r   --   group by StoreType
  select  sum(r.reward_point) from R1_2_tran_reward r

  
      print N' ---插入交易积分'
	  declare @d varchar(10)='2020-04-20'
  exec [erp_ds_sx_tmp] @d
  exec [dbo].[pro_e1_single_leg_reward_sx]  @d
  exec pro_e4_mult_reward_sx  @d
 
 select sum(a) from ( 
  select sum(e.point_number) a  ,point_type from E1_single_leg_reward e
   where e.Create_date='2020-04-22' and e.RetailerId=2 
    group by e.point_type
   union all 
    select sum(e.point_number) ,point_type  from e4_mult_reward e
	 where e.Create_date='2020-04-22' and e.RetailerId=2

 group by e.point_type) aa
end
GO
