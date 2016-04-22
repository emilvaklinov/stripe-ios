//
//  STPAddressFieldTableViewCell.m
//  Stripe
//
//  Created by Ben Guo on 4/13/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPAddressFieldTableViewCell.h"
#import "STPFormTextField.h"
#import "UIColor+Stripe.h"
#import "STPPostalCodeValidator.h"
#import "STPPhoneNumberValidator.h"
#import "STPEmailAddressValidator.h"

@interface STPAddressFieldTableViewCell() <STPFormTextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property(nonatomic, weak) UILabel *captionLabel;
@property(nonatomic, weak) STPFormTextField *textField;
@property(nonatomic) UIToolbar *inputAccessoryToolbar;
@property(nonatomic) UIPickerView *countryPickerView;
@property(nonatomic, strong) NSArray *countryCodes;
@property(nonatomic, weak)id<STPAddressFieldTableViewCellDelegate>delegate;

@end

@implementation STPAddressFieldTableViewCell

- (instancetype)initWithType:(STPAddressFieldType)type
                    contents:(NSString *)contents
                  lastInList:(BOOL)lastInList
                    delegate:(id<STPAddressFieldTableViewCellDelegate>)delegate {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    if (self) {
        _delegate = delegate;
        
        UILabel *captionLabel = [UILabel new];
        captionLabel.textColor = [UIColor stp_fieldLabelGreyColor];
        _captionLabel = captionLabel;
        [self addSubview:captionLabel];
        
        STPFormTextField *textField = [[STPFormTextField alloc] init];
        textField.formDelegate = self;
        textField.autoFormattingBehavior = STPFormTextFieldAutoFormattingBehaviorNone;
        textField.placeholderColor = [UIColor stp_fieldPlaceholderGreyColor];
        textField.textColor = [UIColor stp_darkTextColor];
        textField.errorColor = [UIColor redColor]; // TODO make better
        _textField = textField;
        [self addSubview:textField];
        
        UIToolbar *toolbar = [UIToolbar new];
        UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *nextItem = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStyleDone target:self action:@selector(nextTapped:)];
        toolbar.items = @[flexibleItem, nextItem];
        _inputAccessoryToolbar = toolbar;
        
        NSString *countryCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
        NSMutableArray *otherCountryCodes = [[NSLocale ISOCountryCodes] mutableCopy];
        [otherCountryCodes removeObject:countryCode];
        _countryCodes = [@[@"", countryCode] arrayByAddingObjectsFromArray:otherCountryCodes];
        UIPickerView *pickerView = [UIPickerView new];
        pickerView.dataSource = self;
        pickerView.delegate = self;
        _countryPickerView = pickerView;
        
        self.type = type;
        self.textField.text = contents;
        switch (type) {
            case STPAddressFieldTypeName:
                self.captionLabel.text = NSLocalizedString(@"Name", nil);
                self.textField.placeholder = NSLocalizedString(@"John Appleseed", nil);
                self.textField.keyboardType = UIKeyboardTypeDefault;
                break;
            case STPAddressFieldTypeLine1:
                self.captionLabel.text = NSLocalizedString(@"Address", nil);
                self.textField.placeholder = NSLocalizedString(@"123 Address St", nil);
                self.textField.keyboardType = UIKeyboardTypeDefault;
                break;
            case STPAddressFieldTypeLine2:
                self.captionLabel.text = NSLocalizedString(@"Apt.", nil);
                self.textField.placeholder = NSLocalizedString(@"#23", nil);
                self.textField.keyboardType = UIKeyboardTypeDefault;
                break;
            case STPAddressFieldTypeCity:
                self.captionLabel.text = NSLocalizedString(@"City", nil);
                self.textField.placeholder = NSLocalizedString(@"California", nil);
                self.textField.keyboardType = UIKeyboardTypeDefault;
                break;
            case STPAddressFieldTypeState:
                self.captionLabel.text = NSLocalizedString(@"State", nil);
                self.textField.placeholder = NSLocalizedString(@"CA", nil);
                self.textField.keyboardType = UIKeyboardTypeDefault;
                break;
            case STPAddressFieldTypeZip:
                self.captionLabel.text = NSLocalizedString(@"ZIP Code", nil);
                self.textField.placeholder = NSLocalizedString(@"12345", nil);
                self.textField.keyboardType = UIKeyboardTypeNumberPad;
                if (!lastInList) {
                    self.textField.inputAccessoryView = self.inputAccessoryToolbar;
                }
                break;
            case STPAddressFieldTypeCountry:
                self.captionLabel.text = NSLocalizedString(@"Country", nil);
                self.textField.placeholder = nil;
                self.textField.keyboardType = UIKeyboardTypeDefault;
                self.textField.keyboardType = UIKeyboardTypeDefault;
                self.textField.inputView = self.countryPickerView;
                NSInteger index = [self.countryCodes indexOfObject:self.contents];
                if (index == NSNotFound) {
                    self.textField.text = @"";
                }
                else {
                    [self.countryPickerView selectRow:index inComponent:0 animated:NO];
                }
                break;
            case STPAddressFieldTypePhone:
                self.textField.keyboardType = UIKeyboardTypePhonePad;
                self.textField.autoFormattingBehavior = STPFormTextFieldAutoFormattingBehaviorPhoneNumbers;
                if (!lastInList) {
                    self.textField.inputAccessoryView = self.inputAccessoryToolbar;
                }
                break;
            case STPAddressFieldTypeEmail:
                self.textField.keyboardType = UIKeyboardTypeEmailAddress;
                break;
                
        }
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.captionLabel.frame = CGRectMake(15, 0, 80, self.bounds.size.height);
    CGFloat textFieldX = CGRectGetMaxX(self.captionLabel.frame) + 10;
    self.textField.frame = CGRectMake(textFieldX, 0, self.bounds.size.width - textFieldX, self.bounds.size.height);
    self.inputAccessoryToolbar.frame = CGRectMake(0, 0, self.bounds.size.width, 44);
}

- (BOOL)becomeFirstResponder {
    return [self.textField becomeFirstResponder];
}

- (void)nextTapped:(__unused id)sender {
    [self.delegate addressFieldTableViewCellDidReturn:self];
}

#pragma mark - STPFormTextFieldDelegate

- (void)formTextFieldTextDidChange:(STPFormTextField *)textField {
    if (self.type != STPAddressFieldTypeCountry) {
        self.contents = textField.text;
    }
    [self.delegate addressFieldTableViewCellDidUpdateText:self];
}

- (BOOL)textFieldShouldReturn:(__unused UITextField *)textField {
    [self.delegate addressFieldTableViewCellDidReturn:self];
    return NO;
}

- (void)formTextFieldDidBackspaceOnEmpty:(__unused STPFormTextField *)formTextField {
    [self.delegate addressFieldTableViewCellDidBackspaceOnEmpty:self];
}

- (void)setContents:(NSString *)contents {
    _contents = contents;
    self.textField.validText = [self validContents];
}

- (BOOL)validContents {
    switch (self.type) {
        case STPAddressFieldTypeName:
        case STPAddressFieldTypeLine1:
        case STPAddressFieldTypeCity:
        case STPAddressFieldTypeState:
        case STPAddressFieldTypeCountry:
            return self.contents.length > 0;
        case STPAddressFieldTypeLine2:
            return YES;
        case STPAddressFieldTypeZip:
            return [STPPostalCodeValidator stringIsValidPostalCode:self.contents];
        case STPAddressFieldTypeEmail:
            return [STPEmailAddressValidator stringIsValidEmailAddress:self.contents];
        case STPAddressFieldTypePhone:
            return [STPPhoneNumberValidator stringIsValidPhoneNumber:self.contents];
    }
}

#pragma mark - UIPickerView

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.contents = self.countryCodes[row];
    self.textField.text = [self pickerView:pickerView titleForRow:row forComponent:component];
}

- (NSString *)pickerView:(__unused UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(__unused NSInteger)component {
    NSString *countryCode = self.countryCodes[row];
    NSString *identifier = [NSLocale localeIdentifierFromComponents:[NSDictionary dictionaryWithObject:countryCode forKey: NSLocaleCountryCode]];
    return [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:identifier];
}

- (NSInteger)numberOfComponentsInPickerView:(__unused UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(__unused UIPickerView *)pickerView numberOfRowsInComponent:(__unused NSInteger)component {
    return self.countryCodes.count;
}

@end