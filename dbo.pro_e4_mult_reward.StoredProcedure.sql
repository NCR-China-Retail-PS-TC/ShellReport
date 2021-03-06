USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[pro_e4_mult_reward]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [dbo].[pro_e4_mult_reward]
	 @business_date varchar(10)    --营业日期
AS
BEGIN
declare   @m_etl_date varchar(10);
 

set  @m_etl_date=convert(varchar(10),getdate(),120);
--set  @business_date=@m_etl_date	
delete [e4_mult_reward]  where  id is null 
DELETE       [e4_mult_reward] 	   where    [business_date]=@business_date
	       and  fb_state in ('0','E');
		  ;
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
   'J0101'+r1.store_code+r1.member_reg_store_code+r1.business_date+ case when   IC.firsttypeCode='10' then R1.item_code
	else R1.item_cat_mid_code 
	end  id ,                            --17
	'0'   fb_state                               --18 传输状态 
    from   ds_R1_2_tran_reward  r1
    left join  item_cat  ic on r1.item_code=ic.MainItemid and  MatrixMemberId=1
	where r1.business_date=@business_date and not  ( (r1.member_reg_comp_code=r1.legal_code
	 and r1.store_code not in ('4070','4071','4072','4073','4074','4075','4076')
	and   r1.member_reg_store_code not in ('4070','4071','4072','4073','4074','4075','4076') 
	 ) or  ( r1.store_code  in ('4070','4071','4072','4073','4074','4075','4076')
	  and r1.member_reg_store_code  in ('4070','4071','4072','4073','4074','4075','4076'))
	 ) 
	and   'J0101'+r1.store_code+r1.member_reg_store_code+r1.business_date+ case when   IC.firsttypeCode='10' then R1.item_code
	else R1.item_cat_mid_code  end not in (select id from e4_mult_reward where fb_state<>'9' and business_date =@business_date)
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
	'J0101'+r1.store_code+r1.member_reg_store_code+r1.business_date+ case when   IC.firsttypeCode='10' then R1.item_code
	else R1.item_cat_mid_code end;

	--select * from  	e4_mult_reward
	
	
	
	
	
delete  from e4_mult_reward where fb_state='9' and business_date =@business_date; 
	
		
		        
          
END


GO
