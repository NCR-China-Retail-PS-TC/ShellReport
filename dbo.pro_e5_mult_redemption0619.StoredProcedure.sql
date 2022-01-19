USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[pro_e5_mult_redemption0619]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[pro_e5_mult_redemption0619]
   @business_date  varchar(10)
AS
BEGIN
	

	declare   @m_etl_date varchar(10);
set  @m_etl_date=convert(varchar(10),getdate(),120);
	


	 ---插入积分兑换商品
	 	update      [e5_mult_redemption]  set fb_state='9'
	   where    [business_date]=@business_date
	       and  fb_state in ('0','E');
	--delete  from  [E1_single_leg_reward]  where  point_type='J0201' and etl_date=@m_etl_date;

   INSERT INTO [dbo].[e5_mult_redemption]   
           ([member_reg_comp_code]			--1  注册公司代码
           ,[member_reg_store_code]         --2   注册油站代码
           ,[member_reg_store]              --3   注册油站名称
		   ,store_code						--4  交易油站代码
		   ,store_name						--5  交易油站名称
		   ,legal_code						--6  交易油站公司代码
		   ,legal_name						--7 交易油站公司名称
           ,[city]                          --4  城市名称
           ,[business_date]                 --5  营业日期
           ,[etl_date]                      --6  抽取日期
           ,[etl_time]                      --7  抽取时间
           ,[point_type]					--8  积分类型
           ,[commodity_type]                --9  商品类别
		   ,commodity_name                 --9.1
           ,[point_number]                  --10 积分数量
           ,[point_amount]                  --11 积分金额
		    ,[point_service_type]             --12 积分业务类型 01
			,business_name
			,ID
			,fb_state
		    )            
  select R2.member_reg_comp_code,     --1
  R2.member_reg_store_code,           --2
  R2.member_reg_store,                --3
  r2.store_code,					  --4
  r2.store_name,					  --5
  r2.legal_code,						--6
  r2.legal_name,							--7
  R2.city,                             --4
  R2.business_date,                     --5
  convert(varchar(10),getdate(),120),  --6
  convert(varchar(12),getdate(),114) ,  --7
   'J04',   ---积分兑换优惠券（立减）            --8
    case when   IC.firsttypeCode='10' then R2.item
	else R2.item_cat_mid 
	end ,                               --9
	case when   ic.firsttypeCode='10' then r2.item_name
	else r2.item_cat_mid_name 	end ,                               --9.1
   sum(R2.redemption_point_q) point_num,       --10
   sum(R2.redemption_point_amount) point_amount,     --11
  'J0201',                                    --12积分业务类型
   N'积分兑换自有商品',
	'J0201'+r2.store_code+ R2.member_reg_store_code+r2.business_date+ case when   IC.firsttypeCode='10' then R2.item
	else R2.item_cat_mid end  ID,
	'0'   fb_state 
    from   ds_R2_redemption_point  r2
    left join item_cat  IC on R2.item=IC.MainItemid   and MatrixMemberId=1
	WHERE R2.store_code IS NOT NULL and not  ( (r2.member_reg_comp_code=r2.legal_code
	 and r2.store_code not in ('4070','4071','4072','4073','4074','4075','4076')
	   and   r2.member_reg_store_code not in ('4070','4071','4072','4073','4074','4075','4076')
	   ) or  ( r2.store_code  in ('4070','4071','4072','4073','4074','4075','4076')
	  and r2.member_reg_store_code  in ('4070','4071','4072','4073','4074','4075','4076'))
	 ) 
	 and   'J0201'+r2.store_code+ R2.member_reg_store_code+r2.business_date+ case when   IC.firsttypeCode='10' then R2.item
	else R2.item_cat_mid  end not in (select id from [e5_mult_redemption] where fb_state<>'9' and business_date =@business_date)
	 and  r2.business_date=@business_date
   group by R2.member_reg_comp_code,     --1
  R2.member_reg_store_code,           --2
  R2.member_reg_store,                --3
  r2.store_code,					  --4
  r2.store_name,					  --5
  r2.legal_code,						--6
  r2.legal_name,							--7
  R2.city,                             --4
  R2.business_date,                     --5
   case when   IC.firsttypeCode='10' then R2.item
	else R2.item_cat_mid 
	end ,case when   ic.firsttypeCode='10' then r2.item
	else r2.item_cat_mid 	end,
	case when   ic.firsttypeCode='10' then r2.item_name
	else r2.item_cat_mid_name 	end,
	'J0201'+r2.store_code+ R2.member_reg_store_code+r2.business_date+ case when   IC.firsttypeCode='10' then R2.item
	else R2.item_cat_mid end  ;

delete  from e5_mult_redemption where fb_state='9' and business_date =@business_date; 	



END


GO
