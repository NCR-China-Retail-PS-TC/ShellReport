USE [report_data]
GO
/****** Object:  View [dbo].[store_gs]    Script Date: 1/19/2022 9:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[store_gs]
AS
SELECT        s.MatrixMemberId, s.StoreInternalKey, s.Id AS storeid, s.NodeDescription AS storename, sa.StringValue AS city, t.NodeDescription AS comp, t.Id AS compID, st.StoreIsActive, sa118.LongValue AS DoBusinessCode, 
                         ISNULL(sa117.StringValue, '') AS StoreType, ss.sku, ss.ItemName, ISNULL(sa10133.BooleanValue, 0) AS IsVirtualStore, ISNULL(sa10139.LongValue, 0) AS StoreShare
FROM            ATD_Shell.dbo.StoreHierarchy_ALL AS s LEFT OUTER JOIN
                         ATD_Shell.dbo.StoreHierarchy_ALL AS t ON t.MatrixMemberId = s.MatrixMemberId AND t.StoreHierarchyKey = s.ParentId LEFT OUTER JOIN
                         HOST_Shell_UAT.dbo.StoreAttributeValue AS sa ON s.StoreInternalKey = sa.StoreInternalKey AND sa.AttributeId = '109' AND s.MatrixMemberId = sa.MatrixMemberId LEFT OUTER JOIN
                         HOST_Shell_UAT.dbo.Store AS st ON st.MatrixMemberId = s.MatrixMemberId AND s.StoreInternalKey = st.StoreInternalKey LEFT OUTER JOIN
                         HOST_Shell_UAT.dbo.StoreAttributeValue AS sa118 ON s.StoreInternalKey = sa118.StoreInternalKey AND sa118.AttributeId = '118' AND s.MatrixMemberId = sa118.MatrixMemberId LEFT OUTER JOIN
                         HOST_Shell_UAT.dbo.StoreAttributeValue AS sa117 ON s.StoreInternalKey = sa117.StoreInternalKey AND sa117.AttributeId = '117' AND s.MatrixMemberId = sa117.MatrixMemberId LEFT OUTER JOIN
                         HOST_Shell_UAT.dbo.StoreAttributeValue AS sa10133 ON s.StoreInternalKey = sa10133.StoreInternalKey AND sa10133.AttributeId = '10133' AND s.MatrixMemberId = sa10133.MatrixMemberId LEFT OUTER JOIN
                         dbo.store_sku AS ss ON ss.Storeid = t.Id AND t.MatrixMemberId = ss.MatrixMemberId LEFT OUTER JOIN
                         HOST_Shell_UAT.dbo.StoreAttributeValue AS sa10139 ON s.StoreInternalKey = sa10139.StoreInternalKey AND sa10139.AttributeId = '10139' AND s.MatrixMemberId = sa10139.MatrixMemberId
WHERE        (s.HierarchyLevel = 2) AND (s.ViewId = 0)
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[30] 4[8] 2[56] 3) )"
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
         Top = -288
         Left = 0
      End
      Begin Tables = 
         Begin Table = "s"
            Begin Extent = 
               Top = 126
               Left = 38
               Bottom = 246
               Right = 281
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 126
               Right = 281
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "sa"
            Begin Extent = 
               Top = 294
               Left = 38
               Bottom = 424
               Right = 215
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "st"
            Begin Extent = 
               Top = 414
               Left = 253
               Bottom = 544
               Right = 529
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "sa118"
            Begin Extent = 
               Top = 294
               Left = 600
               Bottom = 424
               Right = 777
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "sa117"
            Begin Extent = 
               Top = 426
               Left = 38
               Bottom = 556
               Right = 215
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "sa10133"
            Begin Extent = 
               Top = 426
               Left = 567
               Bottom = 556
               Right = 744
            End
            DisplayFlags = 280
            TopColumn ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'store_gs'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'= 0
         End
         Begin Table = "ss"
            Begin Extent = 
               Top = 294
               Left = 368
               Bottom = 414
               Right = 562
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "sa10139"
            Begin Extent = 
               Top = 546
               Left = 253
               Bottom = 676
               Right = 430
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
         Width = 2400
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'store_gs'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'store_gs'
GO
