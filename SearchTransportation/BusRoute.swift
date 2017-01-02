//
//  BusRoute.swift
//  SearchTransportation
//
//  Created by Jonny on 1/1/17.
//  Copyright © 2017 Jonny. All rights reserved.
//

import Foundation

struct BusRoute: Equatable {
    
    private enum UserDefaultKey: String {
        case activeRoutes
    }
    
    static var activeRoutes = (UserDefaults.standard.value(forKey: UserDefaultKey.activeRoutes.rawValue) as? [[String : Any]])?.flatMap { BusRoute(propertyList: $0) } ?? [] {
        didSet {
            NotificationCenter.default.post(name: .busRoutesDidChange, object: nil)
            UserDefaults.standard.set(activeRoutes.map { $0.propertyList }, forKey: UserDefaultKey.activeRoutes.rawValue)
        }
    }
    
    var name: String
    let uuid: UUID
    
    var stations: [BusStation] {
        didSet {
            stationSet = Set(stations)
        }
    }
    
    fileprivate(set) var stationSet = Set<BusStation>()
    
    init(name: String, stations: [BusStation] = [], uuid: UUID = UUID()) {
        self.name = name
        self.stations = stations
        self.stationSet = Set(stations)
        self.uuid = uuid
    }
    
    static func ==(lhs: BusRoute, rhs: BusRoute) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}

extension Notification.Name {
    static let busRoutesDidChange = Notification.Name(rawValue: "busRoutesDidChange")
}

extension BusRoute {
    
    init?(propertyList: [String : Any]) {
        
        guard let name = propertyList["name"] as? String,
            let stationIdentifiers = propertyList["stationIdentifiers"] as? [String],
            let identifier = propertyList["identifier"] as? String,
            let uuid = UUID(uuidString: identifier) else { return nil }
        
        self.name = name
        self.uuid = uuid
        
        let stationIdentifiersSet = Set(stationIdentifiers)
        if stationIdentifiersSet.isEmpty {
            self.stations = []
        } else {
            self.stations = BusStation.activeStations.filter { stationIdentifiersSet.contains($0.uuid.uuidString) }
            self.stationSet = Set(self.stations)
        }
    }
    
    var propertyList: [String : Any] {
        return [
            "name" : name,
            "stationIdentifiers" : stations.map { $0.uuid.uuidString },
            "identifier" : uuid.uuidString,
        ]
    }
}


extension BusRoute {
    
    /// 本线路可换乘的其它线路。
    private var acrossedLines: [BusRoute] {
        return BusRoute.activeRoutes.filter { $0 != self && stationSet.intersection($0.stationSet).count > 0 }
    }
    
    /// 搜索从本线路到达指定线路的所有可行路线。
    ///
    /// - Parameters:
    ///   - line: 终点线路。
    ///   - basedLines: 途径线路。
    ///   - newRouteHandler: 新路线回调。
    private func findingRoutes(to line: BusRoute, basedLines: [BusRoute], newRouteHandler: ([BusRoute]) -> Void) {
        
        if line == self {
            newRouteHandler(basedLines)
            return
        }
        
        let acrossedLines = self.acrossedLines.filter({ !basedLines.contains($0) })
        
        // enumerate tree.
        for acrossedLine in acrossedLines {
            acrossedLine.findingRoutes(to: line, basedLines: basedLines + [acrossedLine], newRouteHandler: newRouteHandler)
        }
    }
    
    /// 搜索从本线路的指定站点到指定线路的途径站点。
    ///
    /// - Parameters:
    ///   - fromStation: 起点站。
    ///   - toLine: 终点线路。
    ///   - excludedDestinationStations: 不作考虑的终点站。
    /// - Returns: 第一个值: 途径站点；第二个值: 是否可到达。
    private func stations(fromStation: BusStation, toLine: BusRoute, excludedDestinationStations: [BusStation]) -> ([BusStation], Bool)? {
        
        print("from", self.name, "to", toLine.name)
        
        //        stationSet.intersection(Set(toLine.stations.filter { $0 != fromStation && !excludedDestinationStations.contains($0) }))
        
        let intersectionStations = Set(toLine.stations.filter { $0 != fromStation && !excludedDestinationStations.contains($0) }).intersection(self.stationSet)
        
        guard intersectionStations.count > 0 else {
            // cannot direct travel to indicated bus line.
            print("cannot direct travel to indicated bus line.", self.name, toLine.name, fromStation.name, excludedDestinationStations.map { $0.name })
            return nil
        }
        
        guard let fromIndex = stations.index(of: fromStation) else {
            // the from station is not on current line.
            print("the from station is not on current line.")
            return nil
        }
        
        let toIndice = intersectionStations.flatMap { stations.index(of: $0) }
        
        // 最小途径站点数
        var minimumPassStationCount: Int?
        var destinationIndexOffset: Int?
        
        for toIndex in toIndice {
            let offset = toIndex - fromIndex
            let absOffset = abs(offset)
            
            if let previousMinimumPassStationCount = minimumPassStationCount {
                if absOffset < previousMinimumPassStationCount {
                    minimumPassStationCount = absOffset
                    destinationIndexOffset = offset
                }
            } else {
                minimumPassStationCount = absOffset
                destinationIndexOffset = offset
            }
        }
        
        if let destinationIndexOffset = destinationIndexOffset {
            let toIndex = fromIndex + destinationIndexOffset
            
            let stations: ([BusStation], Bool)
            
            if toIndex > fromIndex {
                stations = (Array(self.stations[fromIndex ... toIndex]), false)
            } else {
                stations = (Array(self.stations[toIndex ... fromIndex].reversed()), true)
            }
            
            return stations
        }
        
        return nil
    }
    
    /// 计算在同一条线路上，从站点 A 到站点 B 的途径站点（包含起始和终点站）。
    ///
    /// - Parameters:
    ///   - from: 起点站。
    ///   - to: 终点站。
    /// - Returns: passed: 途径站点（包含起始和终点站）；isReverseDirection: 是否沿线路反方向搭乘。
    private func onLineStations(from: BusStation, to: BusStation) -> (passed: [BusStation], isReverseDirection: Bool)? {
        
        guard from != to else {
            print(#function, "from == to.")
            return nil
        }
        
        guard let fromIndex = stations.index(of: from), let toIndex = stations.index(of: to) else {
            print(#function, "from or to index not found.")
            return nil
        }
        
        if toIndex > fromIndex {
            return (Array(stations[fromIndex ... toIndex]), false)
        } else {
            return (stations[toIndex ... fromIndex].reversed(), true)
        }
    }
    
    /// 规划从站点 A 到站点 B 的所有路线。
    ///
    /// - Parameters:
    ///   - from: 起点站。
    ///   - to: 终点站。
    /// - Returns: 从站点 A 到站点 B 的所有路线。line: 巴士线路；stations: 搭乘线路的途径站点；isReverseDirection: 是否沿线路反方向搭乘。
    static func travelRoutes(from: BusStation, to: BusStation) -> [[(line: BusRoute, stations: [BusStation], isReverseDirection: Bool)]] {
        
        let fromLines = BusRoute.activeRoutes.filter { $0.stationSet.contains(from) }
        let toLines = BusRoute.activeRoutes.filter { $0.stationSet.contains(to) }
        
        var travelRoutesArray = [[(line: BusRoute, stations: [BusStation], isReverseDirection: Bool)]]()
        
        for fromLine in fromLines {
            for toLine in toLines {
                
                if fromLine == toLine {
                    if let stations = fromLine.onLineStations(from: from, to: to) {
                        travelRoutesArray.append([(line: fromLine, stations: stations.passed, isReverseDirection: stations.isReverseDirection)])
                        continue
                    }
                }
                
                var routes = [[BusRoute]]()
                
                fromLine.findingRoutes(to: toLine, basedLines: [fromLine], newRouteHandler: { route in
                    routes.append(route)
                })
                
                for route in routes {
                    
                    var isValidRoute = true
                    var stationsArray = [([BusStation], Bool)]()
                    var excludedDestinationStations = [from]
                    var fromStation = from
                    var startLine = fromLine
                    
                    for (index, toLine) in route.enumerated() {
                        if toLine == fromLine {
                            continue
                        }
                        
                        if let stations = startLine.stations(fromStation: fromStation, toLine: toLine, excludedDestinationStations: excludedDestinationStations), stations.0.count > 0 {
                            excludedDestinationStations.append(stations.0.first!)
                            excludedDestinationStations.append(stations.0.last!)
                            fromStation = stations.0.last!
                            startLine = toLine
                            
                            stationsArray.append((stations.0, stations.1))
                            
                            if index == route.count - 1 { // last line
                                if let lastLinePassStations = toLine.onLineStations(from: fromStation, to: to), lastLinePassStations.0.count > 0 {
                                    stationsArray.append((lastLinePassStations.passed, lastLinePassStations.isReverseDirection))
                                } else {
                                    isValidRoute = false
                                }
                            }
                            
                        } else {
                            isValidRoute = false
                            break
                        }
                    }
                    
                    if isValidRoute && route.count == stationsArray.count {
                        var travelRoutes = [(line: BusRoute, stations: [BusStation], isReverseDirection: Bool)]()
                        for i in 0 ..< route.count {
                            travelRoutes.append((route[i], stationsArray[i].0, stationsArray[i].1))
                        }
                        travelRoutesArray.append(travelRoutes)
                    }
                }
            }
        }
        
        travelRoutesArray = travelRoutesArray.filter { (route: [(line: BusRoute, stations: [BusStation], isReverseDirection: Bool)]) -> Bool in
            
            // 检查路线中是否有重复经过的站点。如有，滤除此路线
            var stationUUIDDictionary = [UUID : Int]()
            var stationsNeedsRecheck = [BusStation]()
            
            for station in (route.map { $0.stations } .reduce([], +)) {
                if let count = stationUUIDDictionary[station.uuid] {
                    if count >= 2 {
                        return false
                    } else if count >= 1 {
                        stationsNeedsRecheck.append(station)
                    }
                    stationUUIDDictionary[station.uuid] = count + 1
                } else {
                    stationUUIDDictionary[station.uuid] = 1
                }
            }
            
            guard !stationsNeedsRecheck.isEmpty else { return true }
            
            var validStationCount = 0
            
            for station in stationsNeedsRecheck {
                for index in 0 ..< route.count {
                    if route[index].stations.last == station && index + 1 < route.count {
                        if route[index + 1].stations.first == station {
                            validStationCount += 1
                        } else {
                            return false
                        }
                    }
                }
            }
            
            return validStationCount == stationsNeedsRecheck.count
        }
        
        return travelRoutesArray
    }
    
}

