import { LightningElement, track, wire } from 'lwc';
import getZipCodeDetails from '@salesforce/apex/ZipCodeController.getZipCodeDetails';
import getNonUSLogs from '@salesforce/apex/ZipCodeController.getNonUSLogs';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class ZipLookupParent extends LightningElement {
    @track selectedCountryOption = 'us';
    @track customCountryCode = '';
    @track zipCode = '';
    @track zipData;
    @track isLoading = false;
    @track isUS = false;
    @track isNonUS = false;
    @track errorMessage = '';
    @track logs = [];

    wiredLogsResult;

    countryOptions = [
        { label: 'United States', value: 'us' },
        { label: 'Mexico', value: 'mx' },
        { label: 'Canada', value: 'ca' },
        { label: 'Germany', value: 'de' },
        { label: 'Other (Enter ISO Code)', value: 'OTHER' }
    ];

    logColumns = [
        { label: 'Zip Code', fieldName: 'ZipCode__c' },
        { label: 'Country', fieldName: 'Country__c' },
        { label: 'State', fieldName: 'State__c' },
        { label: 'Place Name', fieldName: 'Place_Name__c' },
        { label: 'Created Date', fieldName: 'CreatedDate', type: 'date' }
    ];

    get isCustomCountry() {
        return this.selectedCountryOption === 'OTHER';
    }

    get zipColumnClass() {
        return this.isCustomCountry
            ? 'slds-col slds-size_1-of-1 slds-medium-size_1-of-3'
            : 'slds-col slds-size_1-of-1 slds-medium-size_2-of-3';
    }

    get activeCountryCode() {
        if (this.isCustomCountry) {
            return this.customCountryCode ? this.customCountryCode.trim().toLowerCase() : '';
        }
        return this.selectedCountryOption;
    }

    @wire(getNonUSLogs)
    wiredLogs(result) {
        this.wiredLogsResult = result;
        if (result.data) {
            this.logs = result.data;
        } else if (result.error) {
            this.showToast('Error', 'Failed to load non-US logs', 'error');
        }
    }

    handleCountryOptionChange(event) {
        this.selectedCountryOption = event.detail.value;
        if (!this.isCustomCountry) {
            this.customCountryCode = '';
        }
    }

    handleCustomCountryChange(event) {
        this.customCountryCode = event.detail.value;
    }

    handleZipChange(event) {
        this.zipCode = event.detail.value;
    }

    async handleSearch() {
        const countryToUse = this.activeCountryCode;
        this.isLoading = true;
        this.errorMessage = '';
        this.isUS = false;
        this.isNonUS = false;
        this.zipData = null;

        if (!countryToUse || countryToUse.length !== 2) {
            this.errorMessage = 'Please enter a valid 2-letter country code.';
            this.isLoading = false;
            return;
        }

        if (!this.zipCode) {
            this.errorMessage = 'Please enter a zip code.';
            this.isLoading = false;
            return;
        }

        try {
            const data = await getZipCodeDetails({ countryCode: countryToUse, zipCode: this.zipCode });

            if (data.countryAbbreviation === 'US') {
                this.isUS = true;
                this.zipData = data;
            } else {
                this.isNonUS = true;
                await refreshApex(this.wiredLogsResult);
            }
        } catch (error) {
            // Extract custom Apex error string
            let msg = 'An unknown error occurred.';
            if (error && error.body && typeof error.body.message === 'string') {
                msg = error.body.message;
            } else if (error && error.message) {
                msg = error.message;
            }

            // Set both the inline banner text AND attempt to fire the toast
            this.errorMessage = msg;
            this.showToast('Search Error', msg, 'error');
        } finally {
            this.isLoading = false;
        }
    }


    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}