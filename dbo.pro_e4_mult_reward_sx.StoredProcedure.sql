USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[pro_e4_mult_reward_sx]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
CREATE PROCEDURE  [dbo].[pro_e4_mult_reward_sx]
	 @createDate varchar(10)    --营业日期
AS
BEGIN
declare   @m_etl_date varchar(10)
 ,@MatrixMemberId int
 ,@RetailerId varchar(1)='2' ; ;
  
 
   select @MatrixMemberId=MatrixMemberId from  RetailCode_MP rcmp  	 
	   where rcmp.RetailerId=@RetailerId   ;   ----sx RetailerId   is 2
set  @m_etl_date=convert(varchar(10),getdate(),120);
--set  @business_date=@m_etl_date	
	update      [e4_mult_reward]  set fb_state='9'
	   where     Create_date=@createDate
	       and  fb_state in ('0','E') and RetailerId=@RetailerId;
		  ;

 update r1 set r1.id='J0101'+r1.store_code+r1.member_reg_store_code+convert(varchar(8),convert(date,r1.create_date,120),12)+convert(varchar(8),convert(date,r1.business_date,120),12)+ case when   IC.firsttypeCode='10' then R1.item_code
	else R1.item_cat_mid_code 
	end+r1.TaxCode
			    FROM   ds_R1_2_tran_reward r1
             LEFT JOIN item_cat ic
                    ON r1.item_code = ic.MainItemid
                       AND MatrixMemberId = @MatrixMemberId
             LEFT JOIN RetailCode_MP rmp
                    ON r1.RetailerId = rmp.RetailerId
				where 	rmp.MatrixMemberId = @MatrixMemberId
	      and (r1.member_reg_comp_code<>r1.legal_code
	 	 )
 ---插入多法律实体交易积分
   INSERT INTO [dbo].[e4_mult_reward]   
           ([member_reg_comp_code]			--1  注册公司代码
           ,[member_reg_store_code]         --2   注册油站代码
           ,[member_reg_store]              --3   注册油站名称
		   ,store_code						--4  交易油站代码
		   ,store_name						--5  交易油站名称
		   ,legal_code						--6  交易油站公司代码
		   ,legal_name						--7 交易油站公司名称
           ,[city]                          --8  城市名称
           ,[business_date]                 --9  营业日期
           ,[etl_date]                      --10  抽取日期
           ,[etl_time]                      --11  抽取时间
           ,[point_type]					--12  积分类型
           ,[commodity_type]                --13  商品类别
		   ,commodity_name                  --13.1
           ,[point_number]                  --14 积分数量
           ,[point_amount]                  --15  积分金额
		    ,point_service_type             -- 16 积分业务类型 01
			,business_name  
		    ,id								--17 标识号
			,fb_state                       --18 传输状态 0 未传输, 1 成功 2 失败 
			 ,TaxCode   --19
			,RetailerId--20
			,StoreType --21
			,DoBusinessCode  --22
			,Create_date
			)            
  select r1.member_reg_comp_code,     --1
  r1.member_reg_store_code,           --2
  r1.member_reg_store,                --3
   r1.store_code,					  --4
  r1.store_name,					  --5
  r1.legal_code,						--6
  r1.legal_name,							--7
  case when  r1.city is null then '' else r1.city end,                             --8
  r1.business_date,                     --9
  convert(varchar(10),getdate(),120),  --10
  convert(varchar(12),getdate(),114) ,  --11
  'J02' ,   ---交易积分发行            --12
    case when   ic.firsttypeCode='10' then r1.item_code
	else r1.item_cat_mid_code 
	end ,                               --13
case when   ic.firsttypeCode='10' then r1.item_name
	else r1.item_cat_mid 	end ,                               --13.1
   sum(r1.reward_point) point_num,       --14
   sum(r1.reward_amount) point_amount,     --15
   'J0101',                                    --16积分业务类型
   N'交易积分发行',
    id ,                            --17
	'0'   fb_state                               --18 传输状态 
	,r1.TaxCode   --19
			,r1.RetailerId--20
			,StoreType --21
			,''DoBusinessCode  --22
			,r1.create_date 
    from   ds_R1_2_tran_reward  r1
    left join  item_cat  ic on r1.item_code=ic.MainItemid and  MatrixMemberId=@MatrixMemberId 
	left join RetailCode_MP rmp on r1.RetailerId=rmp.RetailerId
	where r1.create_date=@createDate  and rmp.MatrixMemberId=@MatrixMemberId  
   and not   (r1.member_reg_comp_code=r1.legal_code
	 	 ) 
	and  id not in (select id from e4_mult_reward where  fb_state in ( '0', '3', 'E', 'N', 'S') and  create_date =@createDate  and RetailerId=@RetailerId)
  group by  r1.member_reg_comp_code,     --1
  r1.member_reg_store_code,          --  2
  r1.member_reg_store,                --3
  r1.store_code,					  --4
  r1.store_name,					  --5
  r1.legal_code,						--6
  r1.legal_name,							--7
  r1.city,                             --4
  r1.business_date,  
  case when   ic.firsttypeCode='10' then  r1.item_name
	else r1.item_cat_mid 
	end ,         
   case when   ic.firsttypeCode='10' then r1.item_code
	else r1.item_cat_mid_code 
	end  ,
	id
	,r1.TaxCode   --19
			,r1.RetailerId--20
			,StoreType --21
			,create_date
	--	having 	sum(r1.reward_point)>0

	--select * from  	e4_mult_reward
	
	
	
	
	
delete  from e4_mult_reward where (fb_state='9' and Create_date =@createDate   and RetailerId=@RetailerId)  or id is null ; 
	
	--Reconciliation
	delete report_data..ReconciliationR2ERP 
	where RetailerId = @RetailerId 
	and DataType in ('E4')
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
	select @RetailerId,'E4',e.Create_date,e.business_date,sum(e.point_number),e.StoreType
	from e4_mult_reward e
	--left join [report_data].[dbo].store_gs store on e.store_code = store.storeid
	where e.RetailerId = @RetailerId 
	and e.Create_date = @createDate
	group by e.Create_date,e.business_date,e.StoreType		
		        
          
END


GO
