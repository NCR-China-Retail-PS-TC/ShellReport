USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[pro_e5_mult_redemption]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE   PROCEDURE [dbo].[pro_e5_mult_redemption]
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
           ,[redemption_point_je]                  --11 积分金额
		     ,point_amount              --11.2积分实际抵扣金额
		    ,redem_ce                         --11.3积分抵扣差额
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
   'J03',   ---积分兑换优惠券（立减）            --8
    case when   IC.firsttypeCode='10' then R2.item
	else R2.item_cat_mid 
	end ,                               --9
	case when   ic.firsttypeCode='10' then r2.item_name
	else r2.item_cat_mid_name 	end ,                               --9.1
   sum(R2.redemption_point_q) point_num,       --10
  sum(r2.redemption_point_je)  point_je ,     --11
  sum(R2.redemption_point_amount) point_amount  ,
   sum(R2.redemption_point_amount-r2.redemption_point_je) as redem_ce, 
  'J0201',                                    --12积分业务类型
   N'积分兑换自有商品',
	'J0201'+R2.member_reg_comp_code+r2.store_code+ R2.member_reg_store_code+r2.business_date+ case when   IC.firsttypeCode='10' then R2.item
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
	 and   'J0201'+R2.member_reg_comp_code+r2.store_code+ R2.member_reg_store_code+r2.business_date+ case when   IC.firsttypeCode='10' then R2.item
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




--插入优惠券兑换商品
	 INSERT INTO  [dbo].[e5_mult_redemption]     
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
		   ,redemption_point_je              --11.2积分实际抵扣金额
		    ,redem_ce                         --11.3积分抵扣差额
		    ,[point_service_type]             --12 积分业务类型 01
			,business_name
			,ID
			,fb_state
		    )            
  select   R2.reg_compid,            --1
   r2.reg_storeid,                 --2
   r2.reg_storeName,                --3
  r2.sal_storeID,					  --4
  r2.sal_storeName,					  --5
  r2.sal_compid,						--6
  r2.sal_comp,							--7
  R2.city,                             --4
  R2.using_date,                     --5
  convert(varchar(10),getdate(),120),  --6
  convert(varchar(12),getdate(),114) ,  --7
   'J08',   ---积分兑换优惠券(期限)            --8
    R2.itemid,--9
               r2.itemname,--9.1,                               --9.1
   Sum(R2.point)                    point_num,--10
             Sum(R2.pointJe)                  point_amount,--11
             Sum(r2.act_pointJe)              point_je,
            -1* Sum(r2.act_pointJe-R2.pointJe  ) AS redem_ce,
  'J0302',                                    --优惠券业务类型
  N'优惠券兑换商品' ,
	'J0302'+ R2.reg_compid+reg_storeid+r2.sal_storeID+r2.using_date+ R2.itemid,
	'0'   fb_state 
    from   [dbo].[r41_document_use] r2
   -- left join item_cat  IC on R2.itemid=IC.MainItemid and ic.MatrixMemberId=1
	WHERE R2.sal_storeID IS NOT NULL and not  ( (r2.reg_compid=r2.sal_compid
	 and r2.sal_storeID not in ('4070','4071','4072','4073','4074','4075','4076')
	   and   r2.reg_storeid not in ('4070','4071','4072','4073','4074','4075','4076')) or  ( r2.sal_storeID  in ('4070','4071','4072','4073','4074','4075','4076')
	  and r2.reg_storeid  in ('4070','4071','4072','4073','4074','4075','4076'))
	 )

	 and 'J0302'+ R2.reg_compid+reg_storeid+r2.sal_storeID+r2.using_date+ R2.itemid
	  not in (select id from e5_mult_redemption where fb_state<>'9' and business_date =@business_date)
	 and  r2.using_date=@business_date 
   group by  R2.reg_compid,            --1
   r2.reg_storeid,                 --2
   r2.reg_storeName,                --3
  r2.sal_storeID,					  --4
  r2.sal_storeName,					  --5
  r2.sal_compid,						--6
  r2.sal_comp,							--7
  R2.city,                             --4
  R2.using_date,                     --5
  
    R2.itemid,--9
               r2.itemname,--9.1,                               --9.1
 	'J0302'+ R2.reg_compid+r2.sal_storeID+r2.using_date+   R2.itemid   ;

delete  from e5_mult_redemption where fb_state='9' and business_date =@business_date; 	



END


GO
