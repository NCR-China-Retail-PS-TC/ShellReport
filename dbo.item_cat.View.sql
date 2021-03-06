USE [report_data]
GO
/****** Object:  View [dbo].[item_cat]    Script Date: 1/19/2022 9:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  VIEW [dbo].[item_cat]
AS
SELECT item.MatrixMemberId, item.MainItemId, itemh.Id AS threeType, item.FullName, itemh.Description AS hi, 
     itemh.CategoryKey, itemf.Id AS midtypeCode, itemf.Description AS midtype, 
     itemff.Description AS firsttype, itemff.Id AS firsttypeCode, itemff.HierarchyLevel AS level3, 
     itemff0.Description AS first0type, itemff0.Id AS first0typeCode, itemff0.HierarchyLevel AS level4, 
     item.ItemInternalKey, IAV181.StringValue AS ItemType, IAV429.StringValue AS taxCode, 
     IAV10134.StringValue AS sku, item.CreatedDate, item.UpdatedDate
FROM ATD_Shell.dbo.ItemInfo_HOST AS item LEFT OUTER JOIN
     MP_Shell.dbo.ItemHierarchyTemplateLine_ALL AS itemh ON 
     item.MainCategoryKey = itemh.CategoryKey AND 
     item.MatrixMemberId = itemh.MatrixMemberId LEFT OUTER JOIN
     MP_Shell.dbo.ItemHierarchyTemplateLine_ALL AS itemf ON itemh.ParentId = itemf.CategoryKey AND 
     itemh.MatrixMemberId = itemf.MatrixMemberId LEFT OUTER JOIN
     MP_Shell.dbo.ItemHierarchyTemplateLine_ALL AS itemff ON itemf.ParentId = itemff.CategoryKey AND 
     itemf.MatrixMemberId = itemff.MatrixMemberId LEFT OUTER JOIN
     MP_Shell.dbo.ItemHierarchyTemplateLine_ALL AS itemff0 ON 
     itemff.ParentId = itemff0.CategoryKey AND 
     itemff0.MatrixMemberId = itemff.MatrixMemberId LEFT OUTER JOIN
     HOST_Shell_UAT.dbo.ItemAttributeValue AS IAV181 ON 
     IAV181.MatrixMemberId = item.MatrixMemberId AND 
     item.ItemInternalKey = IAV181.ItemInternalKey AND IAV181.AttributeId = '181' LEFT OUTER JOIN
     HOST_Shell_UAT.dbo.ItemAttributeValue AS IAV429 ON 
     IAV429.MatrixMemberId = item.MatrixMemberId AND 
     item.ItemInternalKey = IAV429.ItemInternalKey AND IAV429.AttributeId = '429' LEFT OUTER JOIN
     HOST_Shell_UAT.dbo.ItemAttributeValue AS IAV10134 ON 
     IAV10134.MatrixMemberId = item.MatrixMemberId AND 
     item.ItemInternalKey = IAV10134.ItemInternalKey AND IAV10134.AttributeId = '10146'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[8] 4[25] 2[44] 3) )"
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
         Top = -192
         Left = 0
      End
      Begin Tables = 
         Begin Table = "item"
            Begin Extent = 
               Top = 126
               Left = 312
               Bottom = 246
               Right = 611
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "itemh"
            Begin Extent = 
               Top = 6
               Left = 270
               Bottom = 126
               Right = 506
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "itemf"
            Begin Extent = 
               Top = 6
               Left = 544
               Bottom = 126
               Right = 780
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "itemff"
            Begin Extent = 
               Top = 126
               Left = 38
               Bottom = 246
               Right = 274
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "itemff0"
            Begin Extent = 
               Top = 246
               Left = 38
               Bottom = 376
               Right = 249
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "IAV181"
            Begin Extent = 
               Top = 246
               Left = 287
               Bottom = 376
               Right = 498
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "IAV429"
            Begin Extent = 
               Top = 246
               Left = 536
               Bottom = 376
               Right = 747
            End
            DisplayFlags = 280
      ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'item_cat'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'      TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 10
         Width = 284
         Width = 1500
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'item_cat'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'item_cat'
GO
