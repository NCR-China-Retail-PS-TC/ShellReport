USE [report_data]
GO
/****** Object:  View [dbo].[PromotionHeader_PR]    Script Date: 1/19/2022 9:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[PromotionHeader_PR]
AS
SELECT        pg.PromotionGroupName, pg.ExternalGroupId, ph.MatrixMemberId, ph.PromotionHeaderId, ph.StoreInternalKey, ph.PromotionGroupId, ph.PromotionHeaderDescription, ph.PromotionStatus, ph.PromotionTypeId, 
                         ph.PromotionSubTypeId, ph.PromotionHeaderStartDate, ph.PromotionHeaderEndDate, ph.CyclicHoursRange, ph.StartTime, ph.EndTime, ph.RequiredCoupon, ph.RewardCounterLimition, 
                         ph.ManagerApprovalRequired, ph.MarkdownCategoryKey, ph.BeginTicketPOSTMessageId, ph.EndTicketPOSTMessageId, ph.SponsorSupplierInternalKey, ph.Prorate, ph.RewardPerBucket, ph.ActiveOnSunday, 
                         ph.SundayStartTime, ph.SundayEndTime, ph.ActiveOnMonday, ph.MondayStartTime, ph.MondayEndTime, ph.ActiveOnTuesday, ph.TuesdayStartTime, ph.TuesdayEndTime, ph.ActiveOnWednesday, 
                         ph.WednesdayStartTime, ph.WednesdayEndTime, ph.ActiveOnThursday, ph.ThursdayStartTime, ph.ThursdayEndTime, ph.ActiveOnFriday, ph.FridayStartTime, ph.FridayEndTime, ph.ActiveOnSaturday, 
                         ph.SaturdayStartTime, ph.SaturdayEndTime, ph.Remarks, ph.CreatedBy, ph.CreatedDate, ph.UpdatedBy, ph.UpdatedDate, ph.TCRId, ph.PublicationStatus, ph.PublicationRowVersion, ph.DownloadedAtLeastOnce, 
                         ph.Status, ph.ChangeBatchId, ph.PriceTypeId, ph.AdditionalDescription, ph.InventoryTransactionType, ph.DiscountType, ph.MaxNumOfPayments, ph.SupplierAccountSettling, 
                         ph.RewardCounterAdditionalLimitation, ph.AccrueDiscountBasedOnGrossPrice, ph.PromotionLimitedToItemsEntitledToDiscount, ph.AllTimeRange, ph.DownloadAsActive, ph.PosPromotionTypeId, ph.IsLeveled, 
                         ph.EnableMultiplePromotions, ph.TriggerImmediatelyUponMeetingCondition, ph.MinimumPurchaseAmount, ph.ThresholdContinuityStatus, ph.RedemptionLimitDuringPromotionPeriod, 
                         ph.RedemptionLimitDuringSingleDay, ph.RedemptionLimitDuringSingleTicket, ph.TargetPopulationType, ph.TargetPopulationId, ph.CouponRewardsScope, ph.LimitToHomeStoreOnly, ph.DiscountAllocationFlag, 
                         ph.DiscountAllocationScope, ph.PromotionFundingFlag, ph.PromotionFundingScope, ph.SharedFundingScope, ph.SharedFundingValue, ph.PromotionPriority, ph.DownloadImmediate, ph.AgreementInternalkey, 
                         ph.DistributionStatus, ph.EngineDeterminesConflictParticipation, ph.ExternalReferenceID, ph.LastDownloadDate, ph.SuspendStatus, ph.AdditionalType, ph.CancelDate, ph.PopulationSegmentsOperator, 
                         ph.PopulationLocalSegmentsOperator, ph.PopulationOfflineMode, ph.TicketPrintingScope, ph.PromotionSubPriority, ph.MeanOfPaymentFlag, ph.MeanOfPaymentScope, ph.HomeStoreScope, ph.ActionStatus, 
                         ph.TriggerItemsExcludedFromOtherPromotions, ph.AccountingCode, ph.AccountingSubCode, ph.InstanceInternalKey, ph.MeanOfPaymentTenderId, ph.TicketPrintingText, ph.PromotionReceiptDescription, 
                         ph.SegmentationMode, ph.ReturnItemEligibility, ph.IsManuallyTriggered, ph.SourcePromotionId, ph.RedemptionLimitScope, ph.UOMLimit, ph.UOMLimitType, ph.PromotionFlowStatus, ph.PromotionDraftStatus, 
                         ph.ExcludeItemsWithProhibitDiscount, ph.ExcludeTriggerItemsOfMarkedPromotions, ph.ExportedAtLeastOnce, ph.ExternalValidationRequired, ph.PromotionChecksum, 
                         ph.ExcludeRewardedItemsFromSpendConditionThreshold, ph.PromotionConflictGroupId, ph.LabelDescription, ph.LabelFormat1, ph.LabelFormat2, ph.ApplyPartialRewardWithOptimization, ph.LevelRepetition, 
                         ph.PromotionRewardWillBeDisregardedByOtherPromotions, ph.DisregardRewardOfMarkedPromotions, ph.MissedOffer, ph.RedeemDigitalCoupon, ph.DigitalCouponRequired, ph.CompetitorId, 
                         ph.ManualPriorityValue, ph.OfferProviderName, ph.ExcludeFromPriceCompare, ph.TotalTriggerLimit, ph.CalculatePromotionOnGrossPrice, ph.SourceId, ph.ItemRedemptionConfirmationRequired, 
                         ph.CalculatePromotionPostTax, ISNULL(pauT.BooleanValue, 0) AS PromotionType, ISNULL(pauS.BooleanValue, 0) AS StationCoupon, ISNULL(DOAtrribute.DoubleValue, 0) AS DOShare
FROM            Promotion_Shell.dbo.PromotionHeader AS ph INNER JOIN
                         Promotion_Shell.dbo.PromotionGroup AS pg ON ph.PromotionGroupId = pg.PromotionGroupId AND ph.MatrixMemberId = pg.MatrixMemberId LEFT OUTER JOIN
                         Promotion_Shell.dbo.PromotionAttributeValue AS pauT ON pauT.AttributeId = '10124' AND pauT.PromotionHeaderId = ph.PromotionHeaderId AND ph.MatrixMemberId = pauT.MatrixMemberId LEFT OUTER JOIN
                         Promotion_Shell.dbo.PromotionAttributeValue AS pauS ON pauS.AttributeId = '10129' AND pauS.PromotionHeaderId = ph.PromotionHeaderId AND ph.MatrixMemberId = pauS.MatrixMemberId LEFT OUTER JOIN
                         Promotion_Shell.dbo.PromotionAttributeValue AS DOAtrribute ON DOAtrribute.AttributeId = '10140' AND DOAtrribute.PromotionHeaderId = ph.PromotionHeaderId AND 
                         ph.MatrixMemberId = DOAtrribute.MatrixMemberId
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[18] 4[13] 2[65] 3) )"
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
         Top = -2400
         Left = 0
      End
      Begin Tables = 
         Begin Table = "ph"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 424
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pg"
            Begin Extent = 
               Top = 6
               Left = 462
               Bottom = 136
               Right = 691
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pauT"
            Begin Extent = 
               Top = 138
               Left = 38
               Bottom = 258
               Right = 246
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "pauS"
            Begin Extent = 
               Top = 138
               Left = 530
               Bottom = 258
               Right = 738
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "DOAtrribute"
            Begin Extent = 
               Top = 2022
               Left = 38
               Bottom = 2142
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
      Begin ColumnWidths = 14
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
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
  ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'PromotionHeader_PR'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N' Begin CriteriaPane = 
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'PromotionHeader_PR'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'PromotionHeader_PR'
GO
