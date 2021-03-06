USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[MemberConsumeInfoIncrement]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
--2020-12-07  消费增量会员
exec  [MemberConsumeInfoIncrement] 1
*/
-- =============================================
CREATE  PROCEDURE   [dbo].[MemberConsumeInfoIncrement]
	 @firstrun int   ---=首次运行等于1   
AS
BEGIN
      
    DECLARE  @BeginDate VARCHAR(10)
       --  @BeginDate VARCHAR(10)='2020-01-01'
         ,@endDate  varchar(10)=convert(varchar(10),getdate()-1,120)
    	 ,@json nvarchar(max)
	     ,@BeginDateFirst  varchar(10)='2020-01-01'
	
		set transaction isolation  level read uncommitted;
		if @firstrun=1
 begin
   truncate  table  CRM_MemberConsumeETL
  	truncate table report_data.[dbo].[CRM_MemberConsumeInfo] 
     truncate table   report_data.[dbo].[CRM_MemberConsumeInfo_HIS]
   end
	 if @firstrun=1 
	 set @BeginDate =@BeginDateFirst
	 else set  @BeginDate  =convert(varchar(10),getdate()-1,120)

	 IF EXISTS(SELECT *  FROM CRM_MemberConsumeETL  WHERE ETLdate=@BeginDate)
	 BEGIN 
	 PRINT N'该日期已经运行'
	 RETURN 1

	 END
	 else
	 begin 
	 insert into CRM_MemberConsumeETL(ETLdate,Result) values(@BeginDate,'begin')
	 end




	declare  @ArchiveDate  datetime =getdate()
	
 delete   cmcih  from   [dbo].[CRM_MemberConsumeInfo_HIS] cmcih where cmcih.ArchiveDate<getdate()-5

  	insert into      CRM_MemberConsumeInfo_his ([ClubCardId]
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
           ,[ETLday]
           ,[Id]
           ,[regdate]
           ,[RetailerId]
           ,[RetailerName]
           ,[ArchiveDate])
 


	    select  [ClubCardId]
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
           ,[ETLday]
           ,[Id]
           ,[regdate]
           ,[RetailerId]
           ,[RetailerName]
           ,@ArchiveDate
       from  CRM_MemberConsumeInfo
	



	--计算出某一时间段会员增量 

	print N'计算出某一时间段会员增量'
	create table   #IncrementClub   
	( clubCardId varchar(50) collate DATABASE_DEFAULT 
	  
	)
	insert into #IncrementClub
	SELECT  distinct  cpt.ClubCardId   FROM Loyalty_Shell_prod..CRM_POSTran CPT 
	left join report_data..store_gs s  on cpt.StoreInternalKey=s.StoreInternalKey and cpt.MatrixMemberId=s.MatrixMemberId
	WHERE CPT.PosDateTime>=CONVERT(date,@BeginDate ,120) and cpt.PosDateTime<=CONVERT(date,@endDate ,120)
	and s.IsVirtualStore=0  
  
   create index IncrementClub  on #IncrementClub(clubCardId)


	-- 会员首次加油时间
	print N'会员首次加油时间'
   create  table  #firstDatetime 
	( clubCardId varchar(50) collate DATABASE_DEFAULT ,
	  firstDateTime nvarchar(10)
	)
	insert into #firstDatetime
	SELECT cpt.ClubCardId, convert(varchar(10),min(cpt.PosDateTime),120) [FirstDateTime]  FROM Loyalty_Shell_prod..CRM_POSTran CPT 
	left join report_data..store_gs s  on cpt.StoreInternalKey=s.StoreInternalKey and cpt.MatrixMemberId=s.MatrixMemberId
	WHERE CPT.PosDateTime>=CONVERT(date,@BeginDate ,120) and cpt.PosDateTime<=CONVERT(date,@endDate ,120)
	and s.IsVirtualStore=0   and cpt.SalesAmount>0 
	group by cpt.ClubCardId

	create index INfirestDate on #firstdatetime(clubCardid)
/*	1.会员光顾次数最多的加油站：
如会员数据中显示有2个或以上的加油站，有相同的加油次数，则：
a.随机选择一个展示
2.在该加油站加油的次数

select * from (select pro_id,img,create_time, ROW_NUMBER() over(partition by pro_id order by  create_time) as row_sort  from product_imgs )
  as t where t.row_sort=1
*/
print N'会员光顾次数最多的加油站'
	create   table   #mostStore 
	( clubCardId varchar(50) collate DATABASE_DEFAULT 
	   ,storeid  nvarchar(10)
	   ,storename nvarchar(100) 
	   ,times int 
	)
	 insert into  #mostStore
	 select  t.ClubCardId ,t.storeid,t.storename,t.FirstStoreTransTimes from  (SELECT cpt.ClubCardId,s.storeid,s.storename
	 , ROW_NUMBER() over (partition by  CPT.ClubCardId order by count(1)  desc ) as number
	 ,count(1)   as  [FirstStoreTransTimes] 
	 FROM Loyalty_Shell_prod..CRM_POSTran CPT 
	 inner  join #IncrementClub c on c.clubCardId=cpt.ClubCardId
	left join report_data..store_gs s  on cpt.StoreInternalKey=s.StoreInternalKey and cpt.MatrixMemberId=s.MatrixMemberId
	WHERE CPT.PosDateTime>=CONVERT(date,@BeginDateFirst ,120) and cpt.PosDateTime<=convert(date,@endDate,120)
	and 	  s.IsVirtualStore=0 
	   group by cpt.ClubCardId,s.storeid,s.storename ) t where  number=1
	create index InmostStroe on #mostStore(clubCardid)
--会员最晚的加油时间
print N'会员最晚的会员最晚的消费时间'
  
	
	SELECT cpt.ClubCardId,  max(substring(convert(varchar(20),cpt.CreatedAt,120),12,8)) lasttime 
	into #lastTime1
	 FROM Loyalty_Shell_prod..CRM_POSTran CPT 
	left join report_data..store_gs s  on cpt.StoreInternalKey=s.StoreInternalKey and cpt.MatrixMemberId=s.MatrixMemberId
	 inner  join #IncrementClub c on c.clubCardId=cpt.ClubCardId
	WHERE CPT.PosDateTime>=CONVERT(date,@BeginDateFirst ,120) and cpt.PosDateTime<=CONVERT(date,@endDate ,120)
	and s.IsVirtualStore=0  
	group by cpt.ClubCardId

	 create index   INlasttime on #lasttime1(clubCardId)

	select  l.ClubCardId,convert(varchar(50),cpt.CreatedAt,120) as lasttime into #lasttime
	 from  #lastTime1 l ,Loyalty_Shell_prod..CRM_POSTran cpt 
	where l.ClubCardId=cpt.ClubCardId and substring(convert(varchar(20),cpt.CreatedAt,120),12,8)=l.lasttime


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
		create index innfrsale1 on ##nfrsale1(clubCardId)
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
		 	  where    ftc.businessDate>=CONVERT(date,@BeginDate ,120) and ftc.businessDate<=CONVERT(date,@EndDate ,120)
	  group by ftcc.CardId,fts.ItemId,ftc.RetailerId,  ftc.StoreId 

	 delete a  from #a  a
	  left join report_data..RetailCode_MP rc  on a.RetailerId=rc.RetailerId
		left join report_data..store_gs store on a.StoreId=store.storeid and rc.MatrixMemberId=store.MatrixMemberId
	 left join  [report_data].[dbo].item_cat  item  on item.MainItemId=a.ItemId and item.MatrixMemberId=rc.MatrixMemberId 
 	   	     where   store.IsVirtualStore=1 or  item.firsttypeCode  like +'''+'10%'+'''
   
    create index inna on #a (CardId)
  
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

     create index Innfrsale on ##nfrsale(clubCardid)
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
		
		create index Infrsale1 on ##frsale1(clubcardId)
SET @curdate=CONVERT(DATE, @beginDate, 120)
      SET @curMonth=CONVERT(VARCHAR(6), CONVERT(DATE, @curdate, 120), 112)

 
   
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
		  
		 where   ftc.businessDate>=CONVERT(date,@BeginDate ,120)  and ftc.businessDate<=CONVERT(date,@EndDate ,120)
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
		   
create index Infralse on ##frsale(ClubCardId)
/*
   1.时间段内用户获得的总优惠金额
1.会员累计加油次数 2.会员累计消费金额3.会员消费排行（所在地区范围，非全国）
*/
	if OBJECT_ID('tempdb..##discountA') is not null 
         drop table ##discounta
        create table  ##discounta
        (
           ClubCardId          NVARCHAR(50) collate DATABASE_DEFAULT 
		  ,TotalFRtimes float
		  ,TotalFRQty  float
		  ,TotalAmount float
		  ,Totaldiscount float 
		  , monthly int
		  ,RetailerId varchar(50)
		  ,StoreId  varchar(50)
		        
        )
		create index Indiscounta on ##discounta(ClubCardId)
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
		 where  ftc.businessDate>=CONVERT(date,@BeginDate ,120) and   ftc.businessDate<=CONVERT(date,@EndDate ,120)	
		   group by ftcc.CardId ,ftc.RetailerId,  ftc.StoreId  
			  

			  	  delete a from #aa  a
			  left join   report_data..RetailCode_MP rc on rc.RetailerId=a.RetailerId
			  left join report_data..store_gs store on  a.StoreId=store.storeid and rc.MatrixMemberId=store.MatrixMemberId
			  where store.IsVirtualStore=1

           insert into ##discountA		
		   select    CardId,
		      sum( totalFRtimes ) as totalFRtimes,sum(FRQty) FRQty ,sum(TotalAmount)  as TotalAmount,sum(TotalDiscount) as TotalDiscount, @curMonth as monthly   
		     ,retailerId,StoreId
		     from #aa
		     group by  CardId ,retailerId,StoreId
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
		  select  n.ClubCardId  --1
		       
		        ,sum(n.TotalDiscount) --2
				,sum(n.TotalFRQty)  --3 
				,sum(n.TotalFRtimes) --4
				,sum(n.TotalAmount)  --5
		      from  ##discounta n 
		   group by n.ClubCardId

;
create index Indiscount on ##discount(ClubCardId)


print N'开始更新历史数据'

	print N'2 会员首次消费时间'
 /* merge into [dbo].[CRM_MemberConsumeInfo]  cmci
 USING ( select * from #firstDatetime ) s
ON   cmci.ClubCardId=s.ClubCardId
WHEN MATCHED and cmci.firstDateTime is null THEN 
    UPDATE  
    SET   firstDateTime  = cmci.firstDateTime  -- 如果存在 那么会员首次消费油站将不更新
WHEN NOT MATCHED THEN 
    INSERT (ClubCardid,firstDateTime) VALUES (clubcardid,firstDateTime);
	*/
	insert into CRM_MemberConsumeInfo
	(ClubCardid,firstDateTime  )
	select  f.clubCardId,f.firstDateTime  from  
	 #firstDatetime f   where not exists (select 1  from CRM_MemberConsumeInfo t  where f.clubCardId=t.ClubCardId)



print N'消费最多油站,消费次数'
merge into [dbo].[CRM_MemberConsumeInfo]  cmci
 
USING ( select * from  #mostStore ) s
ON   cmci.ClubCardId=s.ClubCardId
WHEN MATCHED THEN 
    UPDATE  
    SET  firstStoreCode  = s.storeid
	  	,FistStoreName=s.storename
		,firstStoreTransTimes=s.times
   
WHEN NOT MATCHED THEN 
    INSERT (ClubCardid,firstStoreCode,FistStoreName,firstStoreTransTimes) VALUES (clubcardid,storeid,storename,times);

	/*
print  N'更新光顾最多加油站加油次数.'

	if OBJECT_ID('tempdb..##MaxStoreFrTimes') is not null 
         drop table ##MaxStoreFrTimes
       

		  select n.ClubCardId  --1
		        ,sum(n.TotalFRtimes) totalFrtimes --4
           into    ##MaxStoreFrTimes
			from  ##discounta n , #mostStore s 
			 where   n.ClubCardId=s.clubCardId   and n.StoreId 	 = s.storeid
		   group by n.ClubCardId

;
create index  IndexMaxStoreFrTimes on ##MaxStoreFrTimes(ClubCardId)

merge into  [dbo].[CRM_MemberConsumeInfo] c
  using     ##MaxStoreFrTimes d  on c.ClubCardId=d.ClubCardId 
WHEN MATCHED THEN 
    UPDATE  
    set    
	  firstStoreTransTimes=isnull(firstStoreTransTimes,0)+d.TotalFRtimes  
	 
WHEN NOT MATCHED THEN 
    INSERT (ClubCardId   --1
		,firstStoreTransTimes
	) VALUES ( d.ClubCardId,d.TotalFRtimes    );


*/

print N'更新or add 会员油品消费折扣'

merge into  [dbo].[CRM_MemberConsumeInfo] c
  using ##discount  d  on c.ClubCardId=d.ClubCardId
WHEN MATCHED THEN 
    UPDATE  
    set   c. discount=isnull(c. discount,0)+d.Totaldiscount   
	  ,transTimes=isnull(c.transTimes,0)+d.TotalFRtimes  
	  ,totalConsume=isnull(c.totalConsume,0)+d.TotalAmount
WHEN NOT MATCHED THEN 
    INSERT (ClubCardId   --1
		,discount  --6
	,transTimes  --7
	,totalConsume   --8
	) VALUES ( d.ClubCardId,d.Totaldiscount   ,d.TotalFRtimes    ,d.TotalAmount );

 
 print N'消费v power燃油次数'
  merge into [dbo].[CRM_MemberConsumeInfo]  cmci
 
USING ( select * from  ##frsale ) sale
ON   cmci.ClubCardId=sale.ClubCardId collate Latin1_General_CI_AS_KS 
WHEN MATCHED THEN 
    UPDATE  
    SET frtimes =isnull(frtimes,0)+ sale.totalAmount -- 消费v power燃油次数
,
        frqty = isnull(frqty,0)+sale.totalqty    --消费v power  总加油升数
WHEN NOT MATCHED THEN 
    INSERT (ClubCardid,frtimes,frqty) VALUES ( sale.ClubCardId, sale.totalamount,sale.totalqty);

 --会员在壳牌便利店消费相关数据
 print N'会员在壳牌便利店消费相关数据'
 
  merge into [dbo].[CRM_MemberConsumeInfo]  cmci
 USING ( select * from ##nfrsale ) sale
ON   cmci.ClubCardId=sale.ClubCardId  
WHEN MATCHED THEN 
    UPDATE  
    SET  nframount =isnull(nframount,0)+ sale.totalAmount --  
    ,    nfrqty =isnull(nfrqty,0)+ sale.totalqty    --
WHEN NOT MATCHED THEN 
    INSERT (ClubCardid,nframount,nfrqty) VALUES ( sale.ClubCardId,sale.totalamount,sale.totalqty);

		






print N'3会员最后一次消费时间'



 
update  c set c.LastDatetime=l.lasttime  from  [dbo].[CRM_MemberConsumeInfo]  c,#lasttime l 
where c.ClubCardId=l.clubCardId  --and c.LastDatetime<l.lasttime


insert into [dbo].[CRM_MemberConsumeInfo] 
(ClubCardid,lastDatetime)
select ClubCardid,lasttime from  #lastTime  l
where not exists(select 1  from  [CRM_MemberConsumeInfo] c  where c.ClubCardId=l.clubCardId   )

print N'补充所有会员'

insert into [dbo].[CRM_MemberConsumeInfo] 
(ClubCardid)
select cm.ExternalMemberKey  from  Loyalty_Shell_Prod..CRM_Member cm  
where not exists(select 1  from  [CRM_MemberConsumeInfo] c  where c.ClubCardId=cm.ExternalMemberKey  )



print N'计算所有会员油品消费排序';
  with regcom1 as ( select count(1)  RecCount, rm.compid  from CRM_MemberConsumeInfo d
 left join Loyalty_Shell_prod..CRM_Clubcard cc on d.ClubCardId=cc.ClubCardId 
left join Loyalty_Shell_prod..CRM_Member cm  on cc.MemberInternalKey=cm.MemberInternalKey
left join report_data.[dbo].[v_get_reg_compAndStore]  RM on rm.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
 group by rm.compid )
    
select d.ClubCardId  --1
,ROW_NUMBER() over(  partition by     rm.compid order by d.frqty desc) as orderNumber --4
,  cast(( regcom1.recCount-  ROW_NUMBER() over(  partition by rm.compid order by d.frqty desc))/(regcom1.RecCount*1.00)*100  as decimal(10,2))
   OrderPercent  --5
   into #CRM_MemberConsumeOrder
    from  CRM_MemberConsumeInfo  d
left join Loyalty_Shell_prod..CRM_Clubcard cc on d.ClubCardId=cc.ClubCardId  
left join Loyalty_Shell_prod..CRM_Member cm  on cc.MemberInternalKey=cm.MemberInternalKey
left join report_data.[dbo].[v_get_reg_compAndStore]  RM on rm.BuyingUnitInternalKey=cm.BuyingUnitInternalKey
left join  regcom1 on  regcom1.compid=rm.compid
 where rm.compid is not null
 
 print N'更新所有会员油品消费排序';
 update c set      orderNumber=o.orderNumber,OrderPercent=o.OrderPercent
   from  CRM_MemberConsumeInfo  c ,#CRM_MemberConsumeOrder o
     where o.ClubCardId=c.ClubCardId
   
 
 print N'更新会员jvname  jvcode'

 set @sql=' update a   set a.RegDate=convert(varchar(10),cm.startdate,120),
  a.JVCode=v.compid,a.JVCodeName=v.comp,  RetailerId=rc.RetailerId,RetailerName=rc.Name
 

 from CRM_MemberConsumeInfo  a
   left join Loyalty_Shell_prod..CRM_Clubcard cc on a.ClubCardId=cc.ClubCardId
         left join Loyalty_Shell_prod..CRM_Member cm on cm.MemberInternalKey =cc.MemberInternalKey
 left join report_data..v_get_reg_compAndStore v on v.MemberInternalKey=cc.MemberInternalKey
 left join report_data..RetailCode_MP rc on rc.MatrixMemberId=cc.MatrixMemberId

 '
          SET @sql = Replace(@sql, 'Loyalty_Shell_prod', @loyalty_server);
  print N' update  JVCode=v.compid,a.JVCodeName=v.comp,  RetailerId'
   exec(@sql);
   declare @etlday date =getdate()
   update CRM_MemberConsumeInfo  set ETLday=@etlday;

   UPDATE  CRM_MemberConsumeETL SET Result='END' WHERE ETLdate=@BeginDate
   

END



GO
