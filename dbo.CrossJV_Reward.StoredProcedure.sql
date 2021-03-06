USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[CrossJV_Reward]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Ryan Liang
-- Create date: 2019.8.1
-- Description:	Create Cross JV Reward (发放积分)
-- =============================================
-- TEST declare @MatrixMemberId int = 4, @BusinessDate datetime = '2019/8/5'
/*
	exec CrossJV_Reward 1, '2019/12/11', 0
	select * from CrossJVTemp

	exec CrossJV_Reward 4, '2019/12/10', 0
	select * from CrossJVTemp

	exec CrossJV_Reward 2, '2019/12/11', 0
	select * from CrossJVTemp
*/

CREATE procedure [dbo].[CrossJV_Reward]
(
	@MatrixMemberId int, 
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
               regStore.compid as compid, --2.注册公司代码
               regStore.comp as regcomp, --3.注册公司名称 
               regStore.storeid as storeid, --4.注册油站代码      
               regStore.storename as regstore, --5.注册油站名称 
               store.comp as sal_com, --6.交易公司代码 
               store.compid as sal_com_id, --7.交易公司名称 
               store.storeid as sal_storeid, --8.交易油站代码 
               store.storename as stor, --9.交易油站名称 
               store.city city, --10.城市 
               collect.CashierId, --11.收银员 
               header.TranId, --12.交易流水号 
               convert(varchar(10), collect.BusinessDate, 120) BusinessDate, --13.营业日 
               convert(varchar(10), header.StartDateTime, 120) trandate, --14.交易日期 
               convert(varchar(100), header.StartDateTime, 8) trantime, --15.交易时间, 
               collect.TillId, --16.POS ID
               item.firsttype, --17.商品类型 
               item.midtypeCode, --18.中类编号
               item.midtype, --19.商品中类 
               reward.EntityId, --20.SKU 
               item.FullName, --21.商品 
               reward.RewardValue as RewardvaluePoint, --22.积分发放 
               ROUND(reward.RewardValue / @bal, 2) as reward_amount, --23.积分发放金额 
               reward.PromotionId, --24.促销ID 
               pr.ExternalGroupId, --25.促销组 
               SUBSTRING(pr.ExternalReferenceID, 1, 8) as ExternalReferenceID, --26.外部促销id 
               convert(varchar, header.CreatedDate, 120) as CreatedDate    --27.上传日期
        into CrossJVTemp
        from #ATD#..FO_TranHeader#YYYYMM# (nolock) as header
             join #ATD#..FO_TranCollection (nolock) as collect on collect.CollectionInternalKey = header.CollectionInternalKey
             join report_data..RetailCode_MP (nolock) as mp on mp.RetailerId = collect.RetailerId
             join report_data..store_gs (nolock) as store on store.storeid = collect.storeid
                                                 and store.MatrixMemberId = mp.MatrixMemberId
             join #Loyalty#..CRM_POSTran (nolock) as cp on cp.TranId = header.TranId
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
			 	from #ATD#..FO_TranPromotionRewardApportionment#YYYYMM# (nolock)
			 	where RewardMethodId = 1
			 		  and RewardId = 100
			 ) reward on reward.TicketInternalKey = header.TicketInternalKey
             left join report_data..PromotionHeader_PR (nolock) as pr on pr.PromotionHeaderId = reward.PromotionId
                                                                and pr.MatrixMemberId = mp.MatrixMemberId
             left join report_data..item_cat (nolock) as item on item.MainItemId = reward.EntityId
                                                        and item.MatrixMemberId = mp.MatrixMemberId
             join #Loyalty#..CRM_Member (nolock) as cm on cp.BuyingUnitInternalKey = cm.BuyingUnitInternalKey
             join report_data..v_get_reg_compAndStore (nolock) as regStore on regStore.BuyingUnitInternalKey = cm.BuyingUnitInternalKey
        where cast(cp.CreatedAt as date) = @BusinessDate
              and pr.PromotionHeaderId is not null
              and case when @MyMember = 1 then regStore.MatrixMemberId else mp.MatrixMemberId end = @MatrixMemberId
              and regStore.MatrixMemberId != store.MatrixMemberId;
        ';

		declare @_sql nvarchar(max);
		exec ReplaceSQL @sql, @BusinessDate, @_sql output;

		select @_sql

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
