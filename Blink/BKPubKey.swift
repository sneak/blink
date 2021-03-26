//////////////////////////////////////////////////////////////////////////////////
//
// B L I N K
//
// Copyright (C) 2016-2019 Blink Mobile Shell Project
//
// This file is part of Blink.
//
// Blink is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Blink is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Blink. If not, see <http://www.gnu.org/licenses/>.
//
// In addition, Blink is also subject to certain additional terms under
// GNU GPL version 3 section 7.
//
// You should have received a copy of these additional terms immediately
// following the terms and conditions of the GNU General Public License
// which accompanied the Blink Source Code. If not, see
// <http://www.github.com/blinksh/blink>.
//
////////////////////////////////////////////////////////////////////////////////


import Foundation
import SSH

extension BKPubKey {
  
  @objc public static func saveDefaultKey() -> Bool {
    guard
      let key = try? SSHKey(type: .rsa, bits: 4096),
      let privKey = try? key.privateKeyFileBlob(comment: nil, passphrase: nil),
      let privKeyStr = String(data: privKey, encoding: .utf8),
      let pubKey = try? key.authorizedKey(withComment: "blink"),
      let _ = saveInKeychain(withID: "id_rsa", privateKey: privKeyStr, publicKey: pubKey)
    else {
      return false
    }
    
    return  true
  }
  
  static func addKeychainKey(id: String, key: SSHKey, comment: String) throws {
    let tag = ProcessInfo().globallyUniqueString
    let publicKey = try key.authorizedKey(withComment: comment)
    guard let card = BKPubKey(id: id, tag: tag, publicKey: publicKey, keyType: key.sshKeyType.shortName, certType: nil, storageType: BKPubKeyStorageTypeKeyChain),
        let privateKey = String(data: try key.privateKeyFileBlob(), encoding: .utf8)
    else {
      return
    }
    
    card.storePrivateKey(inKeychain: privateKey)
    
    BKPubKey.addCard(card);
  }
  
  static func addSEKey(id: String, comment: String) throws {
    let tag = ProcessInfo().globallyUniqueString
    let key = try SEKey.create(tagged: tag)
    
    let keyType = key.sshKeyType
    let publicKey = try key.publicKey.authorizedKey(withComment: comment)
    guard let card = BKPubKey(id: id, tag: tag, publicKey: publicKey, keyType: keyType.shortName, certType: nil, storageType: BKPubKeyStorageTypeSecureEnclave)
    else {
      return
    }
    
    BKPubKey.addCard(card);
  }
  
  static func seKeyWithID(_ id: String) -> SEKey? {
    guard let card = BKPubKey.withID(id) else {
      return nil
    }
  
    return SEKey(tagged: card.tag)
  }
  
  static func removeCard(card: BKPubKey) {
    if card.storageType == BKPubKeyStorageTypeSecureEnclave {
      try? SEKey.delete(tag: card.tag)
    }
    
    card.removeCard()
  }
  
}
