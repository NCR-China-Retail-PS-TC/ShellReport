USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[getDelayPromotion]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	get the promotion which  expired was not  stopped  automatic 
-- =============================================
CREATE  PROCEDURE  [dbo].[getDelayPromotion]
	
AS
BEGIN
declare   @month char(6),@sqltext  varchar(max);
    SET @month=  convert(varchar(6),getdate(),112);
delete CheckDelayPromotion where createdate=convert(varchar(10),getdate()-1,120); 	 
SET @sqltext=N'	insert into  [CheckDelayPromotion] (MatrixMemberId,tranid,storeId,storename,promotionheadid,businessDate,promotionEnddate,tranStartDate,createdate)
      select gs.MatrixMemberId, fth.TranId, gs.storeid,gs.storename,ftprd1.PromotionId,ftc.BusinessDate,pd.EndDate ,fth.StartDateTime,convert(varchar(10),getdate(),120)
     from    [ATD_Shell].dbo.FO_TranHeader201901 fth
			  inner  join [ATD_Shell].[dbo].[FO_TranCollection] ftc
on ftc.CollectionInternalKey=fth.CollectionInternalKey
    left join  Loyalty_Shell_uat. [dbo].[CRM_POSTran] cp 
    on cp.TranId=fth.TranId and cp.PosDateTime=ftc.BusinessDate  
	    and cp.PosId=ftc.TillId
	  left join Loyalty_Shell_uat.dbo.CRM_Member cm on cm.BuyingUnitInternalKey=cp.BuyingUnitInternalKey
 left join   [ATD_Shell].dbo.FO_TranPromotionRewardApportionment201901 ftprd1  on ftprd1.TicketInternalKey=fth.TicketInternalKey
 inner join store_gs gs on gs.storeid=ftc.StoreId  and gs.MatrixMemberId=cp.MatrixMemberId
 left join  mp_shell..PromotionHeader_PR pr  on pr.PromotionHeaderid=ftprd1.PromotionId
 left join [Promotion_Shell].[dbo].[PromotionDistribution] pd  on pd.PromotionHeaderId=ftprd1.PromotionId and gs.StoreInternalKey=pd.DistributedStoreInternalKey
 and pd.MatrixMemberId=gs.MatrixMemberId
 where  fth.StartDateTime>pd.EndDate';

 SET  @sqltext=@sqltext+ '   UNION  all 
 select gs.MatrixMemberId, fth.TranId, gs.storeid,gs.storename,ftprd1.PromotionId,ftc.BusinessDate,pd.EndDate ,fth.StartDateTime,convert(varchar(10),getdate(),120)
   from    [ATD_Shell].dbo.FO_TranHeader201901 fth
			  inner  join [ATD_Shell].[dbo].[FO_TranCollection] ftc
on ftc.CollectionInternalKey=fth.CollectionInternalKey
   left join  Loyalty_Shell_uat. [dbo].[CRM_POSTran] cp 
    on cp.TranId=fth.TranId and cp.PosDateTime=ftc.BusinessDate  and cp.PosId=ftc.TillId
	   left join   [ATD_Shell].dbo.FO_TranPromotionRewardApportionment201901 ftprd1  on ftprd1.TicketInternalKey=fth.TicketInternalKey
 inner join store_gs gs on gs.storeid=ftc.StoreId  and gs.MatrixMemberId=cp.MatrixMemberId
 left join    [Promotion_Shell].[dbo].[PromotionDistribution] pd  on pd.MatrixMemberId=cp.MatrixMemberId and pd.PromotionHeaderId=ftprd1.[PromotionId]
  and pd.DistributedStoreInternalKey=0
 where  fth.StartDateTime>pd.EndDate ';
set @sqltext = replace(@sqltext,'201901',@month);
 exec  (@sqltext);
  
END


GO
