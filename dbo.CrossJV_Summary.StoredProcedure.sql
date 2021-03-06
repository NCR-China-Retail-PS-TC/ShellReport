USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[CrossJV_Summary]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Ryan Liang
-- Create date: 2019.8.1
-- Description:	Create Cross JV Summary (跨JV交易月度报告)
-- =============================================
-- declare @MatrixMemberId int = 4, @yyyyMM char(6) = '2019/8/5'
/*
	exec CrossJV_Summary 1, '2019/12/1'
	select * from CrossJVTemp_Summary

	exec CrossJV_Summary 4, '2019/12/1'
	select * from CrossJVTemp_Summary

	exec CrossJV_Summary 6, '2019/12/1'
	select * from CrossJVTemp_Summary
*/

CREATE procedure [dbo].[CrossJV_Summary]
(
	@MatrixMemberId int, 
	@BusinessDate   datetime
)
as
    begin
        set nocount on;
        if object_Id('dbo.CrossJVTemp_Summary', 'U') is not null
            drop table dbo.CrossJVTemp_Summary;

        declare @bal int= 50;
        declare @ParmDefinition nvarchar(max)= N'@MatrixMemberId int, @bal int';

        declare @sql nvarchar(max)= N'
        declare @MyJVName nvarchar(100);
        
		select @MyJVName = JVEN
        from CrossJVConfig
        where MatrixMemberId = @MatrixMemberId;

        select @MyJVName as MyJVName, 
               JVEN, 
               yyyyMM, 
               sum(w.RewardPoint) as RewardPoint, 
               sum(w.RedeemPoint) as RedeemPoint, 
               sum(w.RedeemAmt) as RedeemAmt, 
               sum(w.diff) as diff
		  into CrossJVTemp_Summary
        from
        (
            select jv.JVEN, 
                   convert(char(6), cp.CreatedAt, 112) as yyyyMM, 
                   sum(reward.RewardValue) as RewardPoint, 
                   0 as RedeemPoint, 
                   0 as RedeemAmt, 
                   0 as diff
            from #ATD#..FO_TranHeader#YYYYMM# as header
            join #ATD#..FO_TranCollection as collect on collect.CollectionInternalKey = header.CollectionInternalKey
            join report_data..RetailCode_MP as mp on mp.RetailerId = collect.RetailerId
            join report_data..store_gs store on store.storeid = collect.storeid and store.MatrixMemberId = mp.MatrixMemberId
            join #Loyalty#..CRM_POSTran as cp on cp.TranId = header.TranId
                                                       and cp.PosDateTime = collect.BusinessDate
                                                       and cp.StoreInternalKey = store.StoreInternalKey
                                                       and cp.MatrixMemberId = mp.MatrixMemberId
                                                       and cp.PosId = collect.TillId
            join
            (
                select distinct 
                       TicketInternalKey, 
                       PromotionId, 
                       RewardValue, 
                       entityid
                from #ATD#..FO_TranPromotionRewardApportionment#YYYYMM#
               where RewardMethodId = 1
                     and RewardId = 100
            ) reward on reward.TicketInternalKey = header.TicketInternalKey
            join #Loyalty#..CRM_Member as cm on cp.BuyingUnitInternalKey = cm.BuyingUnitInternalKey
            join report_data..v_get_reg_compAndStore as regStore on regStore.BuyingUnitInternalKey = cm.BuyingUnitInternalKey
            join CrossJVConfig as jv on jv.MatrixMemberId = store.MatrixMemberId
            where 1 = 1
                  and regStore.MatrixMemberId = @MatrixMemberId
                  and regStore.MatrixMemberId != store.MatrixMemberId
            group by jv.JVEN, convert(char(6), cp.CreatedAt, 112)

            union all

            select jv.JVEN, 
                   convert(char(6), cp.CreatedAt, 112), 
                   0, 
                   sum(case
                           when rewards.RewardValue = 0
                           then account.AdjustmentValue
                           else cast(reward.rewardValue / rewards.RewardValue * account.AdjustmentValue as decimal(10, 2))
                       end), --23.积分兑换数量
                   sum(cast(reward.rewardValue as decimal(10, 2))) as redemption, --24.积分抵扣金额
                   sum(-1 * case
                                when rewards.RewardValue = 0
                                then-1 * account.AdjustmentValue / @bal
                                else cast(reward.rewardValue - reward.rewardValue / rewards.RewardValue * account.AdjustmentValue / @bal as decimal(10, 2))
                            end) -- 25.差额'
			set @sql = @sql + '
            from #ATD#..FO_TranCollection as collect
            join #ATD#..FO_TranHeader#YYYYMM# as header on header.CollectionInternalKey = collect.CollectionInternalKey
            join report_data..RetailCode_MP as mp on mp.RetailerId = collect.RetailerId
            join report_data..store_gs as store on store.storeid = collect.storeid and store.MatrixMemberId = mp.MatrixMemberId
            join #Loyalty#..CRM_POSTran as cp on cp.TranId = header.TranId
                                                       and cp.PosDateTime = collect.BusinessDate
                                                       and cp.StoreInternalKey = store.StoreInternalKey
                                                       and cp.MatrixMemberId = mp.MatrixMemberId
                                                       and cp.PosId = collect.TillId
            join
			(
				select TicketInternalKey, 
					   PromotionId, 
					   sum(RewardValue) RewardValue
				from ATD_Shell..FO_TranPromotionRewardApportionment#YYYYMM#
				where RewardMethodId in(3, 4, 5)
				group by TicketInternalKey, 
						 PromotionId
			) as rewards on rewards.TicketInternalKey = header.TicketInternalKey
            join #ATD#..FO_TranPromotionRewardApportionment#YYYYMM# as reward on reward.TicketInternalKey = header.TicketInternalKey
                                                                                   and reward.PromotionId = rewards.PromotionId
                                                                                   and reward.RewardMethodId in(3, 4, 5)
            join #ATD#..FO_TranPromotionMemberAccount#YYYYMM# as account on account.TicketInternalKey = header.TicketInternalKey
            left join report_data..PromotionHeader_PR as pr on pr.PromotionHeaderId = reward.PromotionId and pr.MatrixMemberId = mp.MatrixMemberId
            left join report_data..item_cat as item on item.MainItemId = reward.EntityId and item.MatrixMemberId = mp.MatrixMemberId
                 join #Loyalty#..CRM_Member as cm on cp.BuyingUnitInternalKey = cm.BuyingUnitInternalKey
                 join report_data..v_get_reg_compAndStore as regStore on regStore.BuyingUnitInternalKey = cm.BuyingUnitInternalKey
                 join CrossJVConfig as jv on jv.MatrixMemberId = store.MatrixMemberId
            where 1 = 1
                  and regStore.MatrixMemberId = @MatrixMemberId
                  and cp.MatrixMemberId != regStore.MatrixMemberId
            group by jv.JVEN, convert(char(6), cp.CreatedAt, 112)

        ) as w
        group by JVEN, yyyyMM;
        ';

		declare @_sql nvarchar(max);
		exec ReplaceSQL @sql, @BusinessDate, @_sql output;

        execute sp_executesql 
                @_sql, 
                @ParmDefinition, 
                @MatrixMemberId = @MatrixMemberId, 
                @bal = @bal;
    end;
GO
