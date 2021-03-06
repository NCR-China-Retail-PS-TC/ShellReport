USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[CrossJV_Document]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Ryan Liang
-- Create date: 2019.8.1
-- Description:	Create Cross JV Document (优惠券跨JV报告)
-- =============================================
/*
	exec CrossJV_Document 1, '2019/12/1'
	select * from dbo.CrossJVTemp_Document

	exec CrossJV_Document 4, '2019/12/1'
	select * from dbo.CrossJVTemp_Document

	exec CrossJV_Document 6, '2019/12/1'
	select * from dbo.CrossJVTemp_Document
*/
CREATE procedure [dbo].[CrossJV_Document]
(	
    @MatrixMemberId int, 
    @BusinessDate datetime
)
as
    begin
        set nocount on;
        if object_Id('dbo.CrossJVTemp_Document', 'U') is not null
            drop table dbo.CrossJVTemp_Document;

        declare @ParmDefinition nvarchar(max)= N'@MatrixMemberId int, @BusinessDate date';
        declare @sql nvarchar(max) = N'
        select 
        CONVERT(char(6),redeemTran.CreatedAt,112) as yyyyMM,
        regStore.compid,
        regStore.comp,
        doc.Barcode as coupon_code,
        issueJV.JVEN as issueJVName,
        issueStore.storeid as coupon_release_SiteID,
        convert(char(10), doc.CreationDateTime, 111) as coupon_rewarding_date,
        doc.EndDate as coupon_expired_date,
        redeemTran.CreatedAt as coupon_redemption_date,
        redeemJV.JVEN as redeemJVName,
        redeemStore.storeid as redeemStoreId,
        redeemStore.storename as redeemStoreName,
        case --mid
            when item.firsttypeCode = ''10''
            then item.MainItemId
            else item.midtypeCode
        end as midTypeCode,
        case --name
            when item.firsttypeCode = ''10''
            then item.FullName
            else item.midtype
        end as midTypeName,
        item.MainItemId,
        item.FullName,
        isnull(issueMA.AdjustmentValue, 0) as point, --优惠券扣减积分数量
        isnull(issueMA.AdjustmentValue, 0) * 0.05 as pointValue, --优惠券扣减积分价值
        CAST(reward.RewardValue as decimal(10,2)) pointje, --优惠券实际抵扣金额
        case
            when (isnull(issueMA.AdjustmentValue, 0) * 0.05) > CAST(reward.RewardValue as decimal(10,2))
            then (isnull(issueMA.AdjustmentValue, 0) * 0.05) - CAST(reward.RewardValue as decimal(10,2))
            else 0
        end as GreaterPointValue, --积分价值高于实际抵扣金额
        case
            when (isnull(issueMA.AdjustmentValue, 0) * 0.05) <= CAST(reward.RewardValue as decimal(10,2))
            then CAST(reward.RewardValue as decimal(10,2)) - (isnull(issueMA.AdjustmentValue, 0) * 0.05)
            else 0
        end as LowerPointValue--积分价值低于实际抵扣金额
        into CrossJVTemp_Document'

		set @sql = @sql + N'
        from #Loyalty#..CRM_LoyaltyDocuments (nolock) as doc
        join #Loyalty#..CRM_POSLoyaltyDocumentsActivity (nolock) as issueAct on doc.DocumentInternalKey = issueAct.DocumentInternalKey and issueAct.Action = 0
        join #Loyalty#..CRM_POSLoyaltyDocumentsActivity (nolock) as redeemAct on doc.DocumentInternalKey = redeemAct.DocumentInternalKey and redeemAct.Action = 1
        join report_data..v_get_reg_compAndStore (nolock) as regStore on regStore.BuyingUnitInternalKey = doc.IssuedBuyingUnitInternalKey';

		set @sql = @sql + N'
        --issue tran
        join #Loyalty#..CRM_POSTran (nolock) as issuePosTran on issuePosTran.POSTranInternalKey = issueAct.POSTranInternalKey and issuePosTran.PosDateTime = issueAct.PosDateTime
        join report_data..store_gs (nolock) as issueStore on issueStore.MatrixMemberId = issuePosTran.MatrixMemberId and issueStore.StoreInternalKey = issuePosTran.StoreInternalKey
        join CrossJVConfig as issueJV on issueJV.MatrixMemberId = issuePosTran.MatrixMemberId
        join report_data..RetailCode_MP (nolock) as issueRetailCode on issueRetailCode.MatrixMemberId = issuePosTran.MatrixMemberId
        join #ATD#..FO_TranCollection (nolock) as issueCollect on issueCollect.BusinessDate = issuePosTran.PosDateTime and issueCollect.RetailerId = issueRetailCode.RetailerId and issueCollect.StoreId = issueStore.storeid and issueCollect.TillId = issuePosTran.PosId
        join #ATD#..FO_TranHeader#YYYYMM# (nolock) as issueHeader on issueHeader.CollectionInternalKey = issueCollect.CollectionInternalKey and issueHeader.TranId = issuePosTran.TranId
        join #ATD#..FO_TranPromotionIssuedDocument#YYYYMM# (nolock) as issueTranDoc on issueTranDoc.TicketInternalKey = issueHeader.TicketInternalKey and issueTranDoc.DocumentId = doc.Barcode
        left join #ATD#..FO_TranPromotionMemberAccount#YYYYMM# (nolock) as issueMA on issueMA.TicketInternalKey = issueHeader.TicketInternalKey and issueMA.PromotionId = issueTranDoc.PromotionId and issueMA.MemberAccountID = 100';

		set @sql = @sql + N'
		--redeem tran
        join #Loyalty#..CRM_POSTran (nolock) as redeemTran on redeemTran.POSTranInternalKey = redeemAct.POSTranInternalKey and redeemTran.PosDateTime = redeemAct.PosDateTime
        join report_data..store_gs (nolock) as redeemStore on redeemStore.MatrixMemberId = redeemTran.MatrixMemberId and redeemStore.StoreInternalKey = redeemTran.StoreInternalKey
        join CrossJVConfig as redeemJV on redeemJV.MatrixMemberId = redeemTran.MatrixMemberId
        join report_data..RetailCode_MP (nolock) as redeemRetailCode on redeemRetailCode.MatrixMemberId = redeemTran.MatrixMemberId
        join #ATD#..FO_TranCollection (nolock) as redeemCollect on redeemCollect.BusinessDate = redeemTran.PosDateTime and redeemCollect.RetailerId = redeemRetailCode.RetailerId and redeemCollect.StoreId = redeemStore.storeid and redeemCollect.TillId = redeemTran.PosId
        join #ATD#..FO_TranHeader#YYYYMM# (nolock) as redeemHeader on redeemHeader.CollectionInternalKey = redeemCollect.CollectionInternalKey and redeemHeader.TranId = redeemTran.TranId
        join #ATD#..FO_TranPromotionIssuedDocument#YYYYMM# (nolock) as redeemTranDoc on redeemTranDoc.TicketInternalKey = redeemHeader.TicketInternalKey and redeemTranDoc.DocumentId = doc.Barcode
        join #ATD#..FO_TranPromotionRewardApportionment#YYYYMM# (nolock) as reward on reward.TicketInternalKey = redeemHeader.TicketInternalKey and reward.PromotionId = redeemTranDoc.PromotionId and reward.RewardMethodId = 4
        left join report_data..item_cat (nolock) as item on item.MainItemId = reward.EntityId and item.MatrixMemberId = redeemTran.MatrixMemberId

        where 1 = 1
            --and left(doc.Barcode,1) = ''0''
			and year(redeemAct.PosDateTime) = year(@BusinessDate)
	        and month(redeemAct.PosDateTime) = month(@BusinessDate)
			and issuePosTran.MatrixMemberId = @MatrixMemberId
			and issueJV.JVEN != redeemJV.JVEN';
        
		declare @_sql nvarchar(max);
		exec ReplaceSQL @sql, @BusinessDate, @_sql output;

		--select @_sql;
        execute sp_executesql 
                @_sql,
                @ParmDefinition,
                @MatrixMemberId = @MatrixMemberId,
				@BusinessDate = @BusinessDate;
    end;

GO
