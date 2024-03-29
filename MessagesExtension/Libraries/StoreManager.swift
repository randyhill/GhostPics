//
//  AppStore.swift
//  Super Keyboard Project
//
//  Created by CRH on 5/13/15.
//  Copyright (c) 2015 CRH. All rights reserved.
//

import Foundation
import UIKit
import StoreKit


let kInAppTransactionKey = "IAP_TransactionKey"
let kInAppProductKey = "IAP_ProductKey"
let kActivationKey = "nvariance.ghostpics.activation"

// Notifications
let kInAppRestoreNotification = "kInAppRestoreNotification"
let kInAppRestoreFailNotification = "kInAppRestoreFailNotification"
let kInAppPurchaseFailNotification = "kInAppPurchaseFailNotification"

enum PurchaseError: Int {
    case Success = 0,		// No error.
    NotAuthorized,			// Device wasn't authorized for purchases..
    ProductIDNotFound		// Product ID not found.
}

class StoreManager : NSObject, SKPaymentTransactionObserver, SKProductsRequestDelegate {
    var productIdentifiers: NSSet?
    var productsList = [SKProduct]()
    var productsRequest : SKProductsRequest?
    var expiration : NSDate?

//--------------------------------- Singletons -----------------------------------
    class var sharedInstance : StoreManager {
        struct Singleton {
            static let instance = StoreManager()
        }
        let existingInstance = Singleton.instance
        return existingInstance
    }

// Get upgrade data
    func  requestProductPricingInfo() {
        productIdentifiers = NSSet(objects: kActivationKey)
        if let prodID = productIdentifiers as? Set<String> {
            let productsRequest = SKProductsRequest(productIdentifiers: prodID)
            productsRequest.delegate = self
            productsRequest.start()
        }
    }

//----------------------------------------------------------------------------------------------------------------
// #pragma mark SKProductsRequestDelegate methods

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        productsList = response.products 

        if (response.invalidProductIdentifiers.count > 0) {
            var errString = ""
            if (response.invalidProductIdentifiers.count == 1) {
                errString = "Invalid product ID"
            } else {
                errString = "Invalid product IDs"
            }
            for invalidProductId in response.invalidProductIdentifiers {
                errString = "\(errString), \(invalidProductId)"
            }
            print(errString)
        }
    }


    // call this method once on startup
    func  loadStore()
    {
        let defaultQueue = SKPaymentQueue.default()
        defaultQueue.add(self)
        self.requestProductPricingInfo()
    }

    func storeCount() -> Int {
        return productsList.count
    }


    func featureAvailable(productID : String) -> Bool {
         for product in productsList {
            if product.productIdentifier == productID {
                return true
            }
        }
        return false
    }

    // Get current store price for feature
    // Return 0 if it's a feature (such as Free features) without prices.
    func productPrice(productID: String) -> Float {
        if let product = productObject(productID: productID) {
            return product.price.floatValue
        }
        return 0.0
    }

    func productObject(productID : String) -> SKProduct? {
        for product in productsList {
            if productID == product.productIdentifier {
                return product
            }
        }
        return nil
    }

    // kick off the upgrade transaction
    func startPurchase(productIDs : [String]) -> PurchaseError {
        if (!SKPaymentQueue.canMakePayments()) {
            return PurchaseError.NotAuthorized
        }

        for productID in productIDs {
            if let product = productObject(productID: productID) {
                let payment = SKPayment(product: product)
                SKPaymentQueue.default().add(payment)
            }
            else {
                return PurchaseError.ProductIDNotFound
            }
        }
        return PurchaseError.Success
    }

    // See if user already has active subscription.
    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    /*func validateRecipt(){
        var response: NSURLResponse?
        var error: NSError?

        if let receiptUrl = NSBundle.mainBundle().appStoreReceiptURL {
            if let receipt: NSData = NSData(contentsOfURL:receiptUrl, options: nil, error: nil) {
                //https://buy.itunes.apple.com/verifyReceipt
                var request = NSMutableURLRequest(URL: NSURL(string: "https://sandbox.itunes.apple.com/verifyReceipt")!, cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: 10)

                var session = NSURLSession.sharedSession()
                request.HTTPMethod = "POST"
                var receiptdata:NSString = receipt.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.EncodingEndLineWithLineFeed)
                print("\(receiptdata)")
                var payload:NSString = "{\"receipt-data\" : \"\(receiptdata)\"}"
                var payloadData = payload.dataUsingEncoding(NSUTF8StringEncoding)
                var err: NSError?
                request.HTTPBody = payloadData

                var task = session.dataTaskWithRequest(request, completionHandler:
                    {data, response, error -> Void in
                        var err: NSError?
                        var json = NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves, error: &err) as? NSDictionary

                        if(err != nil) {
                            print(err!.localizedDescription)
                            let jsonStr = NSString(data: data, encoding: NSUTF8StringEncoding)
                            print("Error could not parse JSON: '\(jsonStr)'")
                        }
                        else {
                            if let parseJSON = json {
                                print("Recipt \(parseJSON)")
                            }
                            else {
                                let jsonStr = NSString(data: data, encoding: NSUTF8StringEncoding)
                                print("Recipt Error: \(jsonStr)")
                            }
                        }
                })
                
                task.resume()
            }
        }
        
    }*/

    // removes the transaction from the queue and posts a notification with the transaction result
    // We report the results as an internal notification.
    func finishTransaction(transaction : SKPaymentTransaction, wasSuccessful: Bool) {
        SKPaymentQueue.default().finishTransaction(transaction)

        let userInfo = [kInAppTransactionKey : transaction, kInAppProductKey : transaction.payment.productIdentifier] as [String: Any]?
        if (wasSuccessful)
        {
            let productID = transaction.payment.productIdentifier
            Shared.postTransactions(name: kInAppRestoreNotification, productKeys: [productID])
        }
        else
        {
            Shared.postNotification(name: kInAppPurchaseFailNotification,  userInfo: userInfo , object: "Purchase failed" as AnyObject?)
        }
    }

    // called when the transaction was successful
    func successfulTransaction(transaction: SKPaymentTransaction)
    {
        finishTransaction(transaction: transaction, wasSuccessful: true)
    }

    // called when a transaction has been restored and and successfully completed
    func restoreTransaction(transactions: [SKPaymentTransaction]) {
        // remove the transaction from the payment queue.
        var productKeys = [String]()
        for transaction in transactions {
            SKPaymentQueue.default().finishTransaction(transaction)
            productKeys += [transaction.payment.productIdentifier]
        }
        
        //let userInfo = [kInAppTransactionKey : transaction, kInAppProductKey : transaction.payment.productIdentifier]
        Shared.postTransactions(name: kInAppRestoreNotification, productKeys: productKeys)
    }

    // called when a transaction has failed
    func failedTransaction(transaction : SKPaymentTransaction )
    {
        if let error = (transaction.error! as? SKError), error.code != SKError.paymentCancelled  {
            if error.code != SKError.paymentCancelled {
                self.finishTransaction(transaction: transaction, wasSuccessful: false)
            }
        }
        else
        {
            // this is fine, the user just cancelled, so don’t notify
            SKPaymentQueue.default().finishTransaction(transaction)
        }
    }

    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        Shared.postNotification(name: kInAppRestoreFailNotification,  userInfo: nil, object: "Failed to restore" as AnyObject?)
    }
        
    
     // called when the transaction status is updated
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction])    {
        if let firstTransactionObject: AnyObject = transactions.first  {
            if let firstTransaction = firstTransactionObject as? SKPaymentTransaction {
                let transState = firstTransaction.transactionState
                switch (transState)
                {
                    // case .Purchasing:
                case .purchased:
                    for  transaction in transactions {
                        self.successfulTransaction(transaction: transaction )
                    }
                case .failed:
                    for  transaction in transactions {
                        self.failedTransaction(transaction: transaction )
                    }
                    break
                case .restored:
                    self.restoreTransaction(transactions: transactions)
                default:
                    break
                }
            }
        }
    }
}
