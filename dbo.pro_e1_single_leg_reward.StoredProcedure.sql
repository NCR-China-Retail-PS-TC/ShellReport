USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[pro_e1_single_leg_reward]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[pro_e1_single_leg_reward] @business_date1 VARCHAR(10) --营业日期
AS
  BEGIN
    declare @business_date varchar(10)=@business_date1
      DECLARE @m_etl_date VARCHAR(10);
      SET @m_etl_date=CONVERT(VARCHAR(10), Getdate(), 120);
      --set  @business_date=@m_etl_date	
      UPDATE [E1_single_leg_reward]
      SET    fb_state = '9'
      WHERE  [business_date] = @business_date
             AND fb_state IN ( '0', 'E' );;
      ---插入交易积分
	 /*   SELECT '' -- r1.member_reg_comp_code,     --1
             ,
             '' -- r1.member_reg_store_code,           --2
             ,
             '' -- r1.member_reg_store,                --3
             ,
             r1.store_code,--4
             r1.store_name,--5
             r1.legal_code,--6
             r1.legal_name,--7
             CASE
               WHEN r1.city IS NULL THEN 'a'
               ELSE r1.city
             END,--8
             r1.business_date,--9
             CONVERT(VARCHAR(10), Getdate(), 120),--10
             CONVERT(VARCHAR(12), Getdate(), 114),--11
             'J02',---交易积分发行            --12
             CASE
               WHEN ic.firsttypeCode = '10' THEN r1.item_code
               ELSE r1.item_cat_mid_code
             END,--13
             CASE
               WHEN ic.firsttypeCode = '10' THEN r1.item_name
               ELSE r1.item_cat_mid
             END,--13.1
             Sum(r1.reward_point)  point_num,--14
             Sum(r1.reward_amount) point_amount,--15
             'J0101',--16积分业务类型
             N'交易积分发行',--16.1
             'J0101' + r1.store_code + r1.business_date
             + CASE
                 WHEN IC.firsttypeCode = '10' THEN R1.item_code
                 ELSE R1.item_cat_mid_code
               END                 id,--17
             '0'                   fb_state --18 传输状态 
      FROM   ds_R1_2_tran_reward r1
             LEFT JOIN item_cat ic
                    ON r1.item_code = ic.MainItemid
                       AND MatrixMemberId = 1
      WHERE  r1.business_date = @business_date
             AND ( ( r1.member_reg_comp_code = r1.legal_code
                     AND r1.store_code NOT IN ( '4070', '4071', '4072', '4073',
                                                '4074', '4075', '4076' )
                     AND r1.member_reg_store_code NOT IN ( '4070', '4071', '4072', '4073',
                                                           '4074', '4075', '4076' ) )
                    OR ( r1.store_code IN ( '4070', '4071', '4072', '4073',
                                            '4074', '4075', '4076' )
                         AND r1.member_reg_store_code IN ( '4070', '4071', '4072', '4073',
                                                           '4074', '4075', '4076' ) ) )
             AND 'J0101' + r1.store_code + r1.business_date
                 + CASE
                     WHEN IC.firsttypeCode = '10' THEN R1.item_code
                     ELSE R1.item_cat_mid_code
                   END NOT IN (SELECT id
                               FROM   E1_single_leg_reward
                               WHERE  fb_state <> '9'
                                      AND business_date = @business_date)
      GROUP  BY -- r1.member_reg_comp_code,     --1
        -- r1.member_reg_store_code,          --  2
        -- r1.member_reg_store,                --3
        r1.store_code,--4
        r1.store_name,--5
        r1.legal_code,--6
        r1.legal_name,--7
        r1.city,--4
        r1.business_date,
        CASE
          WHEN ic.firsttypeCode = '10' THEN r1.item_name
          ELSE r1.item_cat_mid
        END,
        CASE
          WHEN ic.firsttypeCode = '10' THEN r1.item_code
          ELSE r1.item_cat_mid_code
        END,
        'J0101' + r1.store_code + r1.business_date
        + CASE
            WHEN IC.firsttypeCode = '10' THEN R1.item_code
            ELSE R1.item_cat_mid_code
          END  order by  id */
      INSERT INTO [dbo].[E1_single_leg_reward]
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
                   [city] --8  城市名称
                   ,
                   [business_date] --9  营业日期
                   ,
                   [etl_date] --10  抽取日期
                   ,
                   [etl_time] --11  抽取时间
                   ,
                   [point_type] --12  积分类型
                   ,
                   [commodity_type] --13  商品类别
                   ,
                   commodity_name --13.1
                   ,
                   [point_number] --14 积分数量
                   ,
                   [point_amount] --15  积分金额
                   ,
                   point_service_type -- 16 积分业务类型 01
                   ,
                   business_name --16.1 业务类型名称
                   ,
                   id --17 标识号
                   ,
                   fb_state --18 传输状态 0 未传输, 1 成功 2 失败 
      )
      SELECT '' -- r1.member_reg_comp_code,     --1
             ,
             '' -- r1.member_reg_store_code,           --2
             ,
             '' -- r1.member_reg_store,                --3
             ,
             r1.store_code,--4
             r1.store_name,--5
             r1.legal_code,--6
             r1.legal_name,--7
             CASE
               WHEN r1.city IS NULL THEN 'a'
               ELSE r1.city
             END,--8
             r1.business_date,--9
             CONVERT(VARCHAR(10), Getdate(), 120),--10
             CONVERT(VARCHAR(12), Getdate(), 114),--11
             'J02',---交易积分发行            --12
             CASE
               WHEN ic.firsttypeCode = '10' THEN r1.item_code
               ELSE r1.item_cat_mid_code
             END,--13
             CASE
               WHEN ic.firsttypeCode = '10' THEN r1.item_name
               ELSE r1.item_cat_mid
             END,--13.1
             Sum(r1.reward_point)  point_num,--14
             Sum(r1.reward_amount) point_amount,--15
             'J0101',--16积分业务类型
             N'交易积分发行',--16.1
             'J0101' + r1.store_code + r1.business_date
             + CASE
                 WHEN IC.firsttypeCode = '10' THEN R1.item_code
                 ELSE R1.item_cat_mid_code
               END                 id,--17
             '0'                   fb_state --18 传输状态 
      FROM   ds_R1_2_tran_reward r1
             LEFT JOIN item_cat ic
                    ON r1.item_code = ic.MainItemid
                       AND MatrixMemberId = 1
      WHERE  r1.business_date = @business_date
             AND ( ( r1.member_reg_comp_code = r1.legal_code
                     AND r1.store_code NOT IN ( '4070', '4071', '4072', '4073',
                                                '4074', '4075', '4076' )
                     AND r1.member_reg_store_code NOT IN ( '4070', '4071', '4072', '4073',
                                                           '4074', '4075', '4076' ) )
                    OR ( r1.store_code IN ( '4070', '4071', '4072', '4073',
                                            '4074', '4075', '4076' )
                         AND r1.member_reg_store_code IN ( '4070', '4071', '4072', '4073',
                                                           '4074', '4075', '4076' ) ) )
             AND 'J0101' + r1.store_code + r1.business_date
                 + CASE
                     WHEN IC.firsttypeCode = '10' THEN R1.item_code
                     ELSE R1.item_cat_mid_code
                   END NOT IN (SELECT id
                               FROM   E1_single_leg_reward
                               WHERE  fb_state <> '9'
                                      AND business_date = @business_date)
      GROUP  BY -- r1.member_reg_comp_code,     --1
        -- r1.member_reg_store_code,          --  2
        -- r1.member_reg_store,                --3
        r1.store_code,--4
        r1.store_name,--5
        r1.legal_code,--6
        r1.legal_name,--7
        r1.city,--4
        r1.business_date,
        CASE
          WHEN ic.firsttypeCode = '10' THEN r1.item_name
          ELSE r1.item_cat_mid
        END,
        CASE
          WHEN ic.firsttypeCode = '10' THEN r1.item_code
          ELSE r1.item_cat_mid_code
        END,
        'J0101' + r1.store_code + r1.business_date
        + CASE
            WHEN IC.firsttypeCode = '10' THEN R1.item_code
            ELSE R1.item_cat_mid_code
          END;
      PRINT N'交易积分发行'
      --select * from  	E1_single_leg_reward
      --插入开户送积分
      INSERT INTO [dbo].[E1_single_leg_reward]
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
                   [city] --8  城市名称
                   ,
                   [business_date] --9  营业日期
                   ,
                   [etl_date] --10  抽取日期
                   ,
                   [etl_time] --11  抽取时间
                   ,
                   [point_type] --12  积分类型
                   ,
                   [commodity_type] --13  商品类别
                   ,
                   commodity_name --13.1
                   ,
                   [point_number] --14 积分数量
                   ,
                   [point_amount] --15  积分金额
                   ,
                   point_service_type -- 16 积分业务类型 01
                   ,
                   business_name,
                   id --17 标识号
                   ,
                   fb_state --18 传输状态 0 未传输, 1 成功 2 失败 
      )
      SELECT r9.member_reg_comp_code,--1
             r9.member_reg_comp_code,-- r9.member_reg_store_code,           --2
             r9.member_reg_store,--3
             r9.store_id,--4
             r9.member_reg_store,--5
             r9.member_reg_comp_code,--6
             r9.member_reg_comp,--7
             CASE
               WHEN r9.city IS NULL THEN ' '
               ELSE r9.city
             END,--8
             r9.business_date,--9
             CONVERT(VARCHAR(10), Getdate(), 120),--10
             CONVERT(VARCHAR(12), Getdate(), 114),--11
             'J01'                       point_type,-- 其它手工调整积分     
             '1022'                      [commodity_type],--默认油料号 11.6 modify from 1000 to 1022                --13
             N'92#国六',--13.1
             Sum(number_awarding)        point_num,--14
             Sum(number_awarding_amount) point_amount,--15
             CASE
               WHEN R9.reason_adjust_code = '21' THEN 'J0102' --开户送积分  注册奖励积分
               WHEN R9.reason_adjust_code = '4' THEN 'J0103' --客户调查赠送积分
               WHEN R9.reason_adjust_code = '3' THEN 'J0104' --系统维护补录积分    
               ELSE 'J0105'
             END,--   其它手工调整积分                     --16积分业务类型
             CASE
               WHEN R9.reason_adjust_code = '21' THEN N'开户送积分' --开户送积分
               WHEN R9.reason_adjust_code = '4' THEN N'客户调查赠送积分'
               WHEN R9.reason_adjust_code = '25' THEN N'投诉积分' --投诉积分  J0105   
               WHEN R9.reason_adjust_code = '3' THEN N'系统维护补录积分'
               ELSE N'其它手工调整积分'
             END,--16.1积分业务类型
             CASE
               WHEN R9.reason_adjust_code = '21' THEN 'J0102' --开户送积分  注册奖励积分
               WHEN R9.reason_adjust_code = '4' THEN 'J0103' --客户调查赠送积分
			    WHEN R9.reason_adjust_code = '25' THEN N'投诉积分' --投诉积分  J0105  
               WHEN R9.reason_adjust_code = '3' THEN 'J0104' --系统维护补录积分    
               ELSE 'J0105'
             END --   其它手工调整积分                   
             + r9.member_reg_comp_code + r9.store_id
             + r9.business_date + '1000' id,--17
             '0'                         fb_state --18 传输状态 
      FROM   ds_R9_adjust r9
      WHERE  r9.business_date = @business_date
             AND CASE
                   WHEN R9.reason_adjust_code = '21' THEN 'J0102' --开户送积分  注册奖励积分
                   WHEN R9.reason_adjust_code = '4' THEN 'J0103' --客户调查赠送积分
                   WHEN R9.reason_adjust_code = '3' THEN 'J0104' --系统维护补录积分    
                   ELSE 'J0105'
                 END
                 + r9.member_reg_comp_code + r9.store_id
                 + r9.business_date + '1000' NOT IN (SELECT id
                                                     FROM   E1_single_leg_reward
                                                     WHERE  fb_state <> '9'
                                                            AND business_date = @business_date)
      GROUP  BY
        r9.member_reg_comp_code,--1
        r9.member_reg_store_code,--2
        r9.member_reg_store,--3
        r9.store_id,--4
        r9.member_reg_store,--5
        r9.member_reg_comp_code,
        r9.member_reg_comp,
        r9.city,--8
        r9.business_date,--9
        CASE
          WHEN R9.reason_adjust_code = '21' THEN 'J0102' --开户送积分  注册奖励积分
          WHEN R9.reason_adjust_code = '4' THEN 'J0103' --客户调查赠送积分
          WHEN R9.reason_adjust_code = '3' THEN 'J0104' --系统维护补录积分    
          ELSE 'J0105'
        END,--   其它手工调整积分                     --16积分业务类型
        CASE
          WHEN R9.reason_adjust_code = '21' THEN N'开户送积分' --开户送积分
          WHEN R9.reason_adjust_code = '4' THEN N'客户调查赠送积分'
          WHEN R9.reason_adjust_code = '25' THEN N'投诉积分' --投诉积分  J0105   
          WHEN R9.reason_adjust_code = '3' THEN N'系统维护补录积分'
          ELSE N'其它手工调整积分'
        END,
        CASE
          WHEN R9.reason_adjust_code = '21' THEN 'J0102' --开户送积分  注册奖励积分
          WHEN R9.reason_adjust_code = '4' THEN 'J0103' --客户调查赠送积分
		   WHEN R9.reason_adjust_code = '25' THEN N'投诉积分' --投诉积分  J0105  
          WHEN R9.reason_adjust_code = '3' THEN 'J0104' --系统维护补录积分    
          ELSE 'J0105'
        END
        + r9.member_reg_comp_code + r9.store_id
        + r9.business_date + '1000' --17
      PRINT N'其它手工调整积分'
      DELETE FROM E1_single_leg_reward
      WHERE  fb_state = '9'
             AND business_date = @business_date;
  END 

GO
