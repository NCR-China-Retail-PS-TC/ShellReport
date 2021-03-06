USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[MemberConsumeInfo]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
--2020-11-01 深深铭记在小油滴心
exec  MemberConsumeInfo
*/
-- =============================================
CREATE PROCEDURE   [dbo].[MemberConsumeInfo]
	
AS
BEGIN
DECLARE  @BeginDate VARCHAR(10)='2020-01-01'
         ,@endDate  varchar(10)=convert(varchar(10),getdate()-2,120)
        ,@ClubCardId  nvarchar(50)='7004900089894650910'
		,@json nvarchar(max)
	
		set transaction isolation  level read uncommitted;
	truncate table report_data.[dbo].[CRM_MemberConsumeInfo_t] 
	
	-- 会员首次加油时间
	print N'会员首次加油时间'
	declare   @firstDatetime table  
	( clubCardId varchar(50) collate DATABASE_DEFAULT ,
	  firstDateTime nvarchar(10)
	)
	insert into @firstDatetime
	SELECT cpt.ClubCardId, convert(varchar(10),min(cpt.PosDateTime),120) [FirstDateTime]  FROM Loyalty_Shell_prod..CRM_POSTran CPT 
	left join report_data..store_gs s  on cpt.StoreInternalKey=s.StoreInternalKey and cpt.MatrixMemberId=s.MatrixMemberId
	WHERE CPT.PosDateTime>=CONVERT(date,@BeginDate ,120) and  CPT.PosDateTime<=CONVERT(date,@endDate ,120)
	and s.IsVirtualStore=0  
	group by cpt.ClubCardId


/*	1.会员光顾次数最多的加油站：
如会员数据中显示有2个或以上的加油站，有相同的加油次数，则：
a.随机选择一个展示
2.在该加油站加油的次数

select * from (select pro_id,img,create_time, ROW_NUMBER() over(partition by pro_id order by  create_time) as row_sort  from product_imgs )
  as t where t.row_sort=1
*/
print N'会员光顾次数最多的加油站'
	declare   @mostStore table  
	( clubCardId varchar(50) collate DATABASE_DEFAULT 
	   ,storeid  nvarchar(10)
	   ,storename nvarchar(100) 
	   ,times int 
	)
	 insert into @mostStore
	 select  t.ClubCardId ,t.storeid,t.storename,t.FirstStoreTransTimes from  (SELECT cpt.ClubCardId,s.storeid,s.storename
	 , ROW_NUMBER() over (partition by  ClubCardId order by count(1)  desc ) as number
	 ,count(1)   as  [FirstStoreTransTimes] 
	 FROM Loyalty_Shell_prod..CRM_POSTran CPT 
	left join report_data..store_gs s  on cpt.StoreInternalKey=s.StoreInternalKey and cpt.MatrixMemberId=s.MatrixMemberId
	WHERE CPT.PosDateTime>=CONVERT(date,@BeginDate ,120) and CPT.PosDateTime<=CONVERT(date,@EndDate ,120)
	and
	  s.IsVirtualStore=0 
	   group by cpt.ClubCardId,s.storeid,s.storename ) t where  number=1
	
--会员最晚的加油时间
print N'会员最晚的加油时间'
  declare @lastTime  table 
  (clubCardId varchar(50),
   lasttime varchar(20))
	
	insert into @lastTime 
	SELECT cpt.ClubCardId,convert(varchar(20),max(cpt.CreatedAt),120) LastDatetime  FROM Loyalty_Shell_prod..CRM_POSTran CPT 
	left join report_data..store_gs s  on cpt.StoreInternalKey=s.StoreInternalKey and cpt.MatrixMemberId=s.MatrixMemberId
	WHERE CPT.PosDateTime>=CONVERT(date,@BeginDate ,120)  and CPT.PosDateTime<=CONVERT(date,@EndDate ,120)
	and s.IsVirtualStore=0  
	group by cpt.ClubCardId


	/*会员在壳牌便利店消费相关数据：
	1.商品件数；2.实际花费金额
	*/
 
   DECLARE   @sql      NVARCHAR(max),
              @orgSql   NVARCHAR(max),
              @CurMonth NVARCHAR(6),
			  
              @curDate  DATE=getdate(),
			  @MatrixMemberId int 

  declare @tableDate_cur varchar(6) ,@tableDate_pre varchar(6) 
	,@atd_Server nvarchar(max) ='ATD_Shell'		
	,@ServerHost nvarchar(max)='HOST_Shell_1'
	,@loyalty_server varchar(max)='Loyalty_Shell_prod'
	,@sql_text  nvarchar(max)
	,@sql_text_org nvarchar(max)
		,@sql_text_org1 nvarchar(max)
	select @atd_Server=c.paraValue0   from dbo.param_config c  where c.paraName='atd_Server';
	select @ServerHost=c.paraValue0   from dbo.param_config c  where c.paraName='ServerHost';
	select @loyalty_server=c.paraValue0   from dbo.param_config c  where c.paraName='loyalty_server';


         --非油
	  	if OBJECT_ID('tempdb..##nfrsale1') is not null 
         drop table ##nfrsale1
        create table  ##nfrsale1
        (
           ClubCardId          NVARCHAR(50) collate DATABASE_DEFAULT 
           ,TotalAmount DECIMAL(13, 3) 
           ,totalqty    float
		   ,monthly   int
        )
 SET @curdate=CONVERT(DATE, @beginDate, 120)
      SET @curMonth=CONVERT(VARCHAR(6), CONVERT(DATE, @curdate, 120), 112)

 
    print    N'会员在壳牌便利店消费相关数据'  
     WHILE CONVERT(INT, @CurMonth) <= CONVERT(INT, Substring(@EndDate, 1, 4)
                                             + Substring(@EndDate, 6, 2))
        BEGIN
            SET @orgSql=' 

        select  ftcc.CardId,sum(fts.amount-isnull(ftprd.RewardValue,0)) amount, sum(fts.qty) qty ,fts.ItemId,@curMonth as monthly
		,ftc.RetailerId,  ftc.StoreId into #a 
		   from    [ATD_Shell].[dbo].[FO_TranCollection] ftc 
		 left join   [ATD_Shell].dbo.FO_TranHeader202008  fth on ftc.CollectionInternalKey=fth.CollectionInternalKey
		 left join   ( select  fts1.TicketInternalKey,fts1.ItemId,sum(fts1.Amount) as  amount,sum(fts1.qty) as qty 
		  from  [ATD_Shell].dbo.FO_TranSale202008 fts1   group  by  fts1.TicketInternalKey,fts1.ItemId ) fts 
		     on fts.TicketInternalKey=fth.TicketInternalKey
	 		left join (select    TicketInternalKey,		    sum(ftprd1.RewardValue)    as RewardValue , entityid
	                      from  [ATD_Shell].dbo.FO_TranPromotionRewardApportionment202008 ftprd1 where RewardMethodId=4 
                            group by  TicketInternalKey,entityid ) ftprd
			on ftprd.TicketInternalKey=fts.TicketInternalKey and ftprd.EntityId=fts.ItemId 
		     left join ATD_Shell..FO_TranCard202008 ftcc                on ftcc.TicketInternalKey=fth.TicketInternalKey
		 	   
	  where    ftc.businessDate>=CONVERT(date,@BeginDate ,120) and   ftc.businessDate<=CONVERT(date,@EndDate ,120)
	  group by ftcc.CardId,fts.ItemId,ftc.RetailerId,  ftc.StoreId 

	  
      

	 
	 delete a  from #a  a
	  left join report_data..RetailCode_MP rc  on a.RetailerId=rc.RetailerId
		left join report_data..store_gs store on a.StoreId=store.storeid and rc.MatrixMemberId=store.MatrixMemberId
	 left join  [report_data].[dbo].item_cat  item  on item.MainItemId=a.ItemId and item.MatrixMemberId=rc.MatrixMemberId 
 	   
	     where   store.IsVirtualStore=1 or  item.firsttypeCode  like +'''+'10%'+'''
  
   insert into ##nfrsale1	
	   select CardId,sum(amount) amount, sum(qty) qty,monthly
	   from #a
	   group by CardId,monthly
	   drop   table  #a ' 
	        SET @sql=@orgSql;
            SET @sql = Replace(@sql, 'ATD_Shell', @atd_Server);
            SET @sql = Replace(@sql, 'Loyalty_Shell_prod', @loyalty_server);
            SET @sql = Replace(@Sql, '@curMonth', @curMonth);
		    SET @sql = Replace(@Sql, '202008', @curMonth);
            SET @sql = Replace(@sql, '@BeginDate', '''' + @BeginDate + '''');
            SET @sql = Replace(@sql, '@EndDate', '''' + @EndDate + '''');
         
			select @sql
      --     insert into ##nfrsale1	
            EXEC (@sql)

            SET @curdate=Dateadd(month, 1, @curdate)
            SET @curMonth=CONVERT(VARCHAR(6), CONVERT(DATE, @curdate, 120), 112)
        END;

		if OBJECT_ID('tempdb..##nfrsale') is not null 
             drop table ##nfrsale
        create table  ##nfrsale
        (
           ClubCardId          NVARCHAR(50) collate DATABASE_DEFAULT 
           ,TotalAmount DECIMAL(13, 3) 
           ,totalqty    float
        )
   
     print 'insert into ##nfrsale'
		insert into ##nfrsale
		  select n.ClubCardId ,sum(n.TotalAmount) amount ,sum(n.totalqty) qty
		      from  ##nfrsale1 n 
		   group by n.ClubCardId

		   -------------------------------
/*
消费v power燃油次数 & 总加油升数
		   此幕数据仅算：SVP燃油 95+98（需要每个jv具体的油品编码，哪些编码的油品是svp）

*/

 	if OBJECT_ID('tempdb..##frsale1') is not null 
         drop table ##frsale1
        create table  ##frsale1
        (
           ClubCardId          NVARCHAR(50)
           ,TotalAmount DECIMAL(13, 3)   --frtimes
           ,totalqty    float   --frqty
        )
		
SET @curdate=CONVERT(DATE, @beginDate, 120)
      SET @curMonth=CONVERT(VARCHAR(6), CONVERT(DATE, @curdate, 120), 112)

  set @enddate=convert(varchar(10),getdate(),120)
   
 print N'消费v power燃油次数 & 总加油升数'

  WHILE CONVERT(INT, @CurMonth) <= CONVERT(INT, Substring(@EndDate, 1, 4)
                                                    + Substring(@EndDate, 6, 2))
        BEGIN
            SET @orgSql=' 
        select  ftcc.CardId,   fth.TicketInternalKey  ,sum(fts.Qty) qty 
		,ftc.RetailerId,  ftc.StoreId   
		 into #aa
		from    [ATD_Shell].[dbo].[FO_TranCollection] ftc 
		 left join   [ATD_Shell].dbo.FO_TranHeader202008  fth on ftc.CollectionInternalKey=fth.CollectionInternalKey
		 left join   [ATD_Shell].dbo.FO_TranSale202008 fts on fts.TicketInternalKey=fth.TicketInternalKey
		 inner join report_data..CRM_MemberConsumeSvp svp on svp.sku=fts.ItemId  and svp.retailerId=ftc.RetailerId
	 	  left join ATD_Shell..FO_TranCard202008 ftcc                on ftcc.TicketInternalKey=fth.TicketInternalKey
		  
		 where   ftc.businessDate>=CONVERT(date,@BeginDate ,120)   and   ftc.businessDate<=CONVERT(date,@EndDate ,120)
			   group by ftcc.CardId,  fth.TicketInternalKey ,ftc.RetailerId,  ftc.StoreId 
			
			 
			  delete a from #aa  a
			  left join   report_data..RetailCode_MP rc on rc.RetailerId=a.RetailerId
			  left join report_data..store_gs store on  a.StoreId=store.storeid and rc.MatrixMemberId=store.MatrixMemberId
			  where store.IsVirtualStore=1

           insert into ##frsale1	
		   select  CardId,   count(1)  frtimes,sum(Qty) frqty 
		     from #aa
		     group by  CardId
			 drop table  #aa
 	   '

	        SET @sql=@orgSql;
            SET @sql = Replace(@sql, 'ATD_Shell', @atd_Server);
            SET @sql = Replace(@sql, 'Loyalty_Shell_prod', @loyalty_server);
            SET @sql = Replace(@Sql, '202008', @curMonth);
            SET @sql = Replace(@sql, '@BeginDate', '''' + @BeginDate + '''');
            SET @sql = Replace(@sql, '@EndDate', '''' + @EndDate + '''');
         
	--		select @sql
      --       insert into ##frsale1	
            EXEC (@sql)

            SET @curdate=Dateadd(month, 1, @curdate)
            SET @curMonth=CONVERT(VARCHAR(6), CONVERT(DATE, @curdate, 120), 112)
        END;

		if OBJECT_ID('tempdb..##frsale') is not null 
         drop table ##frsale
        create table  ##frsale
        (
           ClubCardId          NVARCHAR(50)
           ,TotalAmount DECIMAL(13, 3) 
           ,totalqty    float
        )

		insert into ##frsale
		  select n.ClubCardId ,sum(n.TotalAmount) amount ,sum(n.totalqty) qty
		      from  ##frsale1 n 
		   group by n.ClubCardId

/*
   1.时间段内用户获得的总优惠金额
1.会员累计加油次数 2.会员累计消费金额3.会员消费排行（所在地区范围，非全国）
*/
	if OBJECT_ID('tempdb..##discount1') is not null 
         drop table ##discount1
        create table  ##discount1
        (
           ClubCardId          NVARCHAR(50) collate DATABASE_DEFAULT 
		    ,TotalFRtimes float
			  ,TotalFRQty  float
			     ,TotalAmount float
		   ,Totaldiscount float 
		    , monthly int
		  
		
		   
           
        )
		SET @curdate=CONVERT(DATE, @beginDate, 120)
      SET @curMonth=CONVERT(VARCHAR(6), CONVERT(DATE, @curdate, 120), 112)


 print N'时间段内用户获得的总优惠金额'
  WHILE CONVERT(INT, @CurMonth) <= CONVERT(INT, Substring(@EndDate, 1, 4)
                                                    + Substring(@EndDate, 6, 2))
        BEGIN
            SET @orgSql=' 
        select  ftcc.CardId,
		      count(1 ) as totalFRtimes,sum(fts.Qty) FRQty ,0 as TotalAmount,0 as TotalDiscount, @curMonth as monthly,ftc.RetailerId,  ftc.StoreId   
		 into #aa
		from    [ATD_Shell].[dbo].[FO_TranCollection] ftc 
		 left join   [ATD_Shell].dbo.FO_TranHeader202008  fth on ftc.CollectionInternalKey=fth.CollectionInternalKey
		 left join ATD_Shell..FO_TranCard202008 ftcc                on ftcc.TicketInternalKey=fth.TicketInternalKey
		 left join ATD_Shell..FO_TranSale202008 fts on fth.TicketInternalKey=fts.TicketInternalKey
		 left join report_data..RetailCode_MP rc on ftc.RetailerId=rc.RetailerId
		  inner join report_data..item_cat i on fts.ItemId=i.MainItemId and i.MatrixMemberId=rc.MatrixMemberId and  i.firsttypecode like '''+'10%'+'''
		 
 	   
		  where  ftc.businessDate>=CONVERT(date,@BeginDate ,120)   and   ftc.businessDate<=CONVERT(date,@EndDate ,120)
			  group by ftcc.CardId,fts.ItemId,fts.TicketInternalKey,ftc.RetailerId,  ftc.StoreId   
			  union all 
		select  ftcc.CardId,
		      0 as TotalFRTimes , 0,sum(fth.TotalAmount) as TotalAmount,sum(fth.Discount) as TotalDiscount,@curMonth,ftc.RetailerId,  ftc.StoreId   
		 
		from    [ATD_Shell].[dbo].[FO_TranCollection] ftc 
		 left join   [ATD_Shell].dbo.FO_TranHeader202008  fth on ftc.CollectionInternalKey=fth.CollectionInternalKey
		 left join ATD_Shell..FO_TranCard202008 ftcc                on ftcc.TicketInternalKey=fth.TicketInternalKey
		 
		
 	   
		 where  ftc.businessDate>=CONVERT(date,@BeginDate ,120)  and   ftc.businessDate<=CONVERT(date,@EndDate ,120)	
		   group by ftcc.CardId ,ftc.RetailerId,  ftc.StoreId  
			  

			  	  delete a from #aa  a
			  left join   report_data..RetailCode_MP rc on rc.RetailerId=a.RetailerId
			  left join report_data..store_gs store on  a.StoreId=store.storeid and rc.MatrixMemberId=store.MatrixMemberId
			  where store.IsVirtualStore=1

           insert into ##discount1		
		   select    CardId,
		      count( totalFRtimes ) as totalFRtimes,sum(FRQty) FRQty ,sum(TotalAmount)  as TotalAmount,sum(TotalDiscount) as TotalDiscount, @curMonth as monthly   
		 
		     from #aa
		     group by  CardId
			 drop table  #aa
			    '

	        SET @sql=@orgSql;
            SET @sql = Replace(@sql, 'ATD_Shell', @atd_Server);
            SET @sql = Replace(@sql, 'Loyalty_Shell_prod', @loyalty_server);
            SET @sql = Replace(@Sql, '202008', @curMonth);
               SET @sql = Replace(@Sql,  '@curMonth', @curMonth);
            SET @sql = Replace(@sql, '@BeginDate', '''' + @BeginDate + '''');
            SET @sql = Replace(@sql, '@EndDate', '''' + @EndDate + '''');
         
			select @sql
         
            EXEC (@sql)

            SET @curdate=Dateadd(month, 1, @curdate)
            SET @curMonth=CONVERT(VARCHAR(6), CONVERT(DATE, @curdate, 120), 112)
        END;

		if OBJECT_ID('tempdb..##discount') is not null 
         drop table ##discount
        create table  ##discount
        (
           ClubCardId          NVARCHAR(100) collate DATABASE_DEFAULT 
           ,TotalFRQty  float
		   ,Totaldiscount float 
		   ,TotalFRtimes float
		   ,TotalAmount float
)
 print N'insert into ##discount'
		insert into ##discount(ClubCardId --1 
           ,Totaldiscount                --2
		   ,TotalFRQty                   --3
		   ,TotalFRtimes                 --4
		   ,TotalAmount                  --5
		   )
		  select n.ClubCardId  --1
		        ,sum(n.TotalDiscount) --2
				,sum(n.TotalFRQty)  --3 
				,sum(n.TotalFRtimes) --4
				,sum(n.TotalAmount)  --5
		      from  ##discount1 n 
		   group by n.ClubCardId

;
print N'insert into   [dbo].CRM_MemberConsumeInfo_t 
	 ';
  with regcom1 as ( select count(1)  RecCount, rm.compid  from ##discount d
 left join Loyalty_Shell_prod..CRM_Clubcard cc on d.ClubCardId=cc.ClubCardId 
left join Loyalty_Shell_prod..CRM_Member cm  on cc.MemberInternalKey=cm.MemberInternalKey
left join report_data.[dbo].[v_get_reg_compAndStore]  RM on rm.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
 group by rm.compid )
  
 	insert into [dbo].CRM_MemberConsumeInfo_t 
	( ClubCardId   --1
	,JVCode   --2
	,JVCodeName  --3
	,orderNumber  --4
	,OrderPercent  --5
	,discount  --6
	,transTimes  --7
	,totalConsume   --8
	)

select d.ClubCardId  --1
,rm.compid      ---2
,rm.comp     --3
,ROW_NUMBER() over(  partition by     rm.compid order by d.TotalFRQty desc) as orderNumber --4
,  cast(( regcom1.recCount-  ROW_NUMBER() over(  partition by rm.compid order by d.TotalFRQty desc))/(regcom1.RecCount*1.00)*100  as decimal(10,2))
   OrderPercent  --5
  ,d.Totaldiscount --6
  ,d.TotalFRtimes  --7
  ,d.TotalAmount  --8
   from  ##discount d
left join Loyalty_Shell_prod..CRM_Clubcard cc on d.ClubCardId=cc.ClubCardId  
left join Loyalty_Shell_prod..CRM_Member cm  on cc.MemberInternalKey=cm.MemberInternalKey
left join report_data.[dbo].[v_get_reg_compAndStore]  RM on rm.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
left join  regcom1 on  regcom1.compid=rm.compid
 where rm.compid is not null

print N'merge into [dbo].[CRM_MemberConsumeInfo_t]  '
  merge into [dbo].[CRM_MemberConsumeInfo_t]  cmci
 
USING ( select * from  ##frsale ) sale
ON   cmci.ClubCardId=sale.ClubCardId collate Latin1_General_CI_AS_KS 
WHEN MATCHED THEN 
    UPDATE  
    SET frtimes = sale.totalAmount -- 消费v power燃油次数
,
        frqty = sale.totalqty    --消费v power  总加油升数
WHEN NOT MATCHED THEN 
    INSERT (ClubCardid,frtimes,frqty) VALUES ( sale.ClubCardId, sale.totalamount,sale.totalqty);


 --会员在壳牌便利店消费相关数据
 print N'会员在壳牌便利店消费相关数据'
 
  merge into [dbo].[CRM_MemberConsumeInfo_t]  cmci
 USING ( select * from ##nfrsale ) sale
ON   cmci.ClubCardId=sale.ClubCardId  
WHEN MATCHED THEN 
    UPDATE  
    SET  nframount = sale.totalAmount -- 消费v power燃油次数
    ,    nfrqty = sale.totalqty    --消费v power  总加油升数
WHEN NOT MATCHED THEN 
    INSERT (ClubCardid,nframount,nfrqty) VALUES ( sale.ClubCardId,sale.totalamount,sale.totalqty);


	print N'1merge into [dbo].[CRM_MemberConsumeInfo_t]'
merge into [dbo].[CRM_MemberConsumeInfo_t]  cmci
 
USING ( select * from @mostStore ) s
ON   cmci.ClubCardId=s.ClubCardId
WHEN MATCHED THEN 
    UPDATE  
    SET  firstStoreCode  = s.storeid
	     ,firstStoreTransTimes=s.times
		,FistStoreName=s.storename
   
WHEN NOT MATCHED THEN 
    INSERT (ClubCardid,firstStoreCode,FistStoreName,firstStoreTransTimes) VALUES (clubcardid,storeid,storename,times);

	print N'2 merge into [dbo].[CRM_MemberConsumeInfo_t]'
merge into [dbo].[CRM_MemberConsumeInfo_t]  cmci
 
USING ( select * from @firstDatetime ) s
ON   cmci.ClubCardId=s.ClubCardId
WHEN MATCHED THEN 
    UPDATE  
    SET  firstDateTime  = s.firstDateTime
WHEN NOT MATCHED THEN 
    INSERT (ClubCardid,firstDateTime) VALUES (clubcardid,firstDateTime);

print N'3 merge into [dbo].[CRM_MemberConsumeInfo_t]'
merge into [dbo].[CRM_MemberConsumeInfo_t]  cmci
 
USING ( select * from @lastTime ) s
ON   cmci.ClubCardId=s.ClubCardId
WHEN MATCHED THEN 
    UPDATE  
    SET  lastDatetime  = s.lasttime
WHEN NOT MATCHED THEN 
    INSERT (ClubCardid,lastDatetime) VALUES (clubcardid,lasttime);
set @sql='
update a   set a.RegDate=convert(varchar(10),cm.startdate,120),
  a.JVCode=v.compid,a.JVCodeName=v.comp,  RetailerId=rc.RetailerId,RetailerName=rc.Name
 

 from CRM_MemberConsumeInfo_t a
   left join Loyalty_Shell_prod..CRM_Clubcard cc on a.ClubCardId=cc.ClubCardId
         left join Loyalty_Shell_prod..CRM_Member cm on cm.MemberInternalKey =cc.MemberInternalKey
 left join report_data..v_get_reg_compAndStore v on v.MemberInternalKey=cc.MemberInternalKey
 left join report_data..RetailCode_MP rc on rc.MatrixMemberId=cc.MatrixMemberId

 '
          SET @sql = Replace(@sql, 'Loyalty_Shell_prod', @loyalty_server);
  print N' update  JVCode=v.compid,a.JVCodeName=v.comp,  RetailerId'
   exec(@sql);

 print '[CRM_MemberConsumeInfo]'
 truncate table CRM_MemberConsumeInfo
INSERT INTO [dbo].[CRM_MemberConsumeInfo]
           ([ClubCardId]
           ,[RegDate]
           ,[RetailerId]
           ,RetailerName
           ,[JVCode]
           ,[JVCodeName]
           ,[FirstDateTime]
           ,[FirstStoreCode]
           ,[FistStoreName]
           ,[FirstStoreTransTimes]
           ,[LastDatetime]
           ,[NFRQTY]
           ,[NFRAmount]
           ,[FRTimes]
           ,[FRQty]
           ,[discount]
           ,[transTimes]
           ,[totalConsume]
           ,[orderNumber]
           ,[OrderPercent]
           ,[ETLday])
  select   [ClubCardId]
           ,[RegDate]
           ,[RetailerId]
           ,[RetailerName]
           ,[JVCode]
           ,[JVCodeName]
           ,[FirstDateTime]
           ,[FirstStoreCode]
           ,[FistStoreName]
           ,[FirstStoreTransTimes]
           ,[LastDatetime]
           ,[NFRQTY]
           ,[NFRAmount]
           ,[FRTimes]
           ,[FRQty]
           ,[discount]
           ,[transTimes]
           ,[totalConsume]
           ,[orderNumber]
           ,[OrderPercent]
           ,getdate()
		   from  CRM_MemberConsumeInfo_t t 
		   left join Loyalty_Shell_prod..CRM_Member cm on t.ClubCardId=cm.ExternalMemberKey
		   where JVCode is not null and isnull(cm.MobilePhoneNumber,'')<>''
		   if  OBJECT_ID('index_card')  is not null
		   drop index  index_card on CRM_MemberConsumeInfo_t
  
     if   exists(select *  from sys.sysindexes s where s.name='index_card' and  id=object_id('CRM_MemberConsumeInfo_t'  ) )
	    drop index  index_card on CRM_MemberConsumeInfo_t
   print N' create index  index_card'
         create index  index_card on CRM_MemberConsumeInfo_t(ClubCardId)   
    set @sql='  	insert into [CRM_MemberConsumeInfo]
           ([ClubCardId]
           ,[RegDate]
           ,[RetailerId]
           ,[RetailerName]
           ,[JVCode]
           ,[JVCodeName]
           ,[ETLday])
		  
		
 select    cm.ExternalMemberKey,convert(varchar(10),cm.StartDate,120),r.RetailerId,r.Name ,v.compid,v.comp ,getdate()
	    from   Loyalty_Shell_prod..CRM_Member cm 
		left join Loyalty_Shell_prod..CRM_Clubcard cc on cm.MemberInternalKey=cc.MemberInternalKey
		left join report_data..v_get_reg_compAndStore v on v.MemberInternalKey=cm.MemberInternalKey
		left join report_data..RetailCode_MP r on r.MatrixMemberId=cc.MatrixMemberId
			where  not exists ( select 1 from CRM_MemberConsumeInfo_t  t where   t.ClubCardId=cm.ExternalMemberKey )

  '

      SET @sql = Replace(@sql, 'ATD_Shell', @atd_Server);
            SET @sql = Replace(@sql, 'Loyalty_Shell_prod', @loyalty_server);
   exec(@sql);


 set @sql='	

 select [ClubCardId]
           ,[RegDate]
           ,[RetailerId]
           ,[RetailerName]
           ,[JVCode]
           ,[JVCodeName]
           ,[FirstDateTime]
           ,[FirstStoreCode]
           ,[FistStoreName]
           ,[FirstStoreTransTimes]
            ,[LastDatetime]
           ,[NFRQTY]
           ,[NFRAmount]
           ,[FRTimes]
           ,[FRQty]
           ,[discount]
           ,[transTimes]
           ,[totalConsume]
           ,[orderNumber]
           ,[OrderPercent]
		     from  CRM_MemberConsumeInfo cmc1 
where    cmc1.ClubCardId='''+@ClubCardId+''''

EXEC report_data..[SerializeJSON]   @sql,@json output
set @json=N'{"CRM_MemberConsumeInfo_t":'+@json+N'}'
 print @json

END


GO
