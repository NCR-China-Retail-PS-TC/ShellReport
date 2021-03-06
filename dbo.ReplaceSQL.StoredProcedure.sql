USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[ReplaceSQL]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Ryan Liang
-- Create date: 2020.1.9
-- Description:	Replace Database Name in SQL statement
-- =============================================
CREATE procedure [dbo].[ReplaceSQL] 
(
	@Sql  nvarchar(max),
	@Date datetime,
    @_Sql nvarchar(max) output)
as
    begin
        set nocount on;
        declare @dbKey nvarchar(60), @dbName nvarchar(60);
        declare cursor_dbnames cursor
        for 
			select dbKey, dbName
              from report_data..dbNames;
        open cursor_dbnames;

        fetch next from cursor_dbnames into @dbKey, @dbName;
        while @@FETCH_STATUS = 0
            begin
				set @Sql = Replace(@Sql, @dbKey, @dbName);
                fetch next from cursor_dbnames into @dbKey, @dbName;
            end;
        close cursor_dbnames;
        deallocate cursor_dbnames;
		
		select @_Sql = Replace(@Sql, '#YYYYMM#', convert(char(6), @Date, 112));
    end;




GO
