USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[CrossJV]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Ryan Liang
-- Create date: 2019.8.1
-- Description:	Create Cross JV Report
-- Version: 1.0.1
-- =============================================
/*
	exec CrossJV 0, '2019/12/9'
	exec CrossJV 0, '2019/12/10'
	exec CrossJV 0, '2019/12/11'
*/

CREATE procedure [dbo].[CrossJV] 
(
	@MatrixMemberId int,  --0 = all retailer
	@BussinessDate  datetime
)
as
    begin
        set nocount on;
        declare @cMatrixMemberId int, @MatrixMemberName nvarchar(50), @ExtractLocalPath nvarchar(200);
        declare @path nvarchar(1000);

        declare configCursor cursor
        for select MatrixMemberId, 
                   MatrixMemberName, 
                   ExtractLocalPath
            from report_data..extractReportConfig
            where MatrixMemberId != 0
			  and MatrixMemberId = case when @MatrixMemberId = 0 then MatrixMemberId else @MatrixMemberId end
            order by MatrixMemberId;

        open configCursor;
        fetch next from configCursor into @cMatrixMemberId, @MatrixMemberName, @ExtractLocalPath;
        while @@FETCH_STATUS = 0
            begin
                /*** R1 本JV会员在外JV发放积分 ***/
                exec CrossJV_Reward @cMatrixMemberId, @BussinessDate, 1
                set @path = @ExtractLocalPath + N'Cross_JV\R54_1_CrossJV_(Daily)_' + convert(varchar(10), @BussinessDate, 120) + '.csv';
                exec report_data.[dbo].est_export_cvs 'CrossJVTemp', '', @path;

				/*** R2 本JV会员在外JV兑换 ***/
				exec CrossJV_Redeem @cMatrixMemberId, @BussinessDate, 1
                set @path = @ExtractLocalPath + 'Cross_JV\R54_2_CrossJV_(Daily)_' + convert(varchar(10), @BussinessDate, 120) + '.csv';
                exec report_data.[dbo].est_export_cvs 'CrossJVTemp', '', @path;
				
				/*** R3 外JV会员在本JV交易发放 ***/
                exec CrossJV_Reward @cMatrixMemberId, @BussinessDate, 0
                set @path = @ExtractLocalPath + 'Cross_JV\R54_3_CrossJV_(Daily)_' + convert(varchar(10), @BussinessDate, 120) + '.csv';
                exec report_data.[dbo].est_export_cvs 'CrossJVTemp', '', @path;

				/*** R4 外JV会员在本JV交易兑换 ***/
				exec CrossJV_Redeem @cMatrixMemberId, @BussinessDate, 0
                set @path = @ExtractLocalPath + 'Cross_JV\R54_4_CrossJV_(Daily)_' + convert(varchar(10), @BussinessDate, 120) + '.csv';
                exec report_data.[dbo].est_export_cvs 'CrossJVTemp', '', @path;

				/*** R5 跨JV交易月度报告 ***/
				exec CrossJV_Summary @cMatrixMemberId, @BussinessDate
				set @path = @ExtractLocalPath + 'Cross_JV\R54_5_CrossJV_' + convert(varchar(10), @BussinessDate, 120) + '.csv';
                exec report_data.[dbo].est_export_cvs 'CrossJVTemp_Summary', '', @path;

                /*** R6 优惠券跨JV报告 ***/
				exec CrossJV_Document @cMatrixMemberId, @BussinessDate
				set @path = @ExtractLocalPath + 'Cross_JV\R54_6_CrossJV_' + convert(varchar(10), @BussinessDate, 120) + '.csv';
                exec report_data.[dbo].est_export_cvs 'CrossJVTemp_Document', '', @path;

                /*** R7 会籍转移 ***/
                exec CrossJV_Member @cMatrixMemberId, @BussinessDate
				set @path = @ExtractLocalPath + 'Cross_JV\R54_7_CrossJV_' + convert(varchar(10), @BussinessDate, 120) + '.csv';
                exec report_data.[dbo].est_export_cvs 'CrossJVTemp_Member', '', @path;

                fetch next from configCursor into @cMatrixMemberId, @MatrixMemberName, @ExtractLocalPath;
            end;
        close configCursor;
        deallocate configCursor;

        select 'CrossJV Generation Finish !'
    end;

GO
