USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[pro_e2_single_redemption_sx]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*--================================================
--2019-11-25 
--2019-11-25 ADD  on trans DO'  STORE  document USE  document USE  插入优惠券兑换商品DO  
--20200804 cr312	对于DOCO站的单法律实体积分商城兑换优惠券使用
-	油品部分通过单法律实体积分接口上传ERP（与DO站接口逻辑相同）；
积分类型：J08，业务类型名称：优惠券兑换自有商品

-- =============================================
*/
CREATE  PROCEDURE [dbo].[pro_e2_single_redemption_sx]
   @createDate  varchar(10)
AS
BEGIN
	

	declare   @m_etl_date varchar(10) 
	,@MatrixMemberId int
  ,@RetailerId varchar(1);
  
set  @m_etl_date=convert(varchar(10),getdate(),120);
 	 select @MatrixMemberId=MatrixMemberId,@RetailerId=RetailerId
		  from  RetailCode_MP rcmp     where rcmp.RetailValue='2'   ;   ----sx RetailerId   is 2	
	

	 ---插入积分兑换商品
	  BEGIN  TRAN
	 delete      [e2_single_redemption]     where    Create_date=@createDate
	       and  fb_state in ('0','E')  and RetailerId=@RetailerId;
	--delete  from  [E1_single_leg_reward]  where  point_type='J0201' and etl_date=@m_etl_date;

   INSERT INTO [dbo].[e2_single_redemption]   
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
           , [redemption_point_je] --11 积分金额
                   ,
                   point_amount --11.2积分实际抵扣金额
                   ,
                   redem_ce --11.3积分抵扣差额
		    ,[point_service_type]             --12 积分业务类型 01
			,business_name
			,ID
			,fb_state
			,TaxCode   --19
			,RetailerId--20
			,StoreType --21
			,DoBusinessCode  --22
		    ,Create_date
		    )            
  select ''  --R2.member_reg_comp_code,     --1
 ,''  -- R2.member_reg_store_code,           --2
  ,'' --R2.member_reg_store,                --3
  ,r2.store_code,					  --4
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

   Sum(r2.redemption_point_je)                              point_je                        ,--11
             Sum(R2.redemption_point_amount)  point_amount  ,
             Sum(R2.redemption_point_amount - r2.redemption_point_je) AS redem_ce,

  'J0201',                                    --12积分业务类型
  N'积分兑换自有商品' ,
	'J0201'+r2.store_code+convert(varchar(8),convert(date,r2.create_date,120),12)+convert(varchar(8),convert(date,r2.business_date,120),12)+ case when   IC.firsttypeCode='10' then R2.item
	else R2.item_cat_mid end+r2.TaxCode  ID,
	'0'   fb_state 
	,r2.TaxCode   --19
			,r2.RetailerId--20
			,StoreType --21
			, DoBusinessCode  --22
			,Create_date
    from   ds_R2_redemption_point  r2
    left join item_cat  IC on R2.item=IC.MainItemid and ic.MatrixMemberId= @MatrixMemberId
	left join RetailCode_MP rmp on r2.RetailerId=rmp.RetailerId
	WHERE R2.store_code IS NOT NULL
	 and   'J0201'+r2.store_code+convert(varchar(8),convert(date,r2.create_date,120),12)+convert(varchar(8),convert(date,r2.business_date,120),12)+ case when   IC.firsttypeCode='10' then R2.item
	else R2.item_cat_mid  end+r2.TaxCode not in (select id from [e2_single_redemption] where fb_state<>'9' and Create_date =@createDate and RetailerId=@RetailerId)
	 and  convert(date,r2.create_date,120)=@createDate
	  and r2.member_reg_comp_code=r2.legal_code
	 and rmp.MatrixMemberId=@MatrixMemberId
	 and r2.store_code<>'9999'
   group by -- R2.member_reg_comp_code,     --1
 -- R2.member_reg_store_code,           --2
 -- R2.member_reg_store,                --3
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
	'J0201'+r2.store_code+convert(varchar(8),convert(date,r2.create_date,120),12)+convert(varchar(8),convert(date,r2.business_date,120),12)+ case when   IC.firsttypeCode='10' then R2.item
	else R2.item_cat_mid end+r2.TaxCode ,
	r2.TaxCode   --19
			,r2.RetailerId--20
			,StoreType --21
			,create_date
	 ,DoBusinessCode
	
	--------
	 INSERT INTO [dbo].[e2_single_redemption]   
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
           , [redemption_point_je] --11 积分金额
                   ,
                   point_amount --11.2积分实际抵扣金额
                   ,
                   redem_ce --11.3积分抵扣差额
		    ,[point_service_type]             --12 积分业务类型 01
			,business_name
			,ID
			,fb_state
			,TaxCode   --19
			,RetailerId--20
			,StoreType --21
			,DoBusinessCode  --22
		    ,Create_date
		    )            
  select   R2.member_reg_comp_code     --1  20190916modify   zyp
      ,    R2.member_reg_store_code           --2
      ,R2.member_reg_store                --3
      ,  R2.member_reg_store_code        --  ,r2.store_code,					  --4
      ,R2.member_reg_store  -- r2.store_name,					  --5
      ,  R2.member_reg_comp_code   --  r2.legal_code,						--6
      ,r2.member_reg_comp  --  r2.legal_name,							--7
      , R2.city,                             --4
  R2.business_date,                     --5
  convert(varchar(10),getdate(),120),  --6
  convert(varchar(12),getdate(),114) ,  --7
   'J05',   ---积分兑换优惠券            --8
    case when   IC.firsttypeCode='10' then R2.item
	else R2.item_cat_mid 
	end ,                               --9
	case when   ic.firsttypeCode='10' then r2.item_name
	else r2.item_cat_mid_name 	end ,                               --9.1
   sum(R2.redemption_point_q) point_num,       --10

   Sum(r2.redemption_point_je)                              point_je                        ,--11
             Sum(R2.redemption_point_amount)  point_amount  ,
             Sum(R2.redemption_point_amount - r2.redemption_point_je) AS redem_ce,

  'J0501',                                    --12积分业务类型
  N'积分兑换优惠券 ' ,
	'J05'+r2.RetailerId+ R2.member_reg_store_code+convert(varchar(8),convert(date,r2.create_date,120),12)+convert(varchar(8),convert(date,r2.business_date,120),12)+ case when   IC.firsttypeCode='10' then R2.item
	else R2.item_cat_mid end  +r2.TaxCode ID,
	'0'   fb_state 
	,r2.TaxCode   --19
			,r2.RetailerId--20
			,StoreType --21
			, DoBusinessCode  --22
			,Create_date
    from   ds_R2_redemption_point  r2
    left join item_cat  IC on R2.item=IC.MainItemid and ic.MatrixMemberId= @MatrixMemberId
	left join RetailCode_MP rmp on r2.RetailerId=rmp.RetailerId
	WHERE R2.store_code IS NOT NULL
	 and   'J05'+r2.RetailerId+ R2.member_reg_store_code+convert(varchar(8),convert(date,r2.create_date,120),12)+convert(varchar(8),convert(date,r2.business_date,120),12)+ case when   IC.firsttypeCode='10' then R2.item
	else R2.item_cat_mid  end+r2.TaxCode not in (select id from [e2_single_redemption] where fb_state<>'9' and Create_date =@createDate  and RetailerId=@RetailerId )
	
	 --  and r2.member_reg_comp_code=r2.legal_code  20190916 modify 
	 and rmp.MatrixMemberId=@MatrixMemberId
	 and r2.store_code='9999'   --积分兑换优惠券
   group by R2.member_reg_comp_code,     --1
 R2.member_reg_store_code,           --2
 R2.member_reg_store,                --3
  r2.member_reg_comp,  --  r2.legal_name,
  R2.city,                             --4
  R2.business_date,                     --5
   case when   IC.firsttypeCode='10' then R2.item
	else R2.item_cat_mid 
	end ,case when   ic.firsttypeCode='10' then r2.item
	else r2.item_cat_mid 	end,
	case when   ic.firsttypeCode='10' then r2.item_name
	else r2.item_cat_mid_name 	end,
	'J05'+r2.RetailerId+ R2.member_reg_store_code+convert(varchar(8),convert(date,r2.create_date,120),12)+convert(varchar(8),convert(date,r2.business_date,120),12)+ case when   IC.firsttypeCode='10' then R2.item
	else R2.item_cat_mid end+r2.TaxCode ,
	r2.TaxCode   --19
			,r2.RetailerId--20
			,StoreType --21
			,create_date		
			 ,DoBusinessCode

 
		
delete  from e2_single_redemption where fb_state='9' and  create_date =@createDate and RetailerId=@RetailerId; 	



 --插入优惠券兑换商品 2019-11-25
      INSERT INTO [dbo].[e2_single_redemption]
                  ([member_reg_comp_code] --1  注册公司代码
                   ,
                   [member_reg_store_code] --2   注册油站代码
                   ,
                   [member_reg_store] --3   注册油站名称
                   ,
                   store_code --4  交易油站代码
                   ,
                   store_name --5  交易油站名称
                   ,
                   legal_code --6  交易油站公司代码
                   ,
                   legal_name --7 交易油站公司名称
                   ,
                   [city] --4  城市名称
                   ,
                   [business_date] --5  营业日期
                   ,
                   [etl_date] --6  抽取日期
                   ,
                   [etl_time] --7  抽取时间
                   ,
                   [point_type] --8  积分类型
                   ,
                   [commodity_type] --9  商品类别
                   ,
                   commodity_name --9.1
                   ,
                   [point_number] --10 积分数量
                   ,
                   [point_amount] --11 积分金额
                   ,
                   redemption_point_je --11.2积分实际抵扣金额
                   ,
                   redem_ce --11.3积分抵扣差额
                   ,
                   [point_service_type] --12 积分业务类型 01
                   ,
                   business_name,
                   ID,
                   fb_state
				   ,TaxCode   --19
			   ,RetailerId--20
			,StoreType --21
			,DoBusinessCode  --22
		    ,Create_date)
      SELECT '' --R2.member_reg_comp_code,     --1
             ,
             '' -- R2.member_reg_store_code,           --2
             ,
             '' --R2.member_reg_store,                --3
             ,
             r2.sal_storeID,--4
             r2.sal_storeName,--5
             r2.sal_compid,--6
             r2.sal_comp,--7
             R2.city,--4
             R2.using_date,--5
             CONVERT(VARCHAR(10), Getdate(), 120),--6
             CONVERT(VARCHAR(12), Getdate(), 114),--7
             'J08',---积分兑换优惠券（期限）            --8
               R2.itemid,--9
               r2.itemname,--9.1
               Sum(R2.point)                    point_num,--10
             Sum(R2.pointJe)                  point_amount,--11
             Sum(r2.act_pointJe)              point_je,
            -1* Sum(r2.act_pointJe-R2.pointJe  ) AS redem_ce,
             'J0302',--优惠券业务类型
            
             N'优惠券兑换自有商品',
            'J0302' + r2.sal_storeID +convert(varchar(8),convert(date,r2.create_date,120),12)+convert(varchar(8),convert(date,r2.using_date,120),12)
             +  R2.itemid+r2.TaxCode  ID,
             '0'                              fb_state
			 ,TaxCode   --19
			,r2.RetailerId--20
			,StoreType --21
			, DoBusinessCode  --22
			,r2.create_date
      FROM   [dbo].[r41_document_use] r2
           left join RetailCode_MP rmp on r2.RetailerId=rmp.RetailerId
      WHERE  R2.sal_storeID IS NOT NULL
                   AND   'J0302' + r2.sal_storeID +convert(varchar(8),convert(date,r2.create_date,120),12)+convert(varchar(8),convert(date,r2.using_date,120),12)
             +  R2.itemid+r2.TaxCode 
                    NOT IN (SELECT id
                               FROM   [e2_single_redemption]
                               WHERE  fb_state <> '9'
                                      AND create_date = @createDate and RetailerId=@RetailerId)
             AND r2.create_date = @createDate
             AND r2.reg_compid = r2.sal_compid
			 and (StoreType='DO' )  
      GROUP  BY -- R2.member_reg_comp_code,     --1
      -- R2.member_reg_store_code,           --2
      -- R2.member_reg_store,                --3
      r2.sal_storeID,--4
      r2.sal_storeName,--5
      r2.sal_compid,--6
      r2.sal_comp,--7
      R2.city,--4
      R2.using_date,--5
     
        R2.itemid  ,--9
       r2.itemname        ,--9.1,
      'J0302' + r2.sal_storeID + r2.using_date
                 +   R2.itemid+r2.TaxCode
        ,r2.TaxCode   --19
			,r2.RetailerId--20
			,StoreType --21
			,Create_date  
			 ,TaxCode   --19
			,r2.RetailerId--20
			,StoreType --21
			,Create_date
			 ,DoBusinessCode
		;
/*
	 20200804  CR312对于DOCO站的单法律实体积分商城兑换优惠券使用
-	油品部分
     通过单法律实体积分接口上传ERP（与DO站接口逻辑相同）；
积分类型：J08，业务类型名称：优惠券兑换自有商品
*/
 INSERT INTO [dbo].[e2_single_redemption]
                  ([member_reg_comp_code] --1  注册公司代码
                   ,
                   [member_reg_store_code] --2   注册油站代码
                   ,
                   [member_reg_store] --3   注册油站名称
                   ,
                   store_code --4  交易油站代码
                   ,
                   store_name --5  交易油站名称
                   ,
                   legal_code --6  交易油站公司代码
                   ,
                   legal_name --7 交易油站公司名称
                   ,
                   [city] --4  城市名称
                   ,
                   [business_date] --5  营业日期
                   ,
                   [etl_date] --6  抽取日期
                   ,
                   [etl_time] --7  抽取时间
                   ,
                   [point_type] --8  积分类型
                   ,
                   [commodity_type] --9  商品类别
                   ,
                   commodity_name --9.1
                   ,
                   [point_number] --10 积分数量
                   ,
                   [point_amount] --11 积分金额
                   ,
                   redemption_point_je --11.2积分实际抵扣金额
                   ,
                   redem_ce --11.3积分抵扣差额
                   ,
                   [point_service_type] --12 积分业务类型 01
                   ,
                   business_name,
                   ID,
                   fb_state
				   ,TaxCode   --19
			      ,RetailerId--20
			      ,StoreType --21
			      ,DoBusinessCode  --22
		          ,Create_date)
      SELECT '' --R2.member_reg_comp_code,     --1
             ,
             '' -- R2.member_reg_store_code,           --2
             ,
             '' --R2.member_reg_store,                --3
             ,
             r2.sal_storeID,--4
             r2.sal_storeName,--5
             r2.sal_compid,--6
             r2.sal_comp,--7
             R2.city,--4
             R2.using_date,--5
             CONVERT(VARCHAR(10), Getdate(), 120),--6
             CONVERT(VARCHAR(12), Getdate(), 114),--7
             'J08',---积分兑换优惠券（期限）            --8
               R2.itemid,--9
               r2.itemname,--9.1
               Sum(R2.point)                    point_num,--10
             Sum(R2.pointJe)                  point_amount,--11
             Sum(r2.act_pointJe)              point_je,
            -1* Sum(r2.act_pointJe-R2.pointJe  ) AS redem_ce,
             'J0302',--优惠券业务类型
            
             N'DOCO优惠券兑换自有商品',
            'J0302' + r2.sal_storeID +convert(varchar(8),convert(date,r2.create_date,120),12)+convert(varchar(8),convert(date,r2.using_date,120),12)
             +  R2.itemid+r2.TaxCode  ID,
             '0'                              fb_state
			 ,R2.TaxCode   --19
			,r2.RetailerId--20
			,StoreType --21
			,DoBusinessCode  --22
			,r2.create_date
      FROM   [dbo].[r41_document_use] r2
           left join RetailCode_MP rmp on r2.RetailerId=rmp.RetailerId
		    left join item_cat  IC on R2.itemid=IC.MainItemid and ic.MatrixMemberId= @MatrixMemberId
      WHERE  R2.sal_storeID IS NOT NULL
                   AND   'J0302' + r2.sal_storeID +convert(varchar(8),convert(date,r2.create_date,120),12)+convert(varchar(8),convert(date,r2.using_date,120),12)
             +  R2.itemid+r2.TaxCode 
                    NOT IN (SELECT id
                               FROM   [e2_single_redemption]
                               WHERE  fb_state <> '9'
                                      AND create_date = @createDate and RetailerId=@RetailerId)
             AND r2.create_date = @createDate
             AND r2.reg_compid = r2.sal_compid
			 and (StoreType='DOCO' ) 
			 AND  ic.firsttypeCode='10'  --  油品部分     通过单法律实体积分接口上传ERP（与DO站接口逻辑相同）；
      GROUP  BY -- R2.member_reg_comp_code,     --1
      -- R2.member_reg_store_code,           --2
      -- R2.member_reg_store,                --3
      r2.sal_storeID,--4
      r2.sal_storeName,--5
      r2.sal_compid,--6
      r2.sal_comp,--7
      R2.city,--4
      R2.using_date,--5
     
        R2.itemid  ,--9
       r2.itemname        ,--9.1,
      'J0302' + r2.sal_storeID + r2.using_date
                 +   R2.itemid+r2.TaxCode
        ,r2.TaxCode   --19
			,r2.RetailerId--20
			,StoreType --21
			,Create_date  
			,r2.RetailerId--20
			,StoreType --21
			,Create_date
			 ,DoBusinessCode
		;

delete  from e2_single_redemption where fb_state='9' and  create_date =@createDate and RetailerId=@RetailerId; 	


	--Reconciliation
	delete report_data..ReconciliationR2ERP 
	where RetailerId = @RetailerId 
	and DataType in ('E2')
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
	select @RetailerId,'E2',e.Create_date,e.business_date,sum(e.point_number),e.StoreType
	from e2_single_redemption e
	--left join [report_data].[dbo].store_gs store on e.store_code = store.storeid
	where e.RetailerId = @RetailerId 
	and e.Create_date = @createDate
	group by e.Create_date,e.business_date,e.StoreType
	


COMMIT  TRAN;

END


GO
