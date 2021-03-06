USE [report_data]
GO
/****** Object:  View [dbo].[View_different_amount]    Script Date: 1/19/2022 9:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*	  select    *
   from atd_shell..FO_TranHeader201704 fth where fth.TranId=435534
   select   *
   from atd_shell..FO_TranTender201704 fth where fth.TicketInternalKey=2785
      select  *
	  from atd_shell..FO_TranSale201704 fts  where fts.TicketInternalKey in (2785)
	  select  *
	  from atd_shell..FO_TranTender201704 fts  where fts.TicketInternalKey in (3009)  */
CREATE VIEW [dbo].[View_different_amount]
AS
SELECT fth.TranId, fth.StartDateTime, b.total AS headmount, b.oil + b.noil AS saleamount, fth.Discount, 
     ftt1.amount AS tenderAmount
FROM (SELECT TicketInternalKey, SUM(totalamount) AS total, SUM(oil) AS oil, SUM(Noil) AS noil, 
            SUM(totalamount - Noil) AS sum_oil
      FROM (SELECT fth.TicketInternalKey, fth.TotalAmount + fth.Discount AS totalamount, 0 AS oil, 
                  0 AS Noil
            FROM ATD_Shell.dbo.FO_TranHeader201704 AS fth INNER JOIN
                  ATD_Shell.dbo.FO_TranCollection AS ftc ON 
                  fth.CollectionInternalKey = ftc.CollectionInternalKey
            UNION ALL
            SELECT TicketInternalKey, 0 AS Expr1, SUM(CASE WHEN fts.ItemId IN ('1000', '1002') 
                 THEN fts.Amount ELSE 0 END) AS amount_oil, 
                 SUM(CASE WHEN fts.ItemId NOT IN ('1000', '1002') THEN fts.Amount ELSE 0 END) 
                 AS amount_n
            FROM ATD_Shell.dbo.FO_TranSale201704 AS fts
            GROUP BY TicketInternalKey) AS a
      GROUP BY TicketInternalKey) AS b LEFT OUTER JOIN
     ATD_Shell.dbo.FO_TranHeader201704 AS fth ON 
     b.TicketInternalKey = fth.TicketInternalKey LEFT OUTER JOIN
         (SELECT TicketInternalKey, SUM(Amount) AS amount
       FROM ATD_Shell.dbo.FO_TranTender201704 AS ftt
       GROUP BY TicketInternalKey) AS ftt1 ON ftt1.TicketInternalKey = b.TicketInternalKey
WHERE (b.oil <> b.sum_oil) OR
     (b.total <> ftt1.amount + fth.Discount)
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[18] 4[5] 2[60] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "fth"
            Begin Extent = 
               Top = 6
               Left = 256
               Bottom = 136
               Right = 484
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ftt1"
            Begin Extent = 
               Top = 6
               Left = 522
               Bottom = 102
               Right = 702
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "b"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 126
               Right = 246
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_different_amount'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_different_amount'
GO
