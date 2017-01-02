////
////  TransportationManager.swift
////  SearchTransportation
////
////  Created by Jonny on 1/1/17.
////  Copyright © 2017 Jonny. All rights reserved.
////
//
//import Foundation
//
//class TransportationManager {
//    
//    static let shared = TransportationManager()
//    
//    private init() {}
//    
//    private enum UserDefaultKey: String {
//        case accounts
//    }
//    
//    var stations = [BusStation]() {
//        didSet {
//            NotificationCenter.default.post(name: .busStationsDidChange, object: nil)
//        }
//    }
//    
//    var routes = [BusRoute]() {
//        didSet {
//            NotificationCenter.default.post(name: .busLinesDidChange, object: nil)
//        }
//    }
//    
//}
//
