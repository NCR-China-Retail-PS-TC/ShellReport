USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[main_interface_auto_sx]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [dbo].[main_interface_auto_sx]

	AS
BEGIN
 -- exec  [dbo].[est] '2017-06-20','2017-06-22'
	declare @bussiness_date varchar(10),
	@max_datadate varchar(10),
	@datediff int 
	--@RC int

    set @bussiness_date= convert( varchar(10),getdate()-1,120)
	select @max_datadate = max(tsk.DataDate) from report_data..DailyTaskResult tsk where tsk.RetailerId = 2
    select @datediff = DATEDIFF(day,@max_datadate,@bussiness_date)
   --exec  main_interface_etl_sx @bussiness_date
 
	while @datediff - 1 >= 0  --预防某天整个作业都失败的情况
	begin
		set @datediff = @datediff - 1
		set @max_datadate = convert(varchar(10),dateadd(day,1,@max_datadate),120)
		if not exists (select 1 from report_data..DailyTaskResult tsk where tsk.DataDate = @max_datadate and tsk.RetailerId = 2)
		begin

			insert into report_data..DailyTaskResult(RetailerId,TaskType,DataDate,Success)
			select 2, 'ERP',@max_datadate,0 

		end	
	end

	declare dataDate_cur cursor  static
	for select tsk.DataDate
	from report_data..DailyTaskResult tsk
	where tsk.Success = 0 and tsk.RetailerId = 2
	order by tsk.DataDate desc

	open dataDate_cur
	fetch next from dataDate_cur into @bussiness_date

	while @@fetch_STATUS = 0   
	begin
      exec [dbo].[main_interface_etl_sx] @bussiness_date

	  --if @RC = 0
	  --begin
	  -- update report_data..DailyTaskResult
	  -- set Success = 1
	  -- where RetailerId = 2 and DataDate = @bussiness_date
	  -- --print @dataDate + 'aaaaaa'
	  --end
	  --print @dataDate + 'aaaaaa1'
	 	fetch next from dataDate_cur into @bussiness_date
	end

	close dataDate_cur              
	deallocate dataDate_cur
	--print 'dataDate_cur'


                                  
END





GO
