USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[CrossJV_Redeem]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Ryan Liang
-- Create date: 2019.8.1
-- Description:	Create Cross JV Redeem (兑换积分)
-- =============================================
-- declare @MatrixMemberId int = 4, @BusinessDate datetime = '2019/8/5'
/*
	exec CrossJV_Redeem 4, '2019/12/9', 0
	select * from CrossJVTemp
*/
CREATE procedure [dbo].[CrossJV_Redeem]
(	@MatrixMemberId int, 
	@BusinessDate   datetime,
	@MyMember bit	--1:本JV会员在外JV, 0:外JV会员在本JV
)
as
    begin
        set nocount on;
        if object_Id('dbo.CrossJVTemp', 'U') is not null
            drop table dbo.CrossJVTemp;

        declare @bal int= 50;
        declare @yyyyMM varchar(6);
        select @yyyyMM = left(convert(varchar, @BusinessDate, 112), 6);

        declare @ParmDefinition nvarchar(max)= N'@MatrixMemberId int, @BusinessDate datetime, @bal int, @MyMember bit';
        declare @sql nvarchar(max) = N'
        select cp.ClubCardId, --1.会员号码
               regStore.compid as compid, --2.会员注册公司
               regStore.comp as regcomp, --3.注册公司名称 
               regStore.storeid as storeid, --4.注册油站代码      
               regStore.storename as regstore, --5.会员注册油站 
               store.comp as sal_com, --6.公司代码 
               store.compid as sal_com_id, --7.交易公司名称 
               store.storeid as sal_storeid, --8.油站代码 
               store.storename as stor, -- 9.油站名称 
               store.city as city, --10.城市
               collect.CashierId, --11.收银员
               header.TranId, --12.交易流水号
               convert(varchar(10), collect.BusinessDate, 120) as businessDate, --13.营业日
               convert(varchar(10), collect.createddate, 120) as trandate, --14.交易日期
               convert(varchar(8), collect.createddate, 8) as trantime, --15.交易时间
               collect.TillId as posid, --16.posid
               item.firsttype, --17.商品类型
               item.midtypeCode, --18.商品中类
               item.midtype, --19.中类名称
               item.mainitemid, --20.SKU
               item.FullName, -- 21.商品  
               reward.RewardedQty, --22.数量
               case
                   when rewards.RewardValue = 0
                   then account.AdjustmentValue
                   else cast(reward.rewardValue / rewards.RewardValue * account.AdjustmentValue as decimal(10, 2))
               end as Redemption_quantity, --23.积分兑换数量 
               --case
               --    when rewards.RewardValue = 0
               --    then account.AdjustmentValue / @bal
               --    else cast(reward.rewardValue / rewards.RewardValue * account.AdjustmentValue / @bal as decimal(10, 2))
               --end as redemption_point_je, --积分折算金额
               cast(reward.rewardValue as decimal(10, 2)) as redemption, --24.积分抵扣金额 
               -1 * case
                        when rewards.RewardValue = 0
                        then-1 * account.AdjustmentValue / @bal
                        else cast(reward.rewardValue - reward.rewardValue / rewards.RewardValue * account.AdjustmentValue / @bal as decimal(10, 2))
                    end as redem_ce, -- 25.差额
               reward.PromotionId, --26.促销ID
               pr.ExternalGroupId, --27.促销组 
               pr.ExternalReferenceID, --29.外部促销id 
               convert(varchar, cp.CreatedAt, 120) as CreatedDate --30.上传日期
			   into CrossJVTemp
        from #ATD#..FO_TranCollection as collect
             join #ATD#..FO_TranHeader#YYYYMM# as header on header.CollectionInternalKey = collect.CollectionInternalKey
             join report_data..RetailCode_MP as mp on mp.RetailerId = collect.RetailerId
             join report_data..store_gs as store on store.storeid = collect.storeid
                                                    and store.MatrixMemberId = mp.MatrixMemberId
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
            from #ATD#..FO_TranPromotionRewardApportionment#YYYYMM#
            where RewardMethodId in(3, 4, 5)
            group by TicketInternalKey, 
                     PromotionId
        ) as rewards on rewards.TicketInternalKey = header.TicketInternalKey'
		set @sql = @sql + N'
             join #ATD#..FO_TranPromotionRewardApportionment#YYYYMM# as reward on reward.TicketInternalKey = header.TicketInternalKey
                                                                                    and reward.PromotionId = rewards.PromotionId
                                                                                    and reward.RewardMethodId in(3, 4, 5)
             join #ATD#..FO_TranPromotionMemberAccount#YYYYMM# as account on account.TicketInternalKey = header.TicketInternalKey
             left join report_data..PromotionHeader_PR as pr on pr.PromotionHeaderId = reward.PromotionId
                                                                and pr.MatrixMemberId = mp.MatrixMemberId
             left join report_data..item_cat as item on item.MainItemId = reward.EntityId
                                                        and item.MatrixMemberId = mp.MatrixMemberId
             join #Loyalty#..CRM_Member as cm on cp.BuyingUnitInternalKey = cm.BuyingUnitInternalKey
             join report_data..v_get_reg_compAndStore as regStore on regStore.BuyingUnitInternalKey = cm.BuyingUnitInternalKey
        where cast(cp.CreatedAt as date) = @businessDate
              and case when @MyMember = 1 then regStore.MatrixMemberId else mp.MatrixMemberId end = @MatrixMemberId
              and cp.MatrixMemberId != regStore.MatrixMemberId
        order by cp.CreatedAt;
		';

		declare @_sql nvarchar(max);
		exec ReplaceSQL @sql, @BusinessDate, @_sql output;

        execute sp_executesql 
                @_sql, 
                @ParmDefinition, 
                @BusinessDate = @BusinessDate, 
                @MatrixMemberId = @MatrixMemberId, 
                @bal = @bal,
				@MyMember = @MyMember;

		update CrossJVTemp set ClubCardId = ''''+ ClubCardId;
    end;

GO
