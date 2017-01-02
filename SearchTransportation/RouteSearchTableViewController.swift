//
//  RouteSearchTableViewController.swift
//  SearchTransportation
//
//  Created by Jonny on 1/1/17.
//  Copyright © 2017 Jonny. All rights reserved.
//

import UIKit

class RouteSearchTableViewController: TableViewController {
    
    // MARK: - Properties
    
    override var hintForEmptyTable: String {
        return hintForNoSearchResult
    }
    
    /// Set a non-nil value before present the controller.
    var startStation: BusStation?
    
    /// Set a non-nil value before present the controller.
    var endStation: BusStation?
    
    private typealias TravelRoute = [(line: BusRoute, stations: [BusStation], isReverseDirection: Bool)]
    
    private var travelRoutes = [TravelRoute]()
    
    private enum SortMode: String {
        case fewerTranfers, shorterDistance
    }
    
    private var currentSortMode = SortMode.fewerTranfers
    
    private var indexPathsOfRowsShowsCompletedStations = Set<IndexPath>()
    
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableViewAutomaticDimension
        
        if let startStation = startStation, let endStation = endStation {
            title = startStation.name + " → " + endStation.name
            
            let travelRoutes = BusRoute.travelRoutes(from: startStation, to: endStation)
            self.travelRoutes = sorted(travelRoutes)
        }
        
        super.viewDidLoad()
    }
    
    
    // MARK: - Convenient Methods
    
    private func sorted(_ travelRoutes: [TravelRoute]) -> [TravelRoute] {
        
        switch currentSortMode {
        case .fewerTranfers:
            return travelRoutes.sorted {
                if $0.count == $1.count {
                    let leftPassStationCount = $0.reduce(0, { $0 + $1.stations.count - 1 })
                    let rightPassStationCount = $1.reduce(0, { $0 + $1.stations.count - 1 })
                    return leftPassStationCount < rightPassStationCount
                }
                return $0.count < $1.count
            }
        case .shorterDistance:
            return travelRoutes.sorted {
                let leftPassStationCount = $0.reduce(0, { $0 + $1.stations.count - 1 })
                let rightPassStationCount = $1.reduce(0, { $0 + $1.stations.count - 1 })
                
                if leftPassStationCount == rightPassStationCount {
                    return $0.count < $1.count // sort by minimum tranfer
                }
                return leftPassStationCount < rightPassStationCount
            }
        }
    }
    
    /// 仅途径站点
    private func passedStationsStringForRow(at indexPath: IndexPath) -> String {
        let route = travelRoutes[indexPath.section][indexPath.row]
        return route.stations.map { $0.name } .joined(separator: "\n|\n")
    }
    
    /// 完整站点
    private func completedStationsStringForRow(at indexPath: IndexPath) -> NSAttributedString? {
        
        let route = travelRoutes[indexPath.section][indexPath.row]
        let allStations = route.isReverseDirection ? route.line.stations.reversed() : route.line.stations
        
        guard let startStation = route.stations.first, let endStation = route.stations.last else { return nil }
        guard let startStationIndex = allStations.index(of: startStation), let endStationIndex = allStations.index(of: endStation) else { return nil }
        
        let mutableAttributedString = NSMutableAttributedString()
        
        let attributesForNormalStationName = [NSFontAttributeName : UIFont.preferredFont(forTextStyle: .callout), NSForegroundColorAttributeName : UIColor.darkGray]
        let attributesForPassedStationName = [NSFontAttributeName : UIFont.preferredFont(forTextStyle: .callout), NSForegroundColorAttributeName : UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)]
        
        for (index, station) in allStations.enumerated() {
            
            if index >= startStationIndex && index <= endStationIndex {
                mutableAttributedString.append(NSAttributedString(string: station.name, attributes: attributesForPassedStationName))
            } else {
                mutableAttributedString.append(NSAttributedString(string: station.name, attributes: attributesForNormalStationName))
            }
            if index < allStations.count - 1 {
                if index >= startStationIndex && index + 1 <= endStationIndex {
                    mutableAttributedString.append(NSAttributedString(string: "\n|\n", attributes: attributesForPassedStationName))
                } else {
                    mutableAttributedString.append(NSAttributedString(string: "\n|\n", attributes: attributesForNormalStationName))
                }
            }
        }
        
        return mutableAttributedString
    }
    
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let cell = tableView.cellForRow(at: indexPath) as? SubtitleTableViewCell else { return }
        
        tableView.beginUpdates()
        
        if indexPathsOfRowsShowsCompletedStations.contains(indexPath) {
            indexPathsOfRowsShowsCompletedStations.remove(indexPath)
            cell.subtitleLabel.text = passedStationsStringForRow(at: indexPath)
        } else {
            indexPathsOfRowsShowsCompletedStations.insert(indexPath)
            cell.subtitleLabel.attributedText = completedStationsStringForRow(at: indexPath)
        }
        
        tableView.endUpdates()
        
        tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.none, animated: true)
    }
    
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        hintLabel.isHidden = travelRoutes.count > 0
        return travelRoutes.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return travelRoutes[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "\(SubtitleTableViewCell.self)", for: indexPath) as! SubtitleTableViewCell
        let route = travelRoutes[indexPath.section][indexPath.row]
        
        let terminalStationName = route.isReverseDirection ? route.line.stations.first?.name : route.line.stations.last?.name
        
        cell.titleLabel.text = route.line.name + " (terminal: " + (terminalStationName ?? "Unknown") + ")"
        
        if indexPathsOfRowsShowsCompletedStations.contains(indexPath) {
            cell.subtitleLabel.attributedText = completedStationsStringForRow(at: indexPath)
        } else {
            cell.subtitleLabel.text = passedStationsStringForRow(at: indexPath)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard travelRoutes.count > 1 else { return nil }
        
        if section == 0 {
            return "Plan 1 - " + (currentSortMode == .fewerTranfers ? "Fewest Tranfers" : "Shortest Distance")
        }
        return "Plan \(section + 1)"
    }
    

    // MARK: - Actions
    
    @IBAction private func sortButtonItemDidTap(_ sender: UIBarButtonItem) {
        
        let controller = UIAlertController(title: "Prefer...", message: nil, preferredStyle: .actionSheet)
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        controller.addAction(UIAlertAction(title: "Shorter Distance", style: .default) { _ in
            self.currentSortMode = .shorterDistance
            self.travelRoutes = self.sorted(self.travelRoutes)
            self.tableView.reloadData()
        })
        
        controller.addAction(UIAlertAction(title: "Fewer Transfers", style: .default) { _ in
            self.currentSortMode = .fewerTranfers
            self.travelRoutes = self.sorted(self.travelRoutes)
            self.tableView.reloadData()
        })
        
        if let popover = controller.popoverPresentationController {
             popover.barButtonItem = sender
        }
        
        present(controller, animated: true)
    }
    
}
