USE [report_data]
GO
/****** Object:  StoredProcedure [dbo].[p_ReportAndInterfaceLog]    Script Date: 1/19/2022 9:01:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[p_ReportAndInterfaceLog]
   @ErrorNumber nvarchar(50),
        @ErrorSeverity nvarchar(50),
        @ErrorState nvarchar(50),
        @ErrorProcedure nvarchar(50),
        @ErrorLine nvarchar(50),
        @ErrorMessage nvarchar(50)
as 
begin 
insert into ReportAndInterfaceLog( ErrorNumber,
        ErrorSeverity,
        ErrorState,
        ErrorProcedure,
        ErrorLine,
        ErrorMessage) values(
         @ErrorNumber,
        @ErrorSeverity,
        @ErrorState,
        @ErrorProcedure,
        @ErrorLine,
        @ErrorMessage)
end
GO
