//
//  APEncryptRSA.swift
//  APSwiftEncrypt
//
//  Created by Juan Alvarez on 11/3/14.
//  Copyright (c) 2014 Alvarez Productions. All rights reserved.
//

import Foundation
import Security

private let APSecPublicKeyAttrs = kSecPublicKeyAttrs.takeRetainedValue() as String
private let APSecPrivateKeyAttrs = kSecPrivateKeyAttrs.takeRetainedValue() as String

enum APEncryptRSASize: Int {
    case Size512 = 512
    case Size768 = 768
    case Size1024 = 1024
    case Size2048 = 2048
}

class APRSAKeyPair {
    let publicKey: SecKeyRef
    let privateKey: SecKeyRef
    
    let identifier: String?

    init(publicKey: SecKeyRef, privateKey: SecKeyRef, identifier: String?) {
        self.publicKey = publicKey
        self.privateKey = privateKey
        self.identifier = identifier
    }
    
    func encrypt(string: String) -> NSString? {
        let plainTextData = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        let plainTextBuffer = UnsafePointer<UInt8>(plainTextData.bytes)
        let plainTextLength = UInt(plainTextData.length)
        
        let blockSize = SecKeyGetBlockSize(publicKey)
        
        if blockSize < plainTextLength {
            println("String length is too long to sign with this key, max length is \(blockSize) and actual length is \(plainTextLength)")
            return nil
        }
        
        let cipherData = NSMutableData(length: Int(blockSize))!
        let cipherBuffer = UnsafeMutablePointer<UInt8>(cipherData.mutableBytes)
        var cipherBufferLength = size_t(cipherData.length)
        
        let padding: SecPadding = SecPadding(kSecPaddingPKCS1)
        
        let status = SecKeyEncrypt(
            publicKey,
            padding,
            plainTextBuffer,
            plainTextLength,
            cipherBuffer,
            &cipherBufferLength
        )
        
        if status == errSecSuccess {
            let encryptedString = cipherData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(0))
            
            return encryptedString
        } else {
            println(status)
        }
        
        return nil
    }
    
    func decryptString(string: String) -> String? {
        let blockSize = SecKeyGetBlockSize(privateKey)
        
        let cipherData = NSData(base64EncodedString: string, options: NSDataBase64DecodingOptions(0))!
        let cipherBuffer = UnsafePointer<UInt8>(cipherData.bytes)
        let cipherSize = size_t(cipherData.length)
        
        if cipherSize < blockSize {
            println("String length is too long to decrypt with this key, max length is \(blockSize) and actual length is \(cipherSize)")
            
            return nil
        }
        
        let plainTextData = NSMutableData(length: Int(blockSize))!
        let plainTextBuffer = UnsafeMutablePointer<UInt8>(plainTextData.mutableBytes)
        var plainTextBufferLength = size_t(blockSize)
        
        let padding: SecPadding = SecPadding(kSecPaddingPKCS1)
        
        let status = SecKeyDecrypt(
            privateKey,
            padding,
            cipherBuffer,
            cipherSize,
            plainTextBuffer,
            &plainTextBufferLength
        )
        
        if status == errSecSuccess {
            let decryptedString = NSString(bytes: plainTextBuffer, length: Int(plainTextBufferLength), encoding: NSUTF8StringEncoding)
            
            return decryptedString
        }
        
        return nil
    }
}

class APEncryptRSA {
    
    class func generateRSAPair(size: APEncryptRSASize, tagIdentifier: String?) -> APRSAKeyPair? {
        var keyPairAttributes: [String: AnyObject] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits: size.rawValue
        ]
        
        if let tag = tagIdentifier {
            var identifiers = keychainIdentifiers(tag)
            
            // remove the keys if they exist? or should we return an error?
            
            let pubAttr: [String: AnyObject] = [kSecAttrIsPermanent: true, kSecAttrApplicationTag: identifiers.pub]
            let privAttr: [String: AnyObject] = [kSecAttrIsPermanent: true, kSecAttrApplicationTag: identifiers.priv]
            
            keyPairAttributes[APSecPublicKeyAttrs] = pubAttr
            keyPairAttributes[APSecPrivateKeyAttrs] = privAttr
        }
        
        var publicKeyRef: Unmanaged<SecKeyRef>?
        var privateKeyRef: Unmanaged<SecKeyRef>?
        
        let status: OSStatus = SecKeyGeneratePair(keyPairAttributes, &publicKeyRef, &privateKeyRef)
        
        if status == errSecSuccess {
            // if status is successful then the keys should be valid
            var publicKey: SecKeyRef = Unmanaged<SecKeyRef>.fromOpaque(publicKeyRef!.toOpaque()).takeUnretainedValue()
            var privateKey: SecKeyRef = Unmanaged<SecKeyRef>.fromOpaque(privateKeyRef!.toOpaque()).takeUnretainedValue()
            
            if let tag = tagIdentifier {
                // if there is a tag then the keys should have been saved permenently in the keychain
                // so let's retrieve it that way
                return getKeyPair(tag)
            } else {
                return APRSAKeyPair(publicKey: publicKey, privateKey: privateKey, identifier: nil)
            }
        }
        
        return nil
    }
    
    class func getKeyPair(tag: String) -> APRSAKeyPair? {
        let identifiers = keychainIdentifiers(tag)
        
        let publicKey = getKeyRef(identifiers.pub)
        let privateKey = getKeyRef(identifiers.priv)
        
        switch (publicKey, privateKey) {
        case let (Optional.Some(publicKey), Optional.Some(privateKey)):
            return APRSAKeyPair(publicKey: publicKey, privateKey: privateKey, identifier: tag)
        default:
            return nil
        }
    }
    
}

private extension APEncryptRSA {
    
    class func getKeyRef(tag: String) -> SecKeyRef? {
        var query = keyQuery(tag)
        
        let keyRef = APKeychainService.performKeyQuery(query) as SecKeyRef?
        
        return keyRef
    }
    
    class func getKeyData(tag: String) -> NSData? {
        var query = keyQuery(tag)
        
        let keyData = APKeychainService.performKeyDataQuery(query)
        
        return keyData
    }
    
    class func keyQuery(tag: String) -> APKeychainQuery {
        let query = APKeychainQuery(key: APSecClassKey.Key)
        query.keyType = APSecKeyType.RSA
        query.applicationTag = tag
        query.accessible = APSecAccessible.WhenUnlocked
        
        return query
    }
    
    class func keychainIdentifiers(tag: String) -> (pub: String, priv: String) {
        let publicId = tag + ".public"
        let privateId = tag + ".private"
        
        return (publicId, privateId)
    }
}