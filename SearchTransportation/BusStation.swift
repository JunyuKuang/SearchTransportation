//
//  BusLine.swift
//  BusLineTest
//
//  Created by Jonny on 12/30/16.
//  Copyright © 2016 Jonny. All rights reserved.
//

import Foundation

struct BusStation: Equatable, Hashable {
    
    private enum UserDefaultKey: String {
        case activeStations
    }
    
    static var activeStations = (UserDefaults.standard.value(forKey: UserDefaultKey.activeStations.rawValue) as? [[String : Any]])?.flatMap { BusStation(propertyList: $0) } ?? [] {
        didSet {
            NotificationCenter.default.post(name: .busStationsDidChange, object: nil)
            UserDefaults.standard.set(activeStations.map { $0.propertyList }, forKey: UserDefaultKey.activeStations.rawValue)
        }
    }
    
    var name: String
    let uuid: UUID
    
    var hashValue: Int {
        return uuid.hashValue
    }
    
    init(name: String, uuid: UUID = UUID()) {
        self.name = name
        self.uuid = uuid
    }
    
    static func ==(lhs: BusStation, rhs: BusStation) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}

extension BusStation {
    
    init?(propertyList: [String : Any]) {
        
        guard let name = propertyList["name"] as? String,
            let identifier = propertyList["identifier"] as? String,
            let uuid = UUID(uuidString: identifier) else { return nil }
        
        self.name = name
        self.uuid = uuid
    }
    
    var propertyList: [String : Any] {
        return [
            "name" : name,
            "identifier" : uuid.uuidString,
        ]
    }
}

extension Notification.Name {
    static let busStationsDidChange = Notification.Name(rawValue: "busStationsDidChange")
}

