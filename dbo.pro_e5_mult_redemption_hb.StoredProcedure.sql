USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[pro_e5_mult_redemption_hb]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
--2020-06-19 add DO 积分兑换直接抵扣--积分兑换商品（直接抵扣）场景增加兑换分摊比例计算
--20200619 插入优惠券兑换商品DO  CRD295 增加DO站分摊
-- =============================================
CREATE  PROCEDURE [dbo].[pro_e5_mult_redemption_hb]
  @createDate  varchar(10)
AS
BEGIN
	

	declare   @m_etl_date varchar(10)
	,@MatrixMemberId int
	,@RetailerId varchar(1)  ;
     set @MatrixMemberId=1;;
     set  @m_etl_date=convert(varchar(10),getdate(),120);
	
      select @RetailerId= r.RetailerId  from  RetailCode_MP R where r.MatrixMemberId=@MatrixMemberId;


	 ---插入积分兑换商品
	 delete   [e5_mult_redemption] 
	   where    [create_date]=@createDate
	       and  fb_state in ('0','E')  and RetailerId=@RetailerId;

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
			 ,TaxCode   --19
			,RetailerId--20
			,StoreType --21
			,DoBusinessCode  --22
			,Create_Date
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
   'J03',   ---积分兑换自有商品（立减）            --8
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
	'J0201'+r2.store_code+ R2.member_reg_store_code+convert(varchar(8),convert(date,r2.create_date,120),112)+convert(varchar(8),convert(date,r2.business_date,120),112)+ case when   IC.firsttypeCode='10' then R2.item
	else R2.item_cat_mid end+r2.taxCode  ID,
	'0'   fb_state  
	        ,r2.TaxCode   --19
			,r2.RetailerId--20
			,StoreType --21
			, DoBusinessCode  --22
			,Create_Date
    from   ds_R2_redemption_point  r2
    left join item_cat  IC on R2.item=IC.MainItemid   and MatrixMemberId=1
	WHERE   (r2.storeType is null or r2.storeType='COCO') and 
	R2.store_code IS NOT NULL and not  ( (r2.member_reg_comp_code=r2.legal_code
	 and r2.store_code not in ('4070','4071','4072','4073','4074','4075','4076')
	   and   r2.member_reg_store_code not in ('4070','4071','4072','4073','4074','4075','4076')
	   ) or  ( r2.store_code  in ('4070','4071','4072','4073','4074','4075','4076')
	  and r2.member_reg_store_code  in ('4070','4071','4072','4073','4074','4075','4076'))
	 ) 
	 and   'J0201'+r2.store_code+ R2.member_reg_store_code+convert(varchar(8),convert(date,r2.create_date,120),112)+convert(varchar(8),convert(date,r2.business_date,120),112)+ case when   IC.firsttypeCode='10' then R2.item
	else R2.item_cat_mid end+r2.taxCode not in (select id from [e5_mult_redemption] where fb_state<>'9' and   create_date =@createDate  and RetailerId=@RetailerId)
	
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
	else R2.item_cat_mid end 
	,r2.TaxCode   --19
			,r2.RetailerId--20
			,StoreType --21
			,Create_Date
			,r2.taxCode
			,DoBusinessCode
			 ;



 
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
			 ,TaxCode   --19
			,RetailerId--20
			,StoreType --21
			,DoBusinessCode  --22
			,Create_Date
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
	'J0302'+ R2.reg_compid+reg_storeid+r2.sal_storeID+convert(varchar(8),convert(date,r2.using_date,120),112)+ R2.itemid+r2.TaxCode,
	'0'   fb_state 
	,TaxCode   --19
			,r2.RetailerId--20
			,StoreType --21
			,DoBusinessCode  --22
			,Create_Date
    from   [dbo].[r41_document_use] r2
   left join RetailCode_MP rmp on r2.RetailerId=rmp.RetailerId
	WHERE    (r2.storeType is null or r2.storeType='COCO') and
	 R2.sal_storeID IS NOT NULL and not  ( (r2.reg_compid=r2.sal_compid
	 and r2.sal_storeID not in ('4070','4071','4072','4073','4074','4075','4076')
	   and   r2.reg_storeid not in ('4070','4071','4072','4073','4074','4075','4076')) or  ( r2.sal_storeID  in ('4070','4071','4072','4073','4074','4075','4076')
	  and r2.reg_storeid  in ('4070','4071','4072','4073','4074','4075','4076'))
	 )

	and  'J0302'+ R2.reg_compid+reg_storeid+r2.sal_storeID+convert(varchar(8),convert(date,r2.using_date,120),112)+ R2.itemid+r2.TaxCode
	  not in (select id from e5_mult_redemption where fb_state<>'9' and Create_Date =@createDate  and RetailerId=@RetailerId)
	-- and  r2.using_date=@createDate 
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
 	'J0302'+ R2.reg_compid+r2.sal_storeID+r2.using_date+   R2.itemid  
	,TaxCode   --19
			,r2.RetailerId--20
			,StoreType --21
			,Create_Date
			,DoBusinessCode;

-----------------------------------
----2020-06-19 add DO 积分兑换直接抵扣--积分兑换商品（直接抵扣）场景增加兑换分摊比例计算
----------------------------------
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
			 ,TaxCode   --19
			,RetailerId--20
			,StoreType --21
			,DoBusinessCode  --22
			,Create_Date
				 ,[RegSharePoint]	 --24
            ,[RegShareAmount]	 --25
		    ,[RegRedeemAmount]	 --26
            ,[TransSharePoint]	 --27
            ,[TransShareAmount]	 --28
            ,[TransRedeemAmount] --29
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
   'J03',   ---DO积分兑换优惠券（立减）            --8
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
   N'DO积分兑换自有商品',
	'J0201'+r2.store_code+ R2.member_reg_store_code+convert(varchar(8),convert(date,r2.create_date,120),112)+convert(varchar(8),convert(date,r2.business_date,120),112)+ case when   IC.firsttypeCode='10' then R2.item
	else R2.item_cat_mid end+r2.taxCode  ID,
	'0'   fb_state  
	        ,r2.TaxCode   --19
			,r2.RetailerId--20
			,StoreType --21
			, DoBusinessCode  --22
			,Create_Date
			 ,sum([RegSharePoint])	 --24
            ,sum([RegShareAmount])	 --25
		    ,sum([RegRedeemAmount])	 --26
            ,sum([TransSharePoint])	 --27
            ,sum([TransShareAmount])	 --28
            ,sum([TransRedeemAmount]) --29
    from   ds_R2_redemption_point  r2
    left join item_cat  IC on R2.item=IC.MainItemid   and MatrixMemberId=1
	WHERE     ( r2.storeType='DO') and
	R2.store_code IS NOT NULL and not  ( (r2.member_reg_comp_code=r2.legal_code
	 and r2.store_code not in ('4070','4071','4072','4073','4074','4075','4076')
	   and   r2.member_reg_store_code not in ('4070','4071','4072','4073','4074','4075','4076')
	   ) or  ( r2.store_code  in ('4070','4071','4072','4073','4074','4075','4076')
	  and r2.member_reg_store_code  in ('4070','4071','4072','4073','4074','4075','4076'))
	 ) 
	 and   'J0201'+r2.store_code+ R2.member_reg_store_code+convert(varchar(8),convert(date,r2.create_date,120),112)+convert(varchar(8),convert(date,r2.business_date,120),112)+ case when   IC.firsttypeCode='10' then R2.item
	else R2.item_cat_mid end+r2.taxCode not in (select id from [e5_mult_redemption] where fb_state<>'9' and   create_date =@createDate  and RetailerId=@RetailerId)
	
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
	else R2.item_cat_mid end 
	,r2.TaxCode   --19
			,r2.RetailerId--20
			,StoreType --21
			,Create_Date
			,r2.taxCode
			,DoBusinessCode ;

-----------------
 -------------------------------
--20200619 插入优惠券兑换商品DO  CRD295 增加DO站分摊
-------------------------------------
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
			 ,TaxCode   --19
			,RetailerId--20
			,StoreType --21
			,DoBusinessCode  --22
			,Create_Date
			 ,[RegSharePoint]	 --24
            ,[RegShareAmount]	 --25
		    ,[RegRedeemAmount]	 --26
            ,[TransSharePoint]	 --27
            ,[TransShareAmount]	 --28
            ,[TransRedeemAmount] --29
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
   'J08',   ---DO优惠券兑换商品            --8
    R2.itemid,--9
               r2.itemname,--9.1,                               --9.1
   Sum(R2.point)                    point_num,--10
             Sum(R2.pointJe)                  point_amount,--11
             Sum(r2.act_pointJe)              point_je,
            -1* Sum(r2.act_pointJe-R2.pointJe  ) AS redem_ce,
  'J0302',                                    --优惠券业务类型
  N'DO优惠券兑换商品' ,
	'J0302'+ R2.reg_compid+reg_storeid+r2.sal_storeID+convert(varchar(8),convert(date,r2.using_date,120),112)+ R2.itemid+r2.TaxCode,
	'0'   fb_state 
	,TaxCode   --19
			,r2.RetailerId--20
			,StoreType --21
			,DoBusinessCode  --22
			,Create_Date
			   ,sum([RegSharePoint])	 --24
            ,sum([RegShareAmount])	 --25
		    ,sum([RegRedeemAmount])	 --26
            ,sum([TransSharePoint])	 --27
            ,sum([TransShareAmount])	 --28
            ,sum([TransRedeemAmount]) --29
    from   [dbo].[r41_document_use] r2
   left join RetailCode_MP rmp on r2.RetailerId=rmp.RetailerId
	WHERE      ( r2.storeType='DO') and
	 R2.sal_storeID IS NOT NULL and not  ( (r2.reg_compid=r2.sal_compid
	 and r2.sal_storeID not in ('4070','4071','4072','4073','4074','4075','4076')
	   and   r2.reg_storeid not in ('4070','4071','4072','4073','4074','4075','4076')) or  ( r2.sal_storeID  in ('4070','4071','4072','4073','4074','4075','4076')
	  and r2.reg_storeid  in ('4070','4071','4072','4073','4074','4075','4076'))
	 )

	and  'J0302'+ R2.reg_compid+reg_storeid+r2.sal_storeID+convert(varchar(8),convert(date,r2.using_date,120),112)+ R2.itemid+r2.TaxCode
	  not in (select id from e5_mult_redemption where fb_state<>'9' and Create_Date =@createDate  and RetailerId=@RetailerId)
	-- and  r2.using_date=@createDate 
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
 	'J0302'+ R2.reg_compid+r2.sal_storeID+r2.using_date+   R2.itemid  
	,TaxCode   --19
			,r2.RetailerId--20
			,StoreType --21
			,Create_Date
			,DoBusinessCode;

	------------------------

delete  from e5_mult_redemption where fb_state='9' and  Create_Date =@createDate and RetailerId=@RetailerId;

	--Reconciliation
	delete report_data..ReconciliationR2ERP 
	where RetailerId = @RetailerId 
	and DataType in ('E5')
	and CreatedAt = @CreateDate;


	insert into report_data..ReconciliationR2ERP
	(	
		RetailerId,
		DataType,
		CreatedAt,
		BusinessDate,
		Point,
		StoreType
	)
	select @RetailerId,'E5',e.Create_date,e.business_date,sum(e.point_number),e.StoreType
	from e5_mult_redemption e
	--left join [report_data].[dbo].store_gs store on e.store_code = store.storeid
	where e.RetailerId = @RetailerId 
	and e.Create_date = @createDate
	group by e.Create_date,e.business_date,e.StoreType


END





GO
