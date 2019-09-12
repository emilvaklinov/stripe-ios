//
//  STPBankSelectionViewController.m
//  Stripe
//
//  Created by David Estes on 8/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPBankSelectionViewController.h"

#import "NSArray+Stripe.h"
#import "STPAPIClient+Private.h"
#import "STPColorUtils.h"
#import "STPCoreTableViewController+Private.h"
#import "STPDispatchFunctions.h"
#import "STPImageLibrary+Private.h"
#import "STPLocalizationUtils.h"
#import "STPSectionHeaderView.h"
#import "STPBankSelectionTableViewCell.h"
#import "STPPaymentMethodParams.h"
#import "STPPaymentMethodFPXParams.h"
#import "UIBarButtonItem+Stripe.h"
#import "UINavigationBar+Stripe_Theme.h"
#import "UITableViewCell+Stripe_Borders.h"
#import "UIViewController+Stripe_NavigationItemProxy.h"

static NSString *const STPBankSelectionCellReuseIdentifier = @"STPBankSelectionCellReuseIdentifier";

@interface STPBankSelectionViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) STPAPIClient *apiClient;
@property (nonatomic) STPBankType bankType;
@property (nonatomic) STPFPXBankBrand selectedBank;
@property (nonatomic) STPPaymentConfiguration *configuration;
@property (nonatomic, weak) UIImageView *imageView;
@property (nonatomic) STPSectionHeaderView *headerView;
@property (nonatomic) BOOL loading;
@end

@implementation STPBankSelectionViewController

- (instancetype)initWithBankType:(STPBankType)bankType
                   configuration:(STPPaymentConfiguration *)configuration
                           theme:(STPTheme *)theme {
    self = [super initWithTheme:theme];
    if (self) {
        _bankType = bankType;
        _configuration = configuration;
        _selectedBank = STPFPXBankBrandUnknown;
        _apiClient = [[STPAPIClient alloc] initWithConfiguration:configuration];
        self.title = STPLocalizedString(@"Bank Account", @"Title for bank account selector");
    }
    return self;
}

- (void)createAndSetupViews {
    [super createAndSetupViews];

    [self.tableView registerClass:[STPBankSelectionTableViewCell class] forCellReuseIdentifier:STPBankSelectionCellReuseIdentifier];

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[STPImageLibrary largeFpxLogo]];
    imageView.contentMode = UIViewContentModeCenter;
    imageView.frame = CGRectMake(0, 0, self.view.bounds.size.width, imageView.bounds.size.height + (57 * 2));
    self.imageView = imageView;

    self.tableView.tableHeaderView = imageView;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    STPSectionHeaderView *headerView = [STPSectionHeaderView new];
    headerView.theme = self.theme;
    headerView.buttonHidden = YES;
    headerView.title = STPLocalizedString(@"Bank Account", @"Label for bank account selection form");
    [headerView setNeedsLayout];
    self.headerView = headerView;
}

- (void)updateAppearance {
    [super updateAppearance];
    
    self.tableView.allowsSelection = YES;

    self.imageView.tintColor = self.theme.accentColor;
    [self.tableView reloadData];
}

- (BOOL)useSystemBackButton {
    return YES;
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(__unused NSInteger)section {
    return STPFPXBankBrandUnknown;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    STPBankSelectionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:STPBankSelectionCellReuseIdentifier forIndexPath:indexPath];
    STPFPXBankBrand bankBrand = indexPath.row;
    BOOL selected = self.selectedBank == bankBrand;
    [cell configureWithBank:bankBrand theme:self.theme selected:selected enabled:!self.loading];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL topRow = (indexPath.row == 0);
    BOOL bottomRow = ([self tableView:tableView numberOfRowsInSection:indexPath.section] - 1 == indexPath.row);
    [cell stp_setBorderColor:self.theme.tertiaryBackgroundColor];
    [cell stp_setTopBorderHidden:!topRow];
    [cell stp_setBottomBorderHidden:!bottomRow];
    [cell stp_setFakeSeparatorColor:self.theme.quaternaryBackgroundColor];
    [cell stp_setFakeSeparatorLeftInset:15.0f];
}

- (CGFloat)tableView:(__unused UITableView *)tableView heightForFooterInSection:(__unused NSInteger)section {
    return 27.0f;
}

- (CGFloat)tableView:(__unused UITableView *)tableView heightForHeaderInSection:(__unused NSInteger)section {
    CGSize size = [self.headerView sizeThatFits:CGSizeMake(self.view.bounds.size.width, CGFLOAT_MAX)];
    return size.height;
}

- (UIView *)tableView:(__unused UITableView *)tableView viewForHeaderInSection:(__unused NSInteger)section {
    return self.headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.loading) {
        return; // Don't allow user interaction if we're currently setting up a payment method
    }
    self.loading = YES;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSUInteger bankIndex = indexPath.row;
    self.selectedBank = bankIndex;
    [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]
             withRowAnimation:UITableViewRowAnimationNone];
    
    STPPaymentMethodFPXParams *fpx = [[STPPaymentMethodFPXParams alloc] init];
    fpx.bank = bankIndex;
    // Create and return a Payment Method Params object
    STPPaymentMethodParams *paymentMethodParams = [STPPaymentMethodParams paramsWithFPX:fpx
                                                                          billingDetails:nil
                                                                                metadata:nil];
    if ([self.delegate respondsToSelector:@selector(bankSelectionViewController:didCreatePaymentMethodParams:completion:)]) {
        [self.delegate bankSelectionViewController:self didCreatePaymentMethodParams:paymentMethodParams completion:^() {
            stpDispatchToMainThreadIfNecessary(^{
                self.loading = NO;
                self.selectedBank = STPFPXBankBrandUnknown;
            });
        }];
    }
}

@end
